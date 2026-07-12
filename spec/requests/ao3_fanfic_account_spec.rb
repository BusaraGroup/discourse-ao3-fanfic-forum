# frozen_string_literal: true

RSpec.describe Ao3FanficForum::AccountController do
  fab!(:user)

  before { SiteSetting.ao3_fanfic_enabled = true }

  describe "#show" do
    it "renders invite-only account access for signed-out readers" do
      SiteSetting.invite_only = true

      get "/ao3-fanfic/account"

      expect(response.status).to eq(200)
      expect(response.body).to include(I18n.t("ao3_fanfic.account_page.title"))
      expect(response.body).to include(I18n.t("ao3_fanfic.account_page.state.invite_only_title"))
      expect(response.body).not_to include('href="/ao3-fanfic/signup"')
      expect(response.body).to include('href="/ao3-fanfic/login"')
      expect(response.body).to include('data-auto-route="true"')
    end

    it "renders account status for signed-in readers" do
      sign_in(user)

      get "/ao3-fanfic/account"

      expect(response.status).to eq(200)
      expect(response.body).to include(user.username)
      expect(response.body).to include(I18n.t("ao3_fanfic.account_page.cta.open"))
      expect(response.body).to include('href="/ao3-fanfic/supporter"')
      expect(response.body).to include('action="/ao3-fanfic/logout"')
      expect(response.body).to include(I18n.t("ao3_fanfic.account_page.cta.log_out"))
      expect(response.body).to include('data-auto-route="true"')
    end
  end

  describe "POST #logout" do
    it "logs readers out through an AO3Chat route" do
      sign_in(user)

      post "/ao3-fanfic/logout"

      expect(response).to redirect_to("/ao3-fanfic/login")
    end
  end
end
