# frozen_string_literal: true

RSpec.describe Ao3FanficForum::SignupController do
  before { SiteSetting.ao3_fanfic_enabled = true }

  describe "#show" do
    it "redirects to account registration" do
      get "/ao3-fanfic/signup"

      expect(response).to redirect_to("/signup")
    end
  end
end
