# frozen_string_literal: true

RSpec.describe Ao3FanficForum::PasswordResetController do
  fab!(:user)

  before { SiteSetting.ao3_fanfic_enabled = true }

  it "redirects the stock password reset route to AO3Chat password recovery" do
    get "/password-reset"

    expect(response).to redirect_to("/ao3-fanfic/password-reset")
  end

  describe "#show" do
    it "renders AO3Chat password recovery for signed-out readers", :aggregate_failures do
      get "/ao3-fanfic/password-reset"

      expect(response.status).to eq(200)
      expect(response.body).to include(I18n.t("ao3_fanfic.auth_page.password_reset.title"))
      expect(response.body).to include('data-ao3-auth-form="password-reset"')
      expect(response.body).to include('action="/session/forgot_password"')
      expect(response.body).to include('href="/ao3-fanfic/login" data-auto-route="true"')
      expect(response.body).to include('href="/ao3-fanfic/signup" data-auto-route="true"')
    end

    it "redirects signed-in readers to their account page" do
      sign_in(user)

      get "/ao3-fanfic/password-reset"

      expect(response).to redirect_to("/ao3-fanfic/account")
    end
  end
end
