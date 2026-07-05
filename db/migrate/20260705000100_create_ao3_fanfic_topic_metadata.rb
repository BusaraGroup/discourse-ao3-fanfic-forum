# frozen_string_literal: true

class CreateAo3FanficTopicMetadata < ActiveRecord::Migration[7.0]
  def change
    return if table_exists?(:ao3_fanfic_topic_metadata)

    create_table :ao3_fanfic_topic_metadata do |t|
      t.integer :topic_id, null: false
      t.string :discussion_type, null: false, default: "general"
      t.string :spoiler_label
      t.datetime :spoiler_until
      t.text :fic_url
      t.string :fic_title
      t.string :fic_author
      t.string :chapter_ref
      t.string :visibility, null: false, default: "public"
      t.integer :space_group_id
      t.boolean :post_anonymously, null: false, default: false
      t.timestamps
    end

    add_index :ao3_fanfic_topic_metadata, :topic_id, unique: true
    add_index :ao3_fanfic_topic_metadata, :discussion_type
    add_index :ao3_fanfic_topic_metadata, :visibility
    add_index :ao3_fanfic_topic_metadata, :space_group_id
    add_index :ao3_fanfic_topic_metadata, :spoiler_until
  end
end
