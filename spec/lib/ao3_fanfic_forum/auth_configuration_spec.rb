# frozen_string_literal: true

RSpec.describe Ao3FanficForum::AuthConfiguration do
  describe ".apply!" do
    it "opens local account registration", :aggregate_failures do
      SiteSetting.invite_only = true
      SiteSetting.allow_new_registrations = false
      SiteSetting.login_required = true

      described_class.apply!

      expect(SiteSetting.invite_only).to eq(false)
      expect(SiteSetting.allow_new_registrations).to eq(true)
      expect(SiteSetting.login_required).to eq(false)
    end
  end
end
