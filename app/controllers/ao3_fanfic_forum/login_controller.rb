# frozen_string_literal: true

module Ao3FanficForum
  class LoginController < BaseController
    requires_plugin PLUGIN_NAME
    skip_before_action :redirect_to_login_if_required

    def show
      redirect_to discourse_path("/login")
    end
  end
end
