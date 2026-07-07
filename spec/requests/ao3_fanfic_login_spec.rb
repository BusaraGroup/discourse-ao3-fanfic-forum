# frozen_string_literal: true

RSpec.describe Ao3FanficForum::LoginController do
  fab!(:user)

  before { SiteSetting.ao3_fanfic_enabled = true }

  it "redirects the stock login route to AO3Chat login" do
    get "/login"

    expect(response).to redirect_to("/ao3-fanfic/login")
  end

  it "keeps advanced sign-in available for security key accounts" do
    get "/ao3-fanfic/advanced-login"

    expect(response.status).to eq(200)
  end

  describe "#show" do
    it "renders AO3Chat login for signed-out readers", :aggregate_failures do
      get "/ao3-fanfic/login"

      expect(response.status).to eq(200)
      expect(response.body).to include(I18n.t("ao3_fanfic.auth_page.login.title"))
      expect(response.body).to include('data-ao3-auth-form="login"')
      expect(response.body).to include('action="/session"')
      expect(response.body).to include('data-static-login-url="/login"')
      expect(response.body).to include("/ao3-fanfic/advanced-login")
      expect(response.body).to include('href="/ao3-fanfic/signup" data-auto-route="true"')
    end

    it "redirects signed-in readers to their account page" do
      sign_in(user)

      get "/ao3-fanfic/login"

      expect(response).to redirect_to("/ao3-fanfic/account")
    end
  end
end
