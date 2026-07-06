# frozen_string_literal: true

module Ao3FanficForum
  class SupporterController < BaseController
    requires_plugin PLUGIN_NAME

    def show
      status = SupporterAccess.status_for(current_user)

      @signed_in = status[:signed_in]
      @has_private_room_access = status[:has_private_room_access]
      @price_label = SiteSetting.ao3_fanfic_supporter_price_label
      @home_url = discourse_path("/")
      @login_url = discourse_path("/login")
      @signup_url = discourse_path("/signup")
      @payment_methods_url = discourse_path("/ao3-fanfic/supporter#payment-methods")
      @stripe_checkout_url = discourse_path(SupporterAccess.checkout_url)
      @crypto_payment_methods = SupporterAccess.crypto_payment_methods
      @crypto_receipt_url = discourse_path("/ao3-fanfic/crypto-payments")
      @payment_methods_configured =
        @stripe_checkout_url.present? || @crypto_payment_methods.present?
      if status[:private_rooms_url]
        @private_rooms_url = discourse_path(status[:private_rooms_url])
      end

      assign_cta
    end

    private

    def assign_cta
      if @has_private_room_access && @private_rooms_url.present?
        @state_title_key = "ao3_fanfic.supporter_page.state.active_title"
        @state_body_key = "ao3_fanfic.supporter_page.state.active_body"
        @primary_url = @private_rooms_url
        @primary_label_key = "ao3_fanfic.supporter_page.cta.open_rooms"
        @secondary_url = @home_url
        @secondary_label_key = "ao3_fanfic.supporter_page.cta.browse_public"
      elsif @signed_in
        @state_title_key = "ao3_fanfic.supporter_page.state.ready_title"
        @state_body_key = "ao3_fanfic.supporter_page.state.ready_body"
        @primary_url = @payment_methods_url
        @primary_label_key = "ao3_fanfic.supporter_page.cta.choose_payment"
        @secondary_url = @home_url
        @secondary_label_key = "ao3_fanfic.supporter_page.cta.browse_public"
      else
        @state_title_key = "ao3_fanfic.supporter_page.state.account_title"
        @state_body_key = "ao3_fanfic.supporter_page.state.account_body"
        @primary_url = @signup_url
        @primary_label_key = "ao3_fanfic.supporter_page.cta.create_account"
        @secondary_url = @login_url
        @secondary_label_key = "ao3_fanfic.supporter_page.cta.log_in"
      end
    end
  end
end
