# frozen_string_literal: true

module Ao3FanficForum
  module SupporterAccess
    SUPPORTER_PATH = "/ao3-fanfic/supporter"
    CHECKOUT_FALLBACK_PATH = "/s"
    CRYPTO_METHODS =
      [
        {
          key: "btc",
          code: "BTC",
          address_setting: :ao3_fanfic_crypto_btc_address,
          name_key: "ao3_fanfic.crypto_payment.methods.btc.name",
          network_key: "ao3_fanfic.crypto_payment.methods.btc.network",
        },
        {
          key: "ltc",
          code: "LTC",
          address_setting: :ao3_fanfic_crypto_ltc_address,
          name_key: "ao3_fanfic.crypto_payment.methods.ltc.name",
          network_key: "ao3_fanfic.crypto_payment.methods.ltc.network",
        },
        {
          key: "xmr",
          code: "XMR",
          address_setting: :ao3_fanfic_crypto_xmr_address,
          name_key: "ao3_fanfic.crypto_payment.methods.xmr.name",
          network_key: "ao3_fanfic.crypto_payment.methods.xmr.network",
        },
      ].freeze

    module_function

    def group_name
      SiteSetting.ao3_fanfic_supporter_group_name.presence || "ao3chat_supporters"
    end

    def supporter_group
      Group.find_by(name: group_name)
    end

    def supporter?(user)
      group = supporter_group
      user.present? && group.present? && GroupUser.exists?(group: group, user: user)
    end

    def private_room_access?(user)
      user&.staff? || supporter?(user)
    end

    def private_rooms_category
      slug =
        SiteSetting.ao3_fanfic_private_rooms_category_slug.presence || "private-fandom-rooms"
      Category.find_by(slug: slug)
    end

    def subscribe_url
      configured_url = SiteSetting.ao3_fanfic_subscribe_url.presence

      return configured_url if configured_url.present? && !subscription_checkout_url?(configured_url)

      SUPPORTER_PATH
    end

    def checkout_url
      configured_url =
        if SiteSetting.respond_to?(:ao3_fanfic_supporter_checkout_url)
          SiteSetting.ao3_fanfic_supporter_checkout_url.presence
        end
      return configured_url if configured_url.present?

      legacy_url = SiteSetting.ao3_fanfic_subscribe_url.presence
      return legacy_url if legacy_url.present? && subscription_checkout_url?(legacy_url)
    end

    def crypto_payment_methods
      return [] if !SiteSetting.ao3_fanfic_crypto_payments_enabled

      CRYPTO_METHODS.filter_map do |method|
        address = SiteSetting.public_send(method[:address_setting]).presence
        next if address.blank?

        method.merge(address: address)
      end
    end

    def crypto_payment_method(currency)
      normalized_currency = currency.to_s.downcase
      crypto_payment_methods.find { |method| method[:key] == normalized_currency }
    end

    def status_for(user)
      {
        signed_in: user.present?,
        supporter: supporter?(user),
        staff: user&.staff? || false,
        has_private_room_access: private_room_access?(user),
        supporter_group_name: group_name,
        subscribe_url: subscribe_url,
        private_rooms_url: private_room_url_for(user),
      }
    end

    def private_room_url_for(user)
      return if !private_room_access?(user)

      private_rooms_category&.url
    end

    def subscription_checkout_url?(url)
      url == CHECKOUT_FALLBACK_PATH || url.start_with?("#{CHECKOUT_FALLBACK_PATH}/")
    end
  end
end
