# frozen_string_literal: true

module Ao3FanficForum
  module Setup
    SOCIAL_LOGIN_SETTINGS = %i[
      enable_discourse_id
      enable_google_oauth2_logins
      enable_twitter_logins
      enable_facebook_logins
      enable_github_logins
      enable_discord_logins
      enable_linkedin_oidc_logins
      microsoft_auth_enabled
      openid_connect_enabled
      oauth2_enabled
      patreon_login_enabled
      sign_in_with_apple_enabled
    ].freeze

    module_function

    def site_setting_exists?(name)
      SiteSetting.respond_to?(:"#{name}=")
    end

    def set_site_setting(name, value)
      SiteSetting.public_send(:"#{name}=", value) if site_setting_exists?(name)
    end

    def configure_auth!
      set_site_setting(:enable_local_logins, true)
      set_site_setting(:enable_local_logins_via_email, true)
      set_site_setting(:allow_new_registrations, true)
      set_site_setting(:enable_signup_cta, true)
      set_site_setting(:hide_email_address_taken, true)

      SOCIAL_LOGIN_SETTINGS.each { |setting| set_site_setting(setting, false) }
      set_site_setting(:discourse_id_client_id, "")
      set_site_setting(:discourse_id_client_secret, "")
    end

    def configure_brand!
      set_site_setting(:title, "AO3Chat")
      set_site_setting(:short_title, "AO3Chat")
      set_site_setting(
        :site_description,
        "A privacy-first fanfic discussion forum for AO3 readers: fic recs, chapter threads, fic finding, fandom spaces, spoilers, and content warnings.",
      )
      set_site_setting(
        :extended_site_description,
        "AO3Chat is an unofficial, reader-run forum for discussing fanfiction. It is not affiliated with Archive of Our Own or the Organization for Transformative Works.",
      )
      set_site_setting(:enable_powered_by_discourse, false)
      set_site_setting(:enable_site_owner_onboarding, false)
      set_site_setting(:default_other_skip_new_user_tips, true)
      set_site_setting(:send_welcome_message, false)
      set_site_setting(:send_tl1_welcome_message, false)
      set_site_setting(:privacy_policy_url, "/privacy")
      set_site_setting(:tos_url, "/tos")
      set_site_setting(:faq_url, "/faq")
    end

    def ensure_supporter_group!
      group_name = SiteSetting.ao3_fanfic_supporter_group_name.presence || "ao3chat_supporters"
      group = Group.find_by(name: group_name) || Group.create!(name: group_name)
      group.update!(
        full_name: "AO3Chat supporters",
        title: "Supporter",
        flair_icon: "lock",
        public_admission: false,
        public_exit: false,
        visibility_level: Group.visibility_levels[:owners],
        members_visibility_level: Group.visibility_levels[:owners],
      )
      group
    end

    def ensure_category!(attrs)
      legacy_slugs = Array(attrs[:legacy_slugs])
      category =
        Category.find_by(slug: attrs[:slug]) || Category.where(slug: legacy_slugs).first ||
          Category.find_by(name: attrs[:name]) || Category.new
      category.name = attrs[:name]
      category.slug = attrs[:slug]
      category.description = attrs[:description]
      category.color = attrs[:color]
      category.text_color = "FFFFFF"
      category.position = attrs[:position]
      category.user = Discourse.system_user
      category.set_permissions(attrs[:permissions])
      category.save!
      category
    end

    def configure_subscription_settings!(supporter_group)
      return if !site_setting_exists?(:discourse_subscriptions_campaign_group)

      set_site_setting(:discourse_subscriptions_campaign_group, supporter_group.id)
      set_site_setting(:discourse_subscriptions_campaign_type, "Subscribers")
      set_site_setting(:discourse_subscriptions_campaign_goal, 100)
      set_site_setting(:discourse_subscriptions_campaign_banner_location, "Sidebar")
      set_site_setting(:discourse_subscriptions_extra_nav_subscribe, false)

      if SiteSetting.discourse_subscriptions_public_key.present? &&
           SiteSetting.discourse_subscriptions_secret_key.present?
        set_site_setting(:discourse_subscriptions_enabled, true)
      end
    end

    def stripe_ready?
      defined?(::Stripe) && defined?(::DiscourseSubscriptions::Product) &&
        SiteSetting.respond_to?(:discourse_subscriptions_public_key) &&
        SiteSetting.discourse_subscriptions_public_key.present? &&
        SiteSetting.discourse_subscriptions_secret_key.present?
    end

    def ensure_stripe_product!
      product_id = SiteSetting.ao3_fanfic_subscription_product_id
      product = retrieve_stripe_product(product_id) if product_id.present?
      product ||= create_stripe_product

      DiscourseSubscriptions::Product.find_or_create_by!(external_id: product[:id])
      set_site_setting(:ao3_fanfic_subscription_product_id, product[:id])
      set_site_setting(:discourse_subscriptions_campaign_product, product[:id])
      set_site_setting(:ao3_fanfic_subscribe_url, "/s/#{product[:id]}")
      product
    end

    def retrieve_stripe_product(product_id)
      ::Stripe::Product.retrieve(product_id, DiscourseSubscriptions::Stripe.request_opts)
    rescue ::Stripe::InvalidRequestError
      nil
    end

    def create_stripe_product
      ::Stripe::Product.create(
        {
          name: "AO3Chat supporter",
          active: true,
          metadata: {
            description:
              "Unlock AO3Chat private fandom rooms and support reader-run community infrastructure.",
          },
        },
        DiscourseSubscriptions::Stripe.request_opts,
      )
    end

    def ensure_monthly_stripe_price!(product, supporter_group)
      amount = SiteSetting.ao3_fanfic_supporter_monthly_amount_cents.to_i
      currency = SiteSetting.discourse_subscriptions_currency.downcase
      prices =
        ::Stripe::Price.list(
          { active: true, product: product[:id], limit: 100 },
          DiscourseSubscriptions::Stripe.request_opts,
        )

      existing =
        prices[:data].find do |price|
          recurring = price[:recurring] || {}
          metadata = price[:metadata] || {}
          price[:unit_amount] == amount && price[:currency] == currency &&
            recurring[:interval] == "month" && metadata[:group_name] == supporter_group.name
        end
      return existing if existing

      ::Stripe::Price.create(
        {
          nickname: "Supporter monthly",
          unit_amount: amount,
          product: product[:id],
          currency: currency,
          active: true,
          recurring: {
            interval: "month",
          },
          metadata: {
            group_name: supporter_group.name,
          },
        },
        DiscourseSubscriptions::Stripe.request_opts,
      )
    end
  end
