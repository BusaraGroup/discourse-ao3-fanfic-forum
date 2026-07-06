# frozen_string_literal: true

RSpec.describe Ao3FanficForum::CryptoPaymentsController do
  fab!(:user)

  before do
    SiteSetting.ao3_fanfic_enabled = true
    SiteSetting.ao3_fanfic_crypto_btc_address = "bc1qao3chatbtc"
    sign_in(user)
  end

  describe "#create" do
    it "creates a staff verification message", :aggregate_failures do
      expect {
        post "/ao3-fanfic/crypto-payments",
             params: {
               crypto_payment: {
                 currency: "btc",
                 transaction_id: "bitcoin-tx-123",
                 amount_note: "$5 monthly supporter",
               },
             }
      }.to change { Topic.private_messages.count }.by(1)

      post = Topic.private_messages.last.first_post

      expect(response.status).to eq(302)
      expect(response.location).to include("/ao3-fanfic/supporter#payment-methods")
      expect(post.raw).to include(user.username, "bitcoin-tx-123", "bc1qao3chatbtc")
    end

    it "rejects an unconfigured crypto method", :aggregate_failures do
      expect {
        post "/ao3-fanfic/crypto-payments",
             params: {
               crypto_payment: {
                 currency: "xmr",
                 transaction_id: "monero-tx-123",
               },
             }
      }.not_to change { Topic.private_messages.count }

      expect(response.status).to eq(302)
      expect(response.location).to include("/ao3-fanfic/supporter#payment-methods")
    end
  end
end
