# frozen_string_literal: true

module Ao3FanficForum
  class TopicMetadata < ::ActiveRecord::Base
    self.table_name = "ao3_fanfic_topic_metadata"

    belongs_to :topic
  end
end
