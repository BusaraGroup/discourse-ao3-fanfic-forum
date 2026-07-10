# frozen_string_literal: true

# name: discourse-ao3-fanfic-forum
# about: AO3 reader discussion workflows: fandom/ship metadata, spoiler labels, content warnings, fic recs, fic-finding, chapter threads, and fandom spaces.
# version: 0.1.0
# authors: Gold Mango Labs
# url: https://github.com/BusaraGroup/discourse-ao3-fanfic-forum

enabled_site_setting :ao3_fanfic_enabled

register_asset "stylesheets/common/ao3-fanfic-forum.scss"

%w[
  arrow-right
  eye-slash
  heart
  lock
  magnifying-glass
  plus
  triangle-exclamation
  users
  xmark
].each { |icon| register_svg_icon icon }

module ::Ao3FanficForum
  PLUGIN_NAME = "discourse-ao3-fanfic-forum"
end

require_relative "lib/ao3_fanfic_forum/engine"

after_initialize do
  require_relative "lib/ao3_fanfic_forum/auth_configuration"
  require_relative "lib/ao3_fanfic_forum/fields"
  require_relative "lib/ao3_fanfic_forum/normalizer"
  require_relative "lib/ao3_fanfic_forum/supporter_access"
  require_relative "app/controllers/ao3_fanfic_forum/base_controller"
  require_relative "app/controllers/ao3_fanfic_forum/account_controller"
  require_relative "app/controllers/ao3_fanfic_forum/crypto_payments_controller"
  require_relative "app/controllers/ao3_fanfic_forum/login_controller"
  require_relative "app/controllers/ao3_fanfic_forum/logout_controller"
  require_relative "app/controllers/ao3_fanfic_forum/metadata_controller"
  require_relative "app/controllers/ao3_fanfic_forum/password_reset_controller"
  require_relative "app/controllers/ao3_fanfic_forum/room_requests_controller"
  require_relative "app/controllers/ao3_fanfic_forum/signup_controller"
  require_relative "app/controllers/ao3_fanfic_forum/supporter_controller"
  require_relative "app/controllers/ao3_fanfic_forum/supporter_status_controller"
  require_relative "app/controllers/ao3_fanfic_forum/terms_controller"
  require_relative "app/controllers/ao3_fanfic_forum/topics_controller"
  require_relative "app/models/ao3_fanfic_forum/topic_metadata"
  require_relative "app/models/ao3_fanfic_forum/topic_term"
  require_relative "lib/ao3_fanfic_forum/metadata"

  Discourse::Application.routes.prepend do
    get "/ao3-fanfic/account" => "ao3_fanfic_forum/account#show"
    post "/ao3-fanfic/crypto-payments" => "ao3_fanfic_forum/crypto_payments#create"
    get "/ao3-fanfic/advanced-login" => "static#show", id: "login"
    get "/ao3-fanfic/login" => "ao3_fanfic_forum/login#show"
    post "/ao3-fanfic/login" => "session#create"
    post "/ao3-fanfic/logout" => "ao3_fanfic_forum/logout#create"
    get "/ao3-fanfic/password-reset" => "ao3_fanfic_forum/password_reset#show"
    post "/ao3-fanfic/password-reset" => "session#forgot_password"
    post "/ao3-fanfic/room-requests" => "ao3_fanfic_forum/room_requests#create"
    get "/ao3-fanfic/signup" => "ao3_fanfic_forum/signup#show"
    post "/ao3-fanfic/signup" => "users#create"
    get "/ao3-fanfic/supporter" => "ao3_fanfic_forum/supporter#show"
    get "/ao3-fanfic/supporter-status" => "ao3_fanfic_forum/supporter_status#show"
    get "/ao3-fanfic/terms" => "ao3_fanfic_forum/terms#index"
    get "/ao3-fanfic/topics" => "ao3_fanfic_forum/topics#index"
    put "/ao3-fanfic/topics/:topic_id/metadata" => "ao3_fanfic_forum/metadata#update"
    get "/login" => redirect("#{Discourse.base_path}/ao3-fanfic/login")
    get "/password-reset" => redirect("#{Discourse.base_path}/ao3-fanfic/password-reset")
    get "/signup" => redirect("#{Discourse.base_path}/ao3-fanfic/signup")
  end

  Ao3FanficForum::AuthConfiguration.apply!

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

  on(:topic_destroyed) do |topic, _user|
    Ao3FanficForum::Metadata.clear_for_topic_id!(topic.id)
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
