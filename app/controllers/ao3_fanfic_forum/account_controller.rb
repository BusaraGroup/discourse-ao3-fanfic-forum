# frozen_string_literal: true

module Ao3FanficForum
  class AccountController < BaseController
    requires_plugin PLUGIN_NAME

    def show
      @signed_in = current_user.present?
      @username = current_user&.username
      @home_url = discourse_path("/")
      @login_url = discourse_path("/ao3-fanfic/login")
      @signup_url = discourse_path("/ao3-fanfic/signup")
      @supporter_url = discourse_path(SupporterAccess.subscribe_url)
      @logout_url = discourse_path("/ao3-fanfic/logout") if @signed_in
      @signup_available = AuthConfiguration.signup_available?

      assign_cta
    end

    private

    def assign_cta
      if @signed_in
        @state_title_key = "ao3_fanfic.account_page.state.signed_in_title"
        @state_body_key = "ao3_fanfic.account_page.state.signed_in_body"
        @primary_url = @home_url
        @primary_label_key = "ao3_fanfic.account_page.cta.open"
        @secondary_url = @supporter_url
        @secondary_label_key = "ao3_fanfic.account_page.cta.supporter"
      elsif @signup_available
        @state_title_key = "ao3_fanfic.account_page.state.signed_out_title"
        @state_body_key = "ao3_fanfic.account_page.state.signed_out_body"
        @primary_url = @signup_url
        @primary_label_key = "ao3_fanfic.account_page.cta.create"
        @secondary_url = @login_url
        @secondary_label_key = "ao3_fanfic.account_page.cta.log_in"
      else
        @state_title_key = "ao3_fanfic.account_page.state.invite_only_title"
        @state_body_key = "ao3_fanfic.account_page.state.invite_only_body"
        @primary_url = @login_url
        @primary_label_key = "ao3_fanfic.account_page.cta.log_in"
        @secondary_url = nil
        @secondary_label_key = nil
      end
    end
  end
end
