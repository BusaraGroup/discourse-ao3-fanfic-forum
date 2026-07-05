# frozen_string_literal: true

# name: discourse-ao3-fanfic-forum
# about: AO3 reader discussion workflows: fandom/ship metadata, spoiler labels, content warnings, fic recs, fic-finding, chapter threads, and fandom spaces.
# version: 0.1.0
# authors: Gold Mango Labs
# url: https://github.com/discourse/discourse

enabled_site_setting :ao3_fanfic_enabled

register_asset "stylesheets/common/ao3-fanfic-forum.scss"

module ::Ao3FanficForum
  PLUGIN_NAME = "discourse-ao3-fanfic-forum"
end

require_relative "lib/ao3_fanfic_forum/engine"

after_initialize do
  require_relative "lib/ao3_fanfic_forum/fields"
  require_relative "lib/ao3_fanfic_forum/normalizer"
  require_relative "app/models/ao3_fanfic_forum/topic_metadata"
  require_relative "app/models/ao3_fanfic_forum/topic_term"
  require_relative "lib/ao3_fanfic_forum/metadata"

  Ao3FanficForum::Fields::CUSTOM_FIELD_TYPES.each do |field, options|
    register_topic_custom_field_type(field, :string, max_length: options[:max_length])
    register_editable_topic_custom_field(field)
    add_preloaded_topic_list_custom_field(field)
    Search.preloaded_topic_custom_fields << field
  end

  validate(:topic, :validate_ao3_fanfic_metadata) do
    Ao3FanficForum::Metadata.validate_topic!(self)
  end

  on(:topic_created) do |topic, _opts, _user|
    Ao3FanficForum::Metadata.sync_from_topic!(topic)
  end

  on(:post_edited) do |post, _topic_changed, _revisor|
    Ao3FanficForum::Metadata.sync_from_topic!(post.topic) if post&.is_first_post?
  end

  add_to_serializer(:topic_view, :ao3_fanfic) do
    Ao3FanficForum::Metadata.for_topic(object.topic)
  end

  add_to_serializer(:topic_list_item, :ao3_fanfic) do
    Ao3FanficForum::Metadata.for_topic(object)
  end

  add_to_serializer(:basic_topic, :ao3_fanfic) do
    Ao3FanficForum::Metadata.for_topic(object)
  end

  add_to_serializer(:search_topic_list_item, :ao3_fanfic) do
    Ao3FanficForum::Metadata.for_topic(object)
  end
end
