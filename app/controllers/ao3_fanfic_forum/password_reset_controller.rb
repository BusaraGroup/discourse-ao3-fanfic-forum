# frozen_string_literal: true

module Ao3FanficForum
  class PasswordResetController < BaseController
    requires_plugin PLUGIN_NAME
    skip_before_action :redirect_to_login_if_required

    def show
      return redirect_to discourse_path("/ao3-fanfic/account") if current_user

      @home_url = discourse_path("/")
      @login_url = discourse_path("/ao3-fanfic/login")
      @signup_url = discourse_path("/ao3-fanfic/signup")
      @forgot_password_url = discourse_path("/session/forgot_password")
    end
  end
end
