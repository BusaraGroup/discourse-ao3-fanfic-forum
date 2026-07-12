# frozen_string_literal: true

RSpec.describe Ao3FanficForum::SignupController do
  fab!(:user)

  before { SiteSetting.ao3_fanfic_enabled = true }

  def honeypot_magic(params)
    get "/session/hp.json"
    json = response.parsed_body
    params[:password_confirmation] = json["value"]
    params[:challenge] = json["challenge"].reverse
    params
  end

  it "redirects the stock signup route to AO3Chat signup" do
    get "/signup"

    expect(response).to redirect_to("/ao3-fanfic/signup")
  end

  it "creates readers through the AO3Chat signup action" do
    SiteSetting.allow_new_registrations = true

    post "/ao3-fanfic/signup.json",
         params:
           honeypot_magic(
             email: "reader@example.com",
             username: "ao3reader",
             name: "AO3 Reader",
             password: "strongpassword",
           )

    expect(response.status).to eq(200)
    expect(response.parsed_body["success"]).to eq(true)
    expect(User.find_by_email("reader@example.com")).to be_present
  end

  describe "#show" do
    it "renders AO3Chat signup for signed-out readers", :aggregate_failures do
      get "/ao3-fanfic/signup"

      expect(response.status).to eq(200)
      expect(response.body).to include(I18n.t("ao3_fanfic.auth_page.signup.title"))
      expect(response.body).to include('data-ao3-auth-form="signup"')
      expect(response.body).to include('data-success-url="/"')
      expect(response.body).to include('action="/ao3-fanfic/signup"')
      expect(response.body).to include('data-session-url="/ao3-fanfic/login"')
      expect(response.body).to include('href="/ao3-fanfic/login" data-auto-route="true"')
    end

    it "redirects signed-in readers to their account page" do
      sign_in(user)

      get "/ao3-fanfic/signup"

      expect(response).to redirect_to("/ao3-fanfic/account")
    end
  end
end
