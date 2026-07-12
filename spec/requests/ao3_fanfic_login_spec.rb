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

  it "logs readers in through the AO3Chat login action" do
    post "/ao3-fanfic/login.json", params: { login: user.username, password: "myawesomepassword" }

    expect(response.status).to eq(200)
    expect(response.parsed_body["error"]).not_to be_present
  end

  describe "#show" do
    it "renders AO3Chat login for signed-out readers", :aggregate_failures do
      SiteSetting.invite_only = true

      get "/ao3-fanfic/login"

      expect(response.status).to eq(200)
      expect(response.body).to include(I18n.t("ao3_fanfic.auth_page.login.title"))
      expect(response.body).to include('data-ao3-auth-form="login"')
      expect(response.body).to include('action="/ao3-fanfic/login"')
      expect(response.body).to include('data-success-url="/"')
      expect(response.body).to include('name="authenticity_token"')
      expect(response.body).to include("/ao3-fanfic/advanced-login")
      expect(response.body).not_to include('href="/ao3-fanfic/signup" data-auto-route="true"')
      expect(response.body).to include('href="/ao3-fanfic/password-reset" data-auto-route="true"')
    end

    it "redirects signed-in readers to their account page" do
      sign_in(user)

      get "/ao3-fanfic/login"

      expect(response).to redirect_to("/ao3-fanfic/account")
    end
  end
end
