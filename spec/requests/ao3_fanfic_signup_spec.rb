# frozen_string_literal: true

RSpec.describe Ao3FanficForum::SignupController do
  fab!(:user)

  before { SiteSetting.ao3_fanfic_enabled = true }

  describe "#show" do
    it "redirects signed-out readers to account registration" do
      get "/ao3-fanfic/signup"

      expect(response).to redirect_to("/signup")
    end

    it "redirects signed-in readers to their account page" do
      sign_in(user)

      get "/ao3-fanfic/signup"

      expect(response).to redirect_to("/ao3-fanfic/account")
    end
  end
end
