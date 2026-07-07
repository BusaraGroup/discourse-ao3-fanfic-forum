# frozen_string_literal: true

module Ao3FanficForum
  class SignupController < BaseController
    requires_plugin PLUGIN_NAME
    skip_before_action :redirect_to_login_if_required

    def show
      redirect_to discourse_path(current_user ? "/ao3-fanfic/account" : "/signup")
    end
  end
end
