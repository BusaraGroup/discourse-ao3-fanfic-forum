# frozen_string_literal: true

module Ao3FanficForum
  class LoginController < BaseController
    requires_plugin PLUGIN_NAME
    skip_before_action :redirect_to_login_if_required

    def show
      return redirect_to discourse_path("/ao3-fanfic/account") if current_user

      @home_url = discourse_path("/")
      @account_url = discourse_path("/ao3-fanfic/account")
      @signup_url = discourse_path("/ao3-fanfic/signup")
      @supporter_url = discourse_path(SupporterAccess.subscribe_url)
      @password_reset_url = discourse_path("/ao3-fanfic/password-reset")
      @advanced_login_url = discourse_path("/ao3-fanfic/advanced-login")
      @static_login_url = discourse_path("/login")
      @session_url = discourse_path("/session")
    end
  end
end
