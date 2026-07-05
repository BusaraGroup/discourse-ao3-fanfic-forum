# frozen_string_literal: true

module Ao3FanficForum
  class TopicTerm < ::ActiveRecord::Base
    self.table_name = "ao3_fanfic_topic_terms"

    belongs_to :topic
  end
end
