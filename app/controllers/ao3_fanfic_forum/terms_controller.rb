# frozen_string_literal: true

module Ao3FanficForum
  class TermsController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    VALID_TERM_TYPES = %w[fandom ship warning].freeze
    MAX_LIMIT = 50

    def index
      limit = params[:limit].presence&.to_i || 12
      limit = limit.clamp(1, MAX_LIMIT)
      requested_types = Normalizer.list(params[:term_type])
      term_types = requested_types.presence || VALID_TERM_TYPES
      term_types &= VALID_TERM_TYPES

      terms = term_types.index_with { |term_type| terms_for_type(term_type, limit) }

      render json: { terms: terms }
    end

    private

    def visible_topic_ids
      Topic.listable_topics.visible.secured(guardian).select(:id)
    end

    def terms_for_type(term_type, limit)
      TopicTerm
        .where(topic_id: visible_topic_ids, term_type: term_type)
        .group(:normalized)
        .order(Arel.sql("COUNT(DISTINCT topic_id) DESC, MIN(value) ASC"))
        .limit(limit)
        .pluck(
          Arel.sql("MIN(value)"),
          :normalized,
          Arel.sql("COUNT(DISTINCT topic_id)"),
        )
        .map do |value, normalized, topic_count|
          {
            value: value,
            normalized: normalized,
            topic_count: topic_count,
          }
        end
    end
  end
end
