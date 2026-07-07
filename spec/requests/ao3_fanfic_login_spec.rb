# frozen_string_literal: true

RSpec.describe Ao3FanficForum::LoginController do
  before { SiteSetting.ao3_fanfic_enabled = true }

  describe "#show" do
    it "redirects to account login" do
      get "/ao3-fanfic/login"

      expect(response).to redirect_to("/login")
    end
  end
end
