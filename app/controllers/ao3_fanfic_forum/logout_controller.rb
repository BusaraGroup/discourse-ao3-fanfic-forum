# frozen_string_literal: true

module Ao3FanficForum
  class LogoutController < BaseController
    requires_plugin PLUGIN_NAME

    def create
      redirect_url = discourse_path("/ao3-fanfic/login")
      data = {
        redirect_url: redirect_url,
        user: current_user,
        client_ip: request&.ip,
        user_agent: request&.user_agent,
      }

      DiscourseEvent.trigger(:before_session_destroy, data)

      reset_session
      log_off_user

      redirect_to data[:redirect_url], allow_other_host: false
    end
  end
end
