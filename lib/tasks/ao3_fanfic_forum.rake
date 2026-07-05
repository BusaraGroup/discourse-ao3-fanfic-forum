# frozen_string_literal: true

namespace :ao3_fanfic_forum do
  desc "Apply production-oriented defaults for an AO3 reader forum"
  task configure: :environment do
    SiteSetting.ao3_fanfic_enabled = true
    SiteSetting.title = "AO3Chat"
    SiteSetting.short_title = "AO3Chat"
    SiteSetting.site_description =
      "A privacy-first fanfic discussion forum for AO3 readers: fic recs, chapter threads, fic finding, fandom spaces, spoilers, and content warnings."
    SiteSetting.extended_site_description =
      "AO3Chat is an unofficial, reader-run forum for discussing fanfiction. It is not affiliated with Archive of Our Own or the Organization for Transformative Works."
    SiteSetting.tagging_enabled = true
    SiteSetting.allow_anonymous_mode = true
    SiteSetting.max_post_length = 150_000
    SiteSetting.max_quotes_per_post = 100
    SiteSetting.remove_full_quote = false
    SiteSetting.suppress_reply_when_quoting = false
    SiteSetting.topic_featured_link_enabled = true

    categories = [
      {
        name: "Fic Recs",
        slug: "fic-recs",
        description: "Recommend completed works, hidden gems, rereads, and themed rec lists.",
        color: "A71930",
        position: 1,
        permissions: {
          everyone: :full,
        },
      },
      {
        name: "Chapter Discussions",
        slug: "chapter-discussions",
        description: "Discuss updates chapter by chapter with spoiler labels and readalong threads.",
        color: "6B4E71",
        position: 2,
        permissions: {
          everyone: :full,
        },
      },
      {
        name: "Looking for a Fic",
        slug: "looking-for-a-fic",
        description: "Describe the fic you remember and mark the thread found when readers identify it.",
        color: "246A73",
        position: 3,
        permissions: {
          everyone: :full,
        },
      },
      {
        name: "Fandom Spaces",
        slug: "fandom-spaces",
        description: "Create fandom-specific conversations, ship talk, trope threads, and semi-private spaces.",
        color: "2F6F4E",
        position: 4,
        permissions: {
          everyone: :full,
        },
      },
      {
        name: "Content Warnings",
        slug: "content-warnings",
        description: "Discuss warning vocabulary, tagging conventions, and reader filtering expectations.",
        color: "8C5A2B",
        position: 5,
        permissions: {
          everyone: :full,
        },
      },
      {
        name: "Site Rules",
        slug: "site-rules",
        description: "Forum rules, privacy notes, moderation policy, and unofficial AO3Chat status.",
        color: "4A5568",
        position: 6,
        permissions: {
          everyone: :readonly,
          staff: :full,
        },
      },
    ]

    category_ids =
      categories.map do |attrs|
        category =
          Category.find_by(slug: attrs[:slug]) || Category.find_by(name: attrs[:name]) ||
            Category.new(slug: attrs[:slug])
        category.name = attrs[:name]
        category.description = attrs[:description]
        category.color = attrs[:color]
        category.text_color = "FFFFFF"
        category.position = attrs[:position]
        category.user = Discourse.system_user
        category.set_permissions(attrs[:permissions])
        category.save!
        category.id
      end

    SiteSetting.default_navigation_menu_categories = category_ids.join("|")
    SiteSetting.default_composer_category = category_ids.first

    puts "AO3Chat defaults applied: settings updated and #{category_ids.length} categories ready."
  end

  desc "Rebuild AO3 fanfic metadata indexes from topic custom fields"
  task backfill: :environment do
    count = 0

    Topic.find_each do |topic|
      Ao3FanficForum::Metadata.sync_from_topic!(topic)
      count += 1
    end

    puts "Synced AO3 fanfic metadata for #{count} topics."
  end
end
