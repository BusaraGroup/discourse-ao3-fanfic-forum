# frozen_string_literal: true

module Ao3FanficForum
  class SupporterStatusController < ::ApplicationController
    requires_plugin PLUGIN_NAME
    before_action :ensure_logged_in
    skip_before_action :redirect_to_login_if_required

    def show
      render json: SupporterAccess.status_for(current_user)
    end
  end
end
