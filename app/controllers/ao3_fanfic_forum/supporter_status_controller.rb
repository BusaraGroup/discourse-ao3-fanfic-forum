# frozen_string_literal: true

module Ao3FanficForum
  class SupporterStatusController < ::ApplicationController
    requires_plugin PLUGIN_NAME
    requires_login

    def show
      render json: SupporterAccess.status_for(current_user)
    end
  end
end
