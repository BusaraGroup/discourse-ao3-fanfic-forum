# frozen_string_literal: true

module Ao3FanficForum
  class TopicMetadata < ::ActiveRecord::Base
    self.table_name = "ao3_fanfic_topic_metadata"

    belongs_to :topic
  end
end

# == Schema Information
#
# Table name: ao3_fanfic_topic_metadata
#
#  id               :bigint           not null, primary key
#  chapter_ref      :string
#  discussion_type  :string           default("general"), not null
#  fic_author       :string
#  fic_title        :string
#  fic_url          :text
#  post_anonymously :boolean          default(FALSE), not null
#  spoiler_label    :string
#  spoiler_until    :datetime
#  visibility       :string           default("public"), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  space_group_id   :integer
#  topic_id         :integer          not null
#
# Indexes
#
#  index_ao3_fanfic_topic_metadata_on_discussion_type  (discussion_type)
#  index_ao3_fanfic_topic_metadata_on_space_group_id   (space_group_id)
#  index_ao3_fanfic_topic_metadata_on_spoiler_until    (spoiler_until)
#  index_ao3_fanfic_topic_metadata_on_topic_id         (topic_id) UNIQUE
#  index_ao3_fanfic_topic_metadata_on_visibility       (visibility)
#
