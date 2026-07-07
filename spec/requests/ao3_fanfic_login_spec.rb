# frozen_string_literal: true

RSpec.describe Ao3FanficForum::LoginController do
  fab!(:user)

  before { SiteSetting.ao3_fanfic_enabled = true }

  describe "#show" do
    it "renders AO3Chat login for signed-out readers", :aggregate_failures do
      get "/ao3-fanfic/login"

      expect(response.status).to eq(200)
      expect(response.body).to include(I18n.t("ao3_fanfic.auth_page.login.title"))
      expect(response.body).to include('data-ao3-auth-form="login"')
      expect(response.body).to include('action="/session"')
      expect(response.body).to include("/ao3-fanfic/signup")
    end

    it "redirects signed-in readers to their account page" do
      sign_in(user)

      get "/ao3-fanfic/login"

      expect(response).to redirect_to("/ao3-fanfic/account")
    end
  end
end
