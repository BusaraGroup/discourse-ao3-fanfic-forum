# frozen_string_literal: true

class AddAo3FanficTopicForeignKeys < ActiveRecord::Migration[7.0]
  TABLES = %i[ao3_fanfic_topic_metadata ao3_fanfic_topic_terms].freeze

  def up
    TABLES.each do |table|
      execute <<~SQL
        DELETE FROM #{table}
        WHERE NOT EXISTS (
          SELECT 1 FROM topics WHERE topics.id = #{table}.topic_id
        )
      SQL

      next if foreign_key_exists?(table, :topics)

      add_foreign_key table, :topics, column: :topic_id, on_delete: :cascade
    end
  end

  def down
    TABLES.each do |table|
      remove_foreign_key table, :topics if foreign_key_exists?(table, :topics)
    end
  end
end
