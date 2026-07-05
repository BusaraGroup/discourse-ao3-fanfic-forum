# frozen_string_literal: true

namespace :ao3_fanfic_forum do
  desc "Apply production-oriented defaults for an AO3 reader forum"
  task configure: :environment do
    SiteSetting.ao3_fanfic_enabled = true
    SiteSetting.title = "Anonymous Fanfic Forum"
    SiteSetting.site_description = "A privacy-first discussion forum for AO3 readers."
    SiteSetting.tagging_enabled = true
    SiteSetting.allow_anonymous_mode = true
    SiteSetting.max_post_length = 150_000
    SiteSetting.max_quotes_per_post = 100
    SiteSetting.remove_full_quote = false
    SiteSetting.suppress_reply_when_quoting = false
    SiteSetting.topic_featured_link_enabled = true

    puts "AO3 fanfic forum defaults applied."
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
