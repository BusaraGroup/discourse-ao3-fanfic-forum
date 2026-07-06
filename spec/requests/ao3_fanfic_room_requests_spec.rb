# frozen_string_literal: true

RSpec.describe "AO3 fanfic room requests" do
  fab!(:user)
  fab!(:supporter_group) { Fabricate(:group, name: "ao3chat_supporters") }
  fab!(:private_category) do
    Fabricate(
      :private_category,
      group: supporter_group,
      name: "Private Fandom Rooms",
      slug: "private-fandom-rooms",
    )
  end

  before do
    SiteSetting.ao3_fanfic_enabled = true
    SiteSetting.ao3_fanfic_supporter_group_name = supporter_group.name
    SiteSetting.ao3_fanfic_private_rooms_category_slug = private_category.slug
    SiteSetting.ao3_fanfic_subscribe_url = "/s/ao3chat"
    sign_in(user)
  end

  def room_request_params(overrides = {})
    {
      fandom: "Leverage",
      ship: "Parker/Hardison",
      purpose: "A smaller room for watch-party recs and longer fic discussion.",
      spoiler_policy: "Spoilers allowed after each readalong checkpoint.",
      comfort_notes: "Keep episode spoilers labeled in topic titles.",
    }.merge(overrides)
  end

  it "requires supporter access before creating a private room request" do
    expect {
      post "/ao3-fanfic/room-requests.json",
           params: {
             room_request: room_request_params,
           }
    }.not_to change(Topic, :count)

    expect(response.status).to eq(403)
    expect(response.parsed_body["errors"]).to include(
      I18n.t("ao3_fanfic.room_requests.errors.supporter_required"),
    )
    expect(response.parsed_body["subscribe_url"]).to eq("/s/ao3chat")
  end

  it "creates a private category topic for supporters" do
    GroupUser.create!(group: supporter_group, user: user)

    expect {
      post "/ao3-fanfic/room-requests.json",
           params: {
             room_request: room_request_params,
           }
    }.to change(Topic, :count).by(1)

    expect(response.status).to eq(201)

    topic = Topic.last
    expect(topic.category).to eq(private_category)
    expect(topic.title).to eq("Private room request: Leverage - Parker/Hardison")
    expect(topic.first_post.raw).to include("**Fandom:** Leverage")
    expect(topic.first_post.raw).to include("**Ship or focus:** Parker/Hardison")
    expect(response.parsed_body["topic_url"]).to eq(topic.relative_url)
  end

  it "requires a fandom for the request" do
    GroupUser.create!(group: supporter_group, user: user)

    expect {
      post "/ao3-fanfic/room-requests.json",
           params: {
             room_request: room_request_params(fandom: " "),
           }
    }.not_to change(Topic, :count)

    expect(response.status).to eq(400)
    expect(response.parsed_body["errors"]).to include(
      I18n.t("ao3_fanfic.room_requests.errors.fandom_required"),
    )
  end
end
