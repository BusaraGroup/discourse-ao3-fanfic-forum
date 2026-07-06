# frozen_string_literal: true

RSpec.describe Ao3FanficForum::AccountController do
  fab!(:user)

  before { SiteSetting.ao3_fanfic_enabled = true }

  describe "#show" do
    it "renders account actions for signed-out readers" do
      get "/ao3-fanfic/account"

      expect(response.status).to eq(200)
      expect(response.body).to include(I18n.t("ao3_fanfic.account_page.title"))
      expect(response.body).to include(I18n.t("ao3_fanfic.account_page.cta.create"))
      expect(response.body).to include("/signup")
    end

    it "renders account status for signed-in readers" do
      sign_in(user)

      get "/ao3-fanfic/account"

      expect(response.status).to eq(200)
      expect(response.body).to include(user.username)
      expect(response.body).to include(I18n.t("ao3_fanfic.account_page.cta.open"))
      expect(response.body).to include("/ao3-fanfic/supporter")
    end
  end
end