end

namespace :ao3_fanfic_forum do
  desc "Apply production-oriented defaults for an AO3 reader forum"
  task configure: :environment do
    SiteSetting.ao3_fanfic_enabled = true
    Ao3FanficForum::Setup.configure_brand!
    Ao3FanficForum::Setup.configure_auth!
    SiteSetting.tagging_enabled = true
    SiteSetting.allow_anonymous_mode = true
    SiteSetting.max_post_length = 150_000
    SiteSetting.max_quotes_per_post = 100
    SiteSetting.remove_full_quote = false
    SiteSetting.suppress_reply_when_quoting = false
    SiteSetting.topic_featured_link_enabled = true
    SiteSetting.enable_welcome_banner = false
    SiteSetting.chat_enabled = false if SiteSetting.respond_to?(:chat_enabled=)

    supporter_group = Ao3FanficForum::Setup.ensure_supporter_group!

    categories = [
      {
        name: "Welcome Desk",
        slug: "welcome-desk",
        description: "New reader introductions, account help, and orientation for AO3Chat norms.",
        color: "B33951",
        position: 1,
        permissions: {
          everyone: :full,
        },
      },
      {
        name: "Fic Recs",
        slug: "fic-recs",
        description: "Recommend completed works, hidden gems, rereads, and themed rec lists.",
        color: "A71930",
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
        name: "Chapter Discussions",
        slug: "chapter-discussions",
        description: "Discuss updates chapter by chapter with spoiler labels and readalong threads.",
        color: "6B4E71",
        position: 4,
        permissions: {
          everyone: :full,
        },
      },
      {
        name: "Spoiler Zone",
        slug: "spoiler-zone",
        description: "Current-chapter reactions, ending discussion, reread reveals, and clearly labeled spoiler threads.",
        color: "7C315D",
        position: 5,
        permissions: {
          everyone: :full,
        },
      },
      {
        name: "Content Warnings",
        slug: "content-warnings",
        description: "Discuss warning vocabulary, tagging conventions, and reader filtering expectations.",
        color: "8C5A2B",
        position: 6,
        permissions: {
          everyone: :full,
        },
      },
      {
        name: "Fandom Spaces",
        slug: "fandom-spaces",
        description: "Broad fandom talk, ship discussion, trope threads, and semi-private space requests.",
        color: "2F6F4E",
        position: 7,
        permissions: {
          everyone: :full,
        },
      },
      {
        name: "Reader Lounge",
        slug: "reader-lounge",
        description: "Off-topic reader chat, reading moods, events, and community conversation.",
        color: "4E6A8D",
        position: 8,
        permissions: {
          everyone: :full,
        },
      },
      {
        name: "Site Help",
        slug: "site-help",
        description: "Questions about accounts, privacy settings, anonymous posting, tags, and forum tools.",
        color: "5E6C75",
        position: 9,
        permissions: {
          everyone: :full,
        },
      },
      {
        name: "Private Fandom Rooms",
        slug: SiteSetting.ao3_fanfic_private_rooms_category_slug,
        description: "Supporter-only fandom circles, private ship rooms, readalongs, and higher-privacy discussion threads.",
        color: "9F2536",
        position: 10,
        permissions: {
          supporter_group.name => :full,
          staff: :full,
        },
      },
      {
        name: "Announcements",
        slug: "announcements",
        description: "Official AO3Chat updates, maintenance notices, and policy changes.",
        color: "3B5D8F",
        position: 11,
        permissions: {
          everyone: :readonly,
          staff: :full,
        },
      },
      {
        name: "Guidelines",
        slug: "guidelines",
        legacy_slugs: ["site-rules"],
        description: "Forum rules, privacy notes, moderation policy, and unofficial AO3Chat status.",
        color: "4A5568",
        position: 12,
        permissions: {
          everyone: :readonly,
          staff: :full,
        },
      },
      {
        name: "Moderation",
        slug: "moderation",
        description: "Staff-only reports, policy review, and moderation coordination.",
        color: "2E3440",
        position: 13,
        permissions: {
          staff: :full,
        },
      },
    ]

    created_categories =
      categories.map do |attrs|
        [attrs, Ao3FanficForum::Setup.ensure_category!(attrs)]
      end
    category_ids = created_categories.map { |_, category| category.id }
    sidebar_category_ids =
      created_categories
        .select { |attrs, _| attrs.dig(:permissions, :everyone).present? }
        .map { |_, category| category.id }
    default_composer_category =
      created_categories.find { |attrs, _| attrs[:slug] == "fic-recs" }&.last ||
        created_categories.first.last

    SiteSetting.ao3_fanfic_allowed_space_groups = supporter_group.id.to_s
    SiteSetting.default_navigation_menu_categories = sidebar_category_ids.join("|")
    SiteSetting.default_composer_category = default_composer_category.id
    Ao3FanficForum::Setup.configure_subscription_settings!(supporter_group)

    User.real.where(staged: false).find_each do |user|
      SidebarSectionLinksUpdater.update_category_section_links(
        user,
        category_ids: sidebar_category_ids,
      )
    end

    puts "AO3Chat defaults applied: local auth enabled, #{category_ids.length} categories ready, private rooms gated by #{supporter_group.name}."
  end

  desc "Create or verify the AO3Chat Stripe-backed supporter tier"
  task setup_paid_tier: :environment do
    supporter_group = Ao3FanficForum::Setup.ensure_supporter_group!
    Ao3FanficForum::Setup.configure_subscription_settings!(supporter_group)

    if !Ao3FanficForum::Setup.stripe_ready?
      puts "AO3Chat supporter group and private room gate are ready."
      puts "Add Stripe publishable, secret, and webhook keys before creating the checkout product."
      next
    end

    product = Ao3FanficForum::Setup.ensure_stripe_product!
    price = Ao3FanficForum::Setup.ensure_monthly_stripe_price!(product, supporter_group)
    SiteSetting.discourse_subscriptions_enabled = true

    puts "AO3Chat paid tier ready."
    puts "Stripe product: #{product[:id]}"
    puts "Monthly price: #{price[:id]}"
    puts "Supporter URL: #{SiteSetting.ao3_fanfic_subscribe_url}"
    puts "Successful payments grant group: #{supporter_group.name}"
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
