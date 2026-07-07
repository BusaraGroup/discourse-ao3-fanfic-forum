# frozen_string_literal: true

module Ao3FanficForum
  class SignupController < BaseController
    requires_plugin PLUGIN_NAME
    skip_before_action :redirect_to_login_if_required

    def show
      return redirect_to discourse_path("/ao3-fanfic/account") if current_user

      @home_url = discourse_path("/")
      @account_url = discourse_path("/ao3-fanfic/account")
      @login_url = discourse_path("/ao3-fanfic/login")
      @supporter_url = discourse_path(SupporterAccess.subscribe_url)
      @static_login_url = discourse_path("/login")
      @session_url = discourse_path("/session")
      @users_url = discourse_path("/users")
    end
  end
end
