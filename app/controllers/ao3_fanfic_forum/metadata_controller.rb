# frozen_string_literal: true

module Ao3FanficForum
  class MetadataController < ::ApplicationController
    requires_plugin PLUGIN_NAME
    requires_login

    def update
      topic = Topic.find(params[:topic_id])
      guardian.ensure_can_edit!(topic)

      fields = params[:topic_custom_fields] || ActionController::Parameters.new
      fields = ActionController::Parameters.new(fields) if fields.is_a?(Hash)
      fields = fields.permit(*Fields.field_names)
      Metadata.apply!(topic, fields)

      render json: { ao3_fanfic: Metadata.for_topic(topic.reload) }
    rescue Discourse::InvalidParameters => e
      render_json_error(e.message, status: :bad_request)
    end
  end
end
