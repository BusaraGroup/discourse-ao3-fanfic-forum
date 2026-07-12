# frozen_string_literal: true

require_relative "../ao3_fanfic_forum/auth_configuration"

module Ao3FanficForum
  module Setup
    module_function

    def site_setting_exists?(name)
      SiteSetting.respond_to?(:"#{name}=")
    end

    def set_site_setting(name, value)
      SiteSetting.public_send(:"#{name}=", value) if site_setting_exists?(name)
    end

    def configure_auth!
      Ao3FanficForum::AuthConfiguration.apply!
    end

    def configure_brand!
      set_site_setting(:title, "AO3Chat")
      set_site_setting(:short_title, "AO3Chat")
      set_site_setting(
        :site_description,
        "A privacy-first AO3 reader discussion space for fic recs, chapter threads, fic finding, fandom rooms, spoilers, and content warnings.",
      )
      set_site_setting(
        :extended_site_description,
        "AO3Chat is an unofficial, reader-run space for discussing fanfiction. It is not affiliated with Archive of Our Own or the Organization for Transformative Works.",
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

    def configure_brand_assets!
      wordmark = ensure_brand_upload!("ao3chat-wordmark.svg")
      dark_wordmark = ensure_brand_upload!("ao3chat-wordmark-dark.svg")
      mark = ensure_brand_upload!("ao3chat-mark.png")
      social = ensure_brand_upload!("ao3chat-social.png")

      set_site_setting(:logo, wordmark)
      set_site_setting(:mobile_logo, wordmark)
      set_site_setting(:logo_dark, dark_wordmark)
      set_site_setting(:mobile_logo_dark, dark_wordmark)
      set_site_setting(:logo_small, mark)
      set_site_setting(:logo_small_dark, mark)
      set_site_setting(:large_icon, mark)
      set_site_setting(:manifest_icon, mark)
      set_site_setting(:favicon, mark)
      set_site_setting(:apple_touch_icon, mark)
      set_site_setting(:opengraph_image, social)
    end

    def ensure_brand_upload!(filename)
      path = File.expand_path("../../public/images/#{filename}", __dir__)

      File.open(path, "rb") do |file|
        upload = UploadCreator.new(file, filename).create_for(Discourse::SYSTEM_USER_ID)
        raise "Could not install AO3Chat brand asset: #{filename}" if upload.blank?

        upload
      end
    end

    def configure_beta_security!
      set_site_setting(:force_https, true)
      set_site_setting(:enforce_second_factor, "staff")
      set_site_setting(:invite_allowed_groups, "1|2")
      set_site_setting(:invite_expiry_days, 14)
      set_site_setting(:hide_user_profiles_from_public, true)
      set_site_setting(:default_hide_profile, true)
      set_site_setting(:enable_user_directory, false)
      set_site_setting(:enable_group_directory, false)
      set_site_setting(:hide_user_activity_tab, true)
      set_site_setting(:enable_names, false)
      set_site_setting(:use_name_for_username_suggestions, false)
      set_site_setting(:share_anonymized_statistics, false)
      set_site_setting(:discourse_narrative_bot_enabled, false)
      set_site_setting(:disable_discourse_narrative_bot_welcome_post, true)
      set_site_setting(:use_site_small_logo_as_system_avatar, true)
      set_site_setting(:log_out_strict, true)
      set_site_setting(:maximum_session_age, 720)
      set_site_setting(:allow_index_in_robots_txt, false)
      set_site_setting(:anonymous_posting_allowed_groups, "1|2|10")
    end

    def beta_checks
      supporter_group = ensure_supporter_group!
      private_category = SupporterAccess.private_rooms_category
      notification_email = SiteSetting.notification_email.to_s

      {
        "Invite-only registration" => SiteSetting.invite_only,
        "Invitation redemption enabled" => SiteSetting.allow_new_registrations,
        "Login required" => SiteSetting.login_required,
        "Public signup call-to-action disabled" => !SiteSetting.enable_signup_cta,
        "Local login enabled" => SiteSetting.enable_local_logins,
        "External social login disabled" =>
          AuthConfiguration::SOCIAL_LOGIN_SETTINGS.none? do |setting|
            SiteSetting.respond_to?(setting) && SiteSetting.public_send(setting)
          end,
        "HTTPS enforced" => SiteSetting.force_https,
        "Staff two-factor authentication enforced" => %w[staff all].include?(
          SiteSetting.enforce_second_factor,
        ),
        "Public user directory disabled" => !SiteSetting.enable_user_directory,
        "Public profiles hidden" => SiteSetting.hide_user_profiles_from_public,
        "Usage telemetry disabled" => !SiteSetting.share_anonymized_statistics,
        "Platform footer disabled" => !SiteSetting.enable_powered_by_discourse,
        "Onboarding bot disabled" =>
          !SiteSetting.respond_to?(:discourse_narrative_bot_enabled) ||
            !SiteSetting.discourse_narrative_bot_enabled,
        "Backups enabled" => SiteSetting.enable_backups,
        "Notification email configured" =>
          notification_email.present? && notification_email.exclude?("noreply@unconfigured"),
        "Supporter group private" =>
          supporter_group.visibility_level == Group.visibility_levels[:owners] &&
            supporter_group.members_visibility_level == Group.visibility_levels[:owners],
        "Private rooms restricted" =>
          private_category.present? && private_category.read_restricted &&
            private_category.groups.exists?(id: supporter_group.id),
      }
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
      set_site_setting(:ao3_fanfic_subscribe_url, Ao3FanficForum::SupporterAccess::SUPPORTER_PATH)
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
      set_site_setting(:ao3_fanfic_supporter_checkout_url, "/s/#{product[:id]}")
      set_site_setting(:ao3_fanfic_subscribe_url, Ao3FanficForum::SupporterAccess::SUPPORTER_PATH)
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
  desc "Apply production-oriented defaults for AO3Chat"
  task configure: :environment do
    SiteSetting.ao3_fanfic_enabled = true
    Ao3FanficForum::Setup.configure_brand!
    Ao3FanficForum::Setup.configure_brand_assets!
    Ao3FanficForum::Setup.configure_auth!
    Ao3FanficForum::Setup.configure_beta_security!
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
        description:
          "Describe the fic you remember and mark the thread found when readers identify it.",
        color: "246A73",
        position: 3,
        permissions: {
          everyone: :full,
        },
      },
      {
        name: "Chapter Discussions",
        slug: "chapter-discussions",
        description:
          "Discuss updates chapter by chapter with spoiler labels and readalong threads.",
        color: "6B4E71",
        position: 4,
        permissions: {
          everyone: :full,
        },
      },
      {
        name: "Spoiler Zone",
        slug: "spoiler-zone",
        description:
          "Current-chapter reactions, ending discussion, reread reveals, and clearly labeled spoiler threads.",
        color: "7C315D",
        position: 5,
        permissions: {
          everyone: :full,
        },
      },
      {
        name: "Content Warnings",
        slug: "content-warnings",
        description:
          "Discuss warning vocabulary, tagging conventions, and reader filtering expectations.",
        color: "8C5A2B",
        position: 6,
        permissions: {
          everyone: :full,
        },
      },
      {
        name: "Fandom Spaces",
        slug: "fandom-spaces",
        description:
          "Broad fandom talk, ship discussion, trope threads, and private room requests.",
        color: "2F6F4E",
        position: 7,
        permissions: {
          everyone: :full,
        },
      },
      {
        name: "Harry Potter",
        slug: "harry-potter",
        description:
          "A home for Harry Potter recs, ship talk, fic searches, rereads, and spoiler-marked discussion.",
        color: "7C315D",
        position: 8,
        permissions: {
          everyone: :full,
        },
      },
      {
        name: "Marvel",
        slug: "marvel",
        description:
          "A home for Marvel recs, MCU and comics threads, ship talk, fic searches, and spoiler-safe discussion.",
        color: "B33951",
        position: 9,
        permissions: {
          everyone: :full,
        },
      },
      {
        name: "K-POP",
        slug: "k-pop",
        description:
          "A home for K-POP recs, fandom talk, ship tags, readalongs, and fic-finding threads.",
        color: "246A73",
        position: 10,
        permissions: {
          everyone: :full,
        },
      },
      {
        name: "BTS",
        slug: "bts",
        description:
          "A home for BTS recs, ship discussion, fic searches, chapter threads, and spoiler-safe reader talk.",
        color: "6B4E71",
        position: 11,
        permissions: {
          everyone: :full,
        },
      },
      {
        name: "Reader Lounge",
        slug: "reader-lounge",
        description: "Off-topic reader chat, reading moods, events, and community conversation.",
        color: "4E6A8D",
        position: 12,
        permissions: {
          everyone: :full,
        },
      },
      {
        name: "Site Help",
        slug: "site-help",
        description: "Questions about accounts, private rooms, tags, and AO3Chat tools.",
        color: "5E6C75",
        position: 13,
        permissions: {
          everyone: :full,
        },
      },
      {
        name: "Private Fandom Rooms",
        slug: SiteSetting.ao3_fanfic_private_rooms_category_slug,
        description:
          "Supporter-only fandom circles, private ship rooms, readalongs, and spoiler-heavy discussion threads.",
        color: "9F2536",
        position: 14,
        permissions: {
          supporter_group.name => :full,
          :staff => :full,
        },
      },
      {
        name: "Announcements",
        slug: "announcements",
        description: "Official AO3Chat updates, maintenance notices, and policy changes.",
        color: "3B5D8F",
        position: 15,
        permissions: {
          everyone: :readonly,
          staff: :full,
        },
      },
      {
        name: "Guidelines",
        slug: "guidelines",
        legacy_slugs: ["site-rules"],
        description:
          "Community rules, privacy notes, moderation policy, and unofficial AO3Chat status.",
        color: "4A5568",
        position: 16,
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
        position: 17,
        permissions: {
          staff: :full,
        },
      },
    ]

    created_categories =
      categories.map { |attrs| [attrs, Ao3FanficForum::Setup.ensure_category!(attrs)] }
    category_ids = created_categories.map { |_, category| category.id }
    sidebar_category_ids =
      created_categories
        .select { |attrs, _| attrs.dig(:permissions, :everyone).present? }
        .map { |_, category| category.id }
    default_composer_category =
      created_categories.find { |attrs, _| attrs[:slug] == "fic-recs" }&.last ||
        created_categories.first.last

    SiteSetting.ao3_fanfic_featured_fandom_slugs = "harry-potter|marvel|k-pop|bts"
    SiteSetting.default_navigation_menu_categories = sidebar_category_ids.join("|")
    SiteSetting.default_composer_category = default_composer_category.id
    Ao3FanficForum::Setup.configure_subscription_settings!(supporter_group)

    User
      .real
      .where(staged: false)
      .find_each do |user|
        SidebarSectionLinksUpdater.update_category_section_links(
          user,
          category_ids: sidebar_category_ids,
        )
      end

    puts "AO3Chat defaults applied: local auth enabled, #{category_ids.length} categories ready, private rooms gated by #{supporter_group.name}."
  end

  desc "Audit AO3Chat invite-only beta security and operations"
  task beta_audit: :environment do
    checks = Ao3FanficForum::Setup.beta_checks

    checks.each { |label, passed| puts "#{passed ? "PASS" : "FAIL"}: #{label}" }

    failed = checks.count { |_, passed| !passed }
    abort "AO3Chat beta audit failed with #{failed} issue(s)." if failed.positive?

    puts "AO3Chat beta audit passed."
  end

  desc "Add current public rooms to every reader's sidebar"
  task sync_public_rooms: :environment do
    previous_category_ids = SiteSetting.default_navigation_menu_categories
    public_category_ids = Category.where(read_restricted: false).order(:position).pluck(:id)
    new_category_ids = public_category_ids.join("|")

    SiteSetting.default_navigation_menu_categories = new_category_ids

    SidebarSiteSettingsBackfiller.new(
      "default_navigation_menu_categories",
      previous_value: previous_category_ids,
      new_value: new_category_ids,
    ).backfill!

    puts "AO3Chat sidebars updated with #{public_category_ids.length} public rooms."
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
    puts "Checkout URL: #{SiteSetting.ao3_fanfic_supporter_checkout_url}"
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
