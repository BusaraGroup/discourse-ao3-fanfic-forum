# frozen_string_literal: true

module Ao3FanficForum
  module Fields
    DISCUSSION_TYPE = "ao3_discussion_type"
    FANDOM_TAGS = "ao3_fandom_tags"
    SHIP_TAGS = "ao3_ship_tags"
    CONTENT_WARNINGS = "ao3_content_warnings"
    SPOILER_LABEL = "ao3_spoiler_label"
    SPOILER_UNTIL = "ao3_spoiler_until"
    FIC_URL = "ao3_fic_url"
    FIC_TITLE = "ao3_fic_title"
    FIC_AUTHOR = "ao3_fic_author"
    CHAPTER_REF = "ao3_chapter_ref"
    VISIBILITY = "ao3_visibility"
    SPACE_GROUP_ID = "ao3_space_group_id"
    POST_ANONYMOUSLY = "ao3_post_anonymously"

    DISCUSSION_TYPES = %w[general fic_recommendation chapter_discussion looking_for_fic].freeze
    VISIBILITIES = %w[public members space].freeze
    TERM_FIELDS = [FANDOM_TAGS, SHIP_TAGS, CONTENT_WARNINGS].freeze
    FIELD_NAMES =
      [
        DISCUSSION_TYPE,
        FANDOM_TAGS,
        SHIP_TAGS,
        CONTENT_WARNINGS,
        SPOILER_LABEL,
        SPOILER_UNTIL,
        FIC_URL,
        FIC_TITLE,
        FIC_AUTHOR,
        CHAPTER_REF,
        VISIBILITY,
        SPACE_GROUP_ID,
        POST_ANONYMOUSLY,
      ].freeze

    CUSTOM_FIELD_TYPES =
      {
        DISCUSSION_TYPE => {
          max_length: 40,
        },
        FANDOM_TAGS => {
          max_length: 4000,
        },
        SHIP_TAGS => {
          max_length: 4000,
        },
        CONTENT_WARNINGS => {
          max_length: 4000,
        },
        SPOILER_LABEL => {
          max_length: 120,
        },
        SPOILER_UNTIL => {
          max_length: 40,
        },
        FIC_URL => {
          max_length: 2048,
        },
        FIC_TITLE => {
          max_length: 240,
        },
        FIC_AUTHOR => {
          max_length: 160,
        },
        CHAPTER_REF => {
          max_length: 80,
        },
        VISIBILITY => {
          max_length: 24,
        },
        SPACE_GROUP_ID => {
          max_length: 24,
        },
        POST_ANONYMOUSLY => {
          max_length: 8,
        },
      }.freeze

    def self.field_names
      FIELD_NAMES
    end
  end
end
