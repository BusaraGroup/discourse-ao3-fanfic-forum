# frozen_string_literal: true

module Ao3FanficForum
  class TopicsController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    MAX_PER_PAGE = 100

    def index
      page = [params[:page].to_i, 1].max
      per_page = params[:per_page].presence&.to_i || SiteSetting.ao3_fanfic_filter_page_size
      per_page = per_page.clamp(1, MAX_PER_PAGE)

      topics =
        Topic
          .listable_topics
          .visible
          .secured(guardian)
          .where.not(id: Category.where.not(topic_id: nil).select(:topic_id))
          .joins(
            "LEFT OUTER JOIN ao3_fanfic_topic_metadata ao3_meta ON ao3_meta.topic_id = topics.id",
          )

      topics = apply_metadata_filters(topics)
      topics = apply_term_filters(topics)
      topics = topics.order("topics.bumped_at DESC").offset((page - 1) * per_page).limit(per_page)
      topics = topics.includes(:category, :tags)
      topics = topics.to_a

      Topic.preload_custom_fields(topics, Fields.field_names)

      render json: {
               topics:
                 ActiveModel::ArraySerializer.new(
                   topics,
                   each_serializer: TopicListItemSerializer,
                   scope: guardian,
                   root: false,
                 ).as_json,
               meta: {
                 page: page,
                 per_page: per_page,
                 has_more: topics.length == per_page,
               },
             }
    end

    private

    def apply_metadata_filters(scope)
      discussion_type = Metadata.normalize_discussion_type(params[:discussion_type])
      if params[:discussion_type].present? && Fields::DISCUSSION_TYPES.include?(discussion_type)
        scope = scope.where("ao3_meta.discussion_type = ?", discussion_type)
      end

      if ActiveModel::Type::Boolean.new.cast(params[:spoiler_safe])
        scope =
          scope.where(
            "ao3_meta.spoiler_until IS NULL OR ao3_meta.spoiler_until <= ?",
            Time.zone.now,
          )
      end

      scope
    end

    def apply_term_filters(scope)
      {
        fandom: params[:fandom],
        ship: params[:ship],
        warning: params[:warning],
      }.each do |term_type, raw_values|
        Normalizer.list(raw_values).each_with_index do |value, index|
          scope = include_term(scope, term_type.to_s, Normalizer.key(value), index)
        end
      end

      Normalizer.list(params[:exclude_warning]).each do |value|
        scope =
          scope.where(
            "NOT EXISTS (
              SELECT 1 FROM ao3_fanfic_topic_terms excluded_terms
              WHERE excluded_terms.topic_id = topics.id
                AND excluded_terms.term_type = 'warning'
                AND excluded_terms.normalized = ?
            )",
            Normalizer.key(value),
          )
      end

      scope
    end

    def include_term(scope, term_type, normalized, index)
      table_alias = "ao3_#{term_type}_terms_#{index}"
      quoted_alias = ActiveRecord::Base.connection.quote_table_name(table_alias)

      scope.joins(
        ActiveRecord::Base.sanitize_sql_array(
          [
            "INNER JOIN ao3_fanfic_topic_terms #{quoted_alias}
              ON #{quoted_alias}.topic_id = topics.id
             AND #{quoted_alias}.term_type = ?
             AND #{quoted_alias}.normalized = ?",
            term_type,
            normalized,
          ],
        ),
      )
    end
  end
end
