# frozen_string_literal: true

RSpec.describe Ao3FanficForum::SupporterController do
  fab!(:user)

  before do
    SiteSetting.ao3_fanfic_enabled = true
    SiteSetting.ao3_fanfic_supporter_checkout_url = "https://checkout.example/ao3chat"
    SiteSetting.ao3_fanfic_crypto_btc_address = "bc1qao3chatbtc"
  end

  describe "#show" do
    it "renders configured payment methods for signed-in readers", :aggregate_failures do
      sign_in(user)

      get "/ao3-fanfic/supporter"

      expect(response.status).to eq(200)
      expect(response.body).to include(I18n.t("ao3_fanfic.supporter_page.payments.title"))
      expect(response.body).to include("https://checkout.example/ao3chat")
      expect(response.body).to include("bc1qao3chatbtc")
      expect(response.body).to include("crypto_payment[transaction_id]")
    end

    it "keeps signed-out readers on account creation first", :aggregate_failures do
      get "/ao3-fanfic/supporter"

      expect(response.status).to eq(200)
      expect(response.body).to include("/ao3-fanfic/signup")
      expect(response.body).to include("/ao3-fanfic/login")
      expect(response.body).to include(I18n.t("ao3_fanfic.supporter_page.payments.crypto_login_note"))
    end

    it "links staff to payment settings when payments are missing", :aggregate_failures do
      SiteSetting.ao3_fanfic_supporter_checkout_url = ""
      SiteSetting.ao3_fanfic_crypto_btc_address = ""
      sign_in(Fabricate(:admin))

      get "/ao3-fanfic/supporter"

      expect(response.status).to eq(200)
      expect(response.body).to include(I18n.t("ao3_fanfic.supporter_page.state.configure_title"))
      expect(response.body).to include("/admin/site_settings/category/plugins?filter=ao3_fanfic")
      expect(response.body).to include(I18n.t("ao3_fanfic.supporter_page.cta.configure_payments"))
    end
  end
end
