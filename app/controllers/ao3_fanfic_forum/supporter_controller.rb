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
      @login_url = discourse_path("/ao3-fanfic/login")
      @signup_url = discourse_path("/ao3-fanfic/signup")
      @payment_methods_url = discourse_path("/ao3-fanfic/supporter#payment-methods")
      @payment_settings_url =
        discourse_path("/admin/site_settings/category/plugins?filter=ao3_fanfic")
      @stripe_checkout_url = discourse_path(SupporterAccess.checkout_url)
      @crypto_payment_methods = SupporterAccess.crypto_payment_methods
      @crypto_receipt_url = discourse_path("/ao3-fanfic/crypto-payments")
      @can_configure_payments = current_user&.staff? || false
      @signup_available = AuthConfiguration.signup_available?
      @payment_methods_configured =
        @stripe_checkout_url.present? || @crypto_payment_methods.present?
      @payment_setup_checks = payment_setup_checks if @can_configure_payments
      if status[:private_rooms_url]
        @private_rooms_url = discourse_path(status[:private_rooms_url])
      end

      assign_cta
    end

    private

    def payment_setup_checks
      supporter_group = SupporterAccess.supporter_group
      private_rooms_category = SupporterAccess.private_rooms_category
      checkout_url = SupporterAccess.checkout_url
      crypto_count = @crypto_payment_methods.length

      [
        {
          ready: checkout_url.present?,
          label_key: "ao3_fanfic.supporter_page.setup.stripe_label",
          ready_key: "ao3_fanfic.supporter_page.setup.stripe_ready",
          missing_key: "ao3_fanfic.supporter_page.setup.stripe_missing",
        },
        {
          ready: crypto_count.positive?,
          label_key: "ao3_fanfic.supporter_page.setup.crypto_label",
          ready_key: "ao3_fanfic.supporter_page.setup.crypto_ready",
          missing_key: "ao3_fanfic.supporter_page.setup.crypto_missing",
          count: crypto_count,
        },
        {
          ready: supporter_group.present?,
          label_key: "ao3_fanfic.supporter_page.setup.group_label",
          ready_key: "ao3_fanfic.supporter_page.setup.group_ready",
          missing_key: "ao3_fanfic.supporter_page.setup.group_missing",
          name: SupporterAccess.group_name,
        },
        {
          ready: private_rooms_category.present?,
          label_key: "ao3_fanfic.supporter_page.setup.rooms_label",
          ready_key: "ao3_fanfic.supporter_page.setup.rooms_ready",
          missing_key: "ao3_fanfic.supporter_page.setup.rooms_missing",
        },
      ]
    end

    def assign_cta
      if @has_private_room_access && @private_rooms_url.present?
        @state_title_key = "ao3_fanfic.supporter_page.state.active_title"
        @state_body_key = "ao3_fanfic.supporter_page.state.active_body"
        @primary_url = @private_rooms_url
        @primary_label_key = "ao3_fanfic.supporter_page.cta.open_rooms"
        @secondary_url = @home_url
        @secondary_label_key = "ao3_fanfic.supporter_page.cta.browse_public"
      elsif @signed_in
        if @payment_methods_configured
          @state_title_key = "ao3_fanfic.supporter_page.state.ready_title"
          @state_body_key = "ao3_fanfic.supporter_page.state.ready_body"
          @primary_url = @payment_methods_url
          @primary_label_key = "ao3_fanfic.supporter_page.cta.choose_payment"
        else
          @state_title_key = "ao3_fanfic.supporter_page.state.configure_title"
          @state_body_key = "ao3_fanfic.supporter_page.state.configure_body"
          @primary_url = current_user&.staff? ? @payment_settings_url : @home_url
          @primary_label_key =
            current_user&.staff? ? "ao3_fanfic.supporter_page.cta.configure_payments" :
                                   "ao3_fanfic.supporter_page.cta.browse_public"
        end
        @secondary_url = @home_url
        @secondary_label_key = "ao3_fanfic.supporter_page.cta.browse_public"
      elsif @signup_available
        @state_title_key = "ao3_fanfic.supporter_page.state.account_title"
        @state_body_key = "ao3_fanfic.supporter_page.state.account_body"
        @primary_url = @signup_url
        @primary_label_key = "ao3_fanfic.supporter_page.cta.create_account"
        @secondary_url = @login_url
        @secondary_label_key = "ao3_fanfic.supporter_page.cta.log_in"
      else
        @state_title_key = "ao3_fanfic.supporter_page.state.invite_only_title"
        @state_body_key = "ao3_fanfic.supporter_page.state.invite_only_body"
        @primary_url = @login_url
        @primary_label_key = "ao3_fanfic.supporter_page.cta.log_in"
        @secondary_url = @home_url
        @secondary_label_key = "ao3_fanfic.supporter_page.cta.browse_public"
      end
    end
  end
end
