# frozen_string_literal: true

module Ao3FanficForum
  module Metadata
    PUBLIC_METADATA_KEYS =
      %i[
        discussion_type
        fandom_tags
        ship_tags
        content_warnings
        spoiler_label
        spoiler_until
        fic_url
        fic_title
        fic_author
        chapter_ref
      ].freeze

    PRESENCE_FIELD_NAMES =
      [
        Fields::DISCUSSION_TYPE,
        Fields::FANDOM_TAGS,
        Fields::SHIP_TAGS,
        Fields::CONTENT_WARNINGS,
        Fields::SPOILER_LABEL,
        Fields::SPOILER_UNTIL,
        Fields::FIC_URL,
        Fields::FIC_TITLE,
        Fields::FIC_AUTHOR,
        Fields::CHAPTER_REF,
      ].freeze

    DEFAULT_FIELD_VALUES = { Fields::DISCUSSION_TYPE => "general" }.freeze

    module_function

    def for_topic(topic)
      return nil if topic.blank?

      fields = read_custom_fields(topic)
      return nil unless raw_present?(fields)

      data = coerce(fields)
      public_data = data.slice(*PUBLIC_METADATA_KEYS)

      public_data.merge(
        present: true,
        spoiler_active: spoiler_active?(data[:spoiler_until]),
        fandom_keys: data[:fandom_tags].map { |tag| Normalizer.key(tag) },
        ship_keys: data[:ship_tags].map { |tag| Normalizer.key(tag) },
        content_warning_keys: data[:content_warnings].map { |tag| Normalizer.key(tag) },
      )
    end

    def apply!(topic, fields)
      fields = sanitize_fields(fields)
      delete_legacy_fields(topic)

      if !raw_present?(fields)
        Fields.field_names.each { |field| topic.custom_fields.delete(field) }
        topic.save!
        sync_from_topic!(topic)
        return topic
      end

      data = coerce(fields)
      validate_data!(data, topic)

      fields.each { |field, value| topic.custom_fields[field] = value.presence }
      topic.save!
      sync_from_topic!(topic)
      topic
    end

    def sync_from_topic!(topic)
      legacy_fields_deleted = delete_legacy_fields(topic)
      fields = read_custom_fields(topic)

      if !raw_present?(fields)
        topic.save! if legacy_fields_deleted
        TopicMetadata.where(topic_id: topic.id).destroy_all
        TopicTerm.where(topic_id: topic.id).delete_all
        return
      end

      data = coerce(fields)
      validate_data!(data, topic)

      record = TopicMetadata.find_or_initialize_by(topic_id: topic.id)
      record.assign_attributes(
        discussion_type: data[:discussion_type],
        spoiler_label: data[:spoiler_label].presence,
        spoiler_until: data[:spoiler_until],
        fic_url: data[:fic_url].presence,
        fic_title: data[:fic_title].presence,
        fic_author: data[:fic_author].presence,
        chapter_ref: data[:chapter_ref].presence,
        visibility: "public",
        space_group_id: nil,
        post_anonymously: false,
      )
      record.save!

      TopicTerm.where(topic_id: topic.id).delete_all
      term_rows(data).each { |attrs| TopicTerm.create!(attrs.merge(topic_id: topic.id)) }
      topic.save! if legacy_fields_deleted
    end

    def validate_topic!(topic)
      fields = read_custom_fields(topic)
      return if !raw_present?(fields)

      data = coerce(fields)
      validate_data!(data, topic)
    rescue Discourse::InvalidParameters => e
      topic.errors.add(:base, e.message)
    end

    def sanitize_fields(fields)
      fields = fields.to_unsafe_h if fields.respond_to?(:to_unsafe_h)
      fields = fields.to_h if fields.respond_to?(:to_h)
      fields ||= {}
      fields.slice(*Fields.field_names)
    end

    def coerce(fields)
      fields = sanitize_fields(fields)

      {
        discussion_type: normalize_discussion_type(fields[Fields::DISCUSSION_TYPE]),
        fandom_tags: Normalizer.list(fields[Fields::FANDOM_TAGS]),
        ship_tags: Normalizer.list(fields[Fields::SHIP_TAGS]),
        content_warnings: Normalizer.list(fields[Fields::CONTENT_WARNINGS]),
        spoiler_label: Normalizer.text(fields[Fields::SPOILER_LABEL], max_length: 120),
        spoiler_until: Normalizer.date_time(fields[Fields::SPOILER_UNTIL]),
        fic_url: Normalizer.url(fields[Fields::FIC_URL], max_length: 2048),
        fic_title: Normalizer.text(fields[Fields::FIC_TITLE], max_length: 240),
        fic_author: Normalizer.text(fields[Fields::FIC_AUTHOR], max_length: 160),
        chapter_ref: Normalizer.text(fields[Fields::CHAPTER_REF], max_length: 80),
      }
    end

    def fields_for_data(data)
      {
        Fields::DISCUSSION_TYPE => data[:discussion_type],
        Fields::FANDOM_TAGS => data[:fandom_tags].to_json,
        Fields::SHIP_TAGS => data[:ship_tags].to_json,
        Fields::CONTENT_WARNINGS => data[:content_warnings].to_json,
        Fields::SPOILER_LABEL => data[:spoiler_label],
        Fields::SPOILER_UNTIL => data[:spoiler_until]&.iso8601,
        Fields::FIC_URL => data[:fic_url],
        Fields::FIC_TITLE => data[:fic_title],
        Fields::FIC_AUTHOR => data[:fic_author],
        Fields::CHAPTER_REF => data[:chapter_ref],
      }
    end

    def read_custom_fields(topic)
      Fields.field_names.index_with do |field|
        topic.custom_fields[field]
      rescue HasCustomFields::NotPreloadedError
        nil
      end
    end

    def delete_legacy_fields(topic)
      deleted = false

      Fields.legacy_field_names.each do |field|
        next if !topic.custom_fields.key?(field)

        topic.custom_fields.delete(field)
        deleted = true
      end

      deleted
    end

    def raw_present?(fields)
      fields = sanitize_fields(fields)

      PRESENCE_FIELD_NAMES.any? { |field| meaningful_field_value?(field, fields[field]) }
    end

    def meaningful_field_value?(field, value)
      return false if value.blank?

      normalized_value = value.is_a?(Array) ? value.to_json : value.to_s
      return false if normalized_value == "[]"
      return false if DEFAULT_FIELD_VALUES[field] == normalized_value

      true
    end

    def validate_data!(data, _topic = nil)
      if SiteSetting.ao3_fanfic_require_fandom_tags && data[:fandom_tags].blank?
        raise Discourse::InvalidParameters.new(I18n.t("ao3_fanfic.errors.fandom_required"))
      end

      if !Fields::DISCUSSION_TYPES.include?(data[:discussion_type])
        raise Discourse::InvalidParameters.new(I18n.t("ao3_fanfic.errors.invalid_discussion_type"))
      end

      validate_allowed_warnings!(data[:content_warnings])
    end

    def normalize_discussion_type(value)
      value = Normalizer.text(value)
      value.presence || "general"
    end

    def spoiler_active?(value)
      value.present? && value.future?
    end

    def term_rows(data)
      [
        ["fandom", data[:fandom_tags]],
        ["ship", data[:ship_tags]],
        ["warning", data[:content_warnings]],
      ].flat_map do |type, values|
        values.map { |value| { term_type: type, value: value, normalized: Normalizer.key(value) } }
      end
    end

    def validate_allowed_warnings!(warnings)
      return if SiteSetting.ao3_fanfic_allow_custom_content_warnings

      allowed = Normalizer.list(SiteSetting.ao3_fanfic_allowed_content_warnings).map do |warning|
        Normalizer.key(warning)
      end
      invalid = warnings.reject { |warning| allowed.include?(Normalizer.key(warning)) }
      return if invalid.blank?

      raise Discourse::InvalidParameters.new(
              I18n.t("ao3_fanfic.errors.invalid_content_warnings", warnings: invalid.join(", ")),
            )
    end
  end
end
