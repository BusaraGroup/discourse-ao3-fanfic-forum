# frozen_string_literal: true

class RemoveOrphanedAo3FanficTopicRows < ActiveRecord::Migration[7.0]
  TABLES = %i[ao3_fanfic_topic_metadata ao3_fanfic_topic_terms].freeze

  def up
    TABLES.each do |table|
      execute <<~SQL
        DELETE FROM #{table}
        WHERE NOT EXISTS (
          SELECT 1 FROM topics WHERE topics.id = #{table}.topic_id
        )
      SQL
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
