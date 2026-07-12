# frozen_string_literal: true

module Ao3FanficForum
  class TopicTerm < ::ActiveRecord::Base
    self.table_name = "ao3_fanfic_topic_terms"

    belongs_to :topic
  end
end

# == Schema Information
#
# Table name: ao3_fanfic_topic_terms
#
#  id         :bigint           not null, primary key
#  normalized :string           not null
#  term_type  :string           not null
#  value      :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  topic_id   :integer          not null
#
# Indexes
#
#  idx_ao3_terms_topic_type_normalized       (topic_id,term_type,normalized) UNIQUE
#  idx_ao3_terms_type_normalized_topic       (term_type,normalized,topic_id)
#  index_ao3_fanfic_topic_terms_on_topic_id  (topic_id)
#
