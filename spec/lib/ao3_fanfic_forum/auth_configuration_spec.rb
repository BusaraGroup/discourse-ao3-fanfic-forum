# frozen_string_literal: true

RSpec.describe Ao3FanficForum::AuthConfiguration do
  describe ".apply!" do
    it "enforces invite-only local accounts for the beta", :aggregate_failures do
      SiteSetting.ao3_fanfic_invite_only_beta = true
      SiteSetting.invite_only = false
      SiteSetting.allow_new_registrations = false
      SiteSetting.login_required = false
      SiteSetting.enable_signup_cta = true

      described_class.apply!

      expect(SiteSetting.invite_only).to eq(true)
      expect(SiteSetting.allow_new_registrations).to eq(true)
      expect(SiteSetting.login_required).to eq(true)
      expect(SiteSetting.enable_signup_cta).to eq(false)
      expect(SiteSetting.enable_local_logins).to eq(true)
    end

    it "can reopen public signup after the beta", :aggregate_failures do
      SiteSetting.ao3_fanfic_invite_only_beta = false

      described_class.apply!

      expect(SiteSetting.invite_only).to eq(false)
      expect(SiteSetting.allow_new_registrations).to eq(true)
      expect(SiteSetting.login_required).to eq(false)
      expect(SiteSetting.enable_signup_cta).to eq(true)
    end
  end
end
