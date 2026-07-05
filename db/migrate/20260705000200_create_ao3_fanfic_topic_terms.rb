# frozen_string_literal: true

class CreateAo3FanficTopicTerms < ActiveRecord::Migration[7.0]
  def change
    return if table_exists?(:ao3_fanfic_topic_terms)

    create_table :ao3_fanfic_topic_terms do |t|
      t.integer :topic_id, null: false
      t.string :term_type, null: false
      t.string :value, null: false
      t.string :normalized, null: false
      t.timestamps
    end

    add_index :ao3_fanfic_topic_terms,
              %i[topic_id term_type normalized],
              unique: true,
              name: "idx_ao3_terms_topic_type_normalized"
    add_index :ao3_fanfic_topic_terms,
              %i[term_type normalized topic_id],
              name: "idx_ao3_terms_type_normalized_topic"
    add_index :ao3_fanfic_topic_terms, :topic_id
  end
end
