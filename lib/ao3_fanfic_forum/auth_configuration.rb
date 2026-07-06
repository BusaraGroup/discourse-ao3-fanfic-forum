# frozen_string_literal: true

module Ao3FanficForum
  module AuthConfiguration
    SOCIAL_LOGIN_SETTINGS = %i[
      enable_discourse_id
      enable_google_oauth2_logins
      enable_twitter_logins
      enable_facebook_logins
      enable_github_logins
      enable_discord_logins
      enable_linkedin_oidc_logins
      microsoft_auth_enabled
      openid_connect_enabled
      oauth2_enabled
      patreon_login_enabled
      sign_in_with_apple_enabled
    ].freeze

    module_function

    def apply!
      set_site_setting(:login_required, false)
      set_site_setting(:invite_only, false)
      set_site_setting(:auth_immediately, false)
      set_site_setting(:enable_discourse_connect, false)
      set_site_setting(:enable_local_logins, true)
      set_site_setting(:enable_local_logins_via_email, true)
      set_site_setting(:allow_new_registrations, true)
      set_site_setting(:enable_signup_cta, true)
      set_site_setting(:hide_email_address_taken, true)

      SOCIAL_LOGIN_SETTINGS.each { |setting| set_site_setting(setting, false) }
      set_site_setting(:discourse_id_client_id, "")
      set_site_setting(:discourse_id_client_secret, "")
    end

    def signup_available?
      !SiteSetting.invite_only && SiteSetting.allow_new_registrations &&
        !SiteSetting.enable_discourse_connect
    end

    def set_site_setting(name, value)
      SiteSetting.public_send(:"#{name}=", value) if SiteSetting.respond_to?(:"#{name}=")
    end
  end
end
