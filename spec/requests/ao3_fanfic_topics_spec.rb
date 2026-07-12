# frozen_string_literal: true

RSpec.describe "AO3 fanfic topics" do
  fab!(:user)
  fab!(:category)

  before do
    SiteSetting.ao3_fanfic_enabled = true
    sign_in(user)
  end

  def ao3_fields(overrides = {})
    {
      "ao3_discussion_type" => "fic_recommendation",
      "ao3_fandom_tags" => ["The Untamed"].to_json,
      "ao3_ship_tags" => ["Lan Wangji/Wei Wuxian"].to_json,
      "ao3_content_warnings" => ["Creator Chose Not To Use Archive Warnings"].to_json,
      "ao3_spoiler_label" => "post-canon",
      "ao3_fic_url" => "https://archiveofourown.org/works/1",
      "ao3_fic_title" => "A Good Fic",
      "ao3_fic_author" => "ao3writer",
      "ao3_chapter_ref" => "Chapter 3",
    }.merge(overrides)
  end

  it "creates a topic with indexed AO3 metadata" do
    post "/posts.json",
         params: {
           raw: "A detailed recommendation with quoted passages and discussion prompts.",
           title: "A recommendation for a post-canon fic",
           category: category.id,
           topic_custom_fields: ao3_fields,
         }

    expect(response.status).to eq(200), response.body

    topic = Topic.last
    metadata = Ao3FanficForum::TopicMetadata.find_by(topic_id: topic.id)

    expect(metadata.discussion_type).to eq("fic_recommendation")
    expect(metadata.fic_title).to eq("A Good Fic")
    expect(
      Ao3FanficForum::TopicTerm.exists?(
        topic_id: topic.id,
        term_type: "fandom",
        normalized: "the-untamed",
      ),
    ).to eq(true)
  end

  it "lists discussions without AO3 metadata", :aggregate_failures do
    topic = Fabricate(:topic, category: category, title: "Reader lounge check-in")

    get "/ao3-fanfic/topics.json"

    topic_ids = response.parsed_body["topics"].pluck("id")
    expect(topic_ids).to include(topic.id)
    expect(topic_ids).not_to include(category.topic_id)
  end

  it "requires login for reader topic and term APIs", :aggregate_failures do
    sign_out

    get "/ao3-fanfic/topics.json"
    expect(response.status).to eq(403)

    get "/ao3-fanfic/terms.json"
    expect(response.status).to eq(403)
  end

  it "ignores default-only and privacy-only custom fields" do
    expect {
      post "/posts.json",
           params: {
             raw: "A normal site topic that does not need fanfic metadata.",
             title: "A normal reader lounge topic",
             category: category.id,
             topic_custom_fields: {
               "ao3_discussion_type" => "general",
               "ao3_visibility" => "space",
               "ao3_space_group_id" => "42",
               "ao3_post_anonymously" => "true",
             },
           }
    }.to change(Topic, :count).by(1)

    expect(response.status).to eq(200)
    expect(Ao3FanficForum::TopicMetadata.exists?(topic_id: Topic.last.id)).to eq(false)
  end

  it "omits privacy intent metadata from public topic payloads" do
    topic = Fabricate(:topic, category: category, title: "Private intent metadata")
    topic.custom_fields =
      ao3_fields(
        "ao3_visibility" => "members",
        "ao3_space_group_id" => "42",
        "ao3_post_anonymously" => "true",
      )
    topic.save!
    Ao3FanficForum::Metadata.sync_from_topic!(topic)

    get "/ao3-fanfic/topics.json", params: { fandom: "The Untamed" }

    expect(response.status).to eq(200)

    metadata =
      response.parsed_body["topics"].find { |result| result["id"] == topic.id }["ao3_fanfic"]

    expect(metadata).to include(
      "present" => true,
      "discussion_type" => "fic_recommendation",
      "fandom_tags" => ["The Untamed"],
    )
    expect(metadata.keys).not_to include("post_anonymously", "visibility", "space_group_id")
  end

  it "does not persist legacy privacy intent fields as AO3 metadata" do
    post "/posts.json",
         params: {
           raw: "A detailed recommendation with stale privacy fields from an old draft.",
           title: "A recommendation with stale privacy fields",
           category: category.id,
           topic_custom_fields:
             ao3_fields(
               "ao3_visibility" => "space",
               "ao3_space_group_id" => "42",
               "ao3_post_anonymously" => "true",
             ),
         }

    expect(response.status).to eq(200)

    metadata = Ao3FanficForum::TopicMetadata.find_by(topic_id: Topic.last.id)
    expect(metadata.visibility).to eq("public")
    expect(metadata.space_group_id).to eq(nil)
    expect(metadata.post_anonymously).to eq(false)
  end

  it "removes stale privacy intent custom fields" do
    topic = Fabricate(:topic, category: category, title: "Legacy privacy custom fields")
    topic.custom_fields =
      ao3_fields(
        "ao3_visibility" => "space",
        "ao3_space_group_id" => "42",
        "ao3_post_anonymously" => "true",
      )
    topic.save!

    Ao3FanficForum::Metadata.sync_from_topic!(topic)

    expect(topic.reload.custom_fields.keys).not_to include(
      "ao3_visibility",
      "ao3_space_group_id",
      "ao3_post_anonymously",
    )
  end

  it "removes indexed metadata when a topic is destroyed" do
    topic = Fabricate(:topic, category: category, title: "Doomed fanfic recommendation")
    topic.custom_fields = ao3_fields
    topic.save!
    Ao3FanficForum::Metadata.sync_from_topic!(topic)

    expect(Ao3FanficForum::TopicMetadata.exists?(topic_id: topic.id)).to eq(true)
    expect(Ao3FanficForum::TopicTerm.exists?(topic_id: topic.id)).to eq(true)

    DiscourseEvent.trigger(:topic_destroyed, topic, user)

    expect(Ao3FanficForum::TopicMetadata.exists?(topic_id: topic.id)).to eq(false)
    expect(Ao3FanficForum::TopicTerm.exists?(topic_id: topic.id)).to eq(false)
  end

  it "rejects a malformed metadata payload with a 400" do
    topic = Fabricate(:topic, category: category, user: user, title: "Malformed payload")

    put "/ao3-fanfic/topics/#{topic.id}/metadata.json", params: { topic_custom_fields: "junk" }

    expect(response.status).to eq(400)
  end

  it "drops unsafe fic URL schemes and prefixes scheme-less URLs" do
    unsafe = Fabricate(:topic, category: category, title: "Unsafe fanfic URL example")
    unsafe.custom_fields = ao3_fields("ao3_fic_url" => "javascript:alert(1)")
    unsafe.save!
    Ao3FanficForum::Metadata.sync_from_topic!(unsafe)

    expect(Ao3FanficForum::TopicMetadata.find_by(topic_id: unsafe.id).fic_url).to eq(nil)
    expect(Ao3FanficForum::Metadata.for_topic(unsafe.reload)[:fic_url]).to eq(nil)

    schemeless = Fabricate(:topic, category: category, title: "Scheme-less fic url")
    schemeless.custom_fields = ao3_fields("ao3_fic_url" => "archiveofourown.org/works/1")
    schemeless.save!
    Ao3FanficForum::Metadata.sync_from_topic!(schemeless)

    expect(Ao3FanficForum::TopicMetadata.find_by(topic_id: schemeless.id).fic_url).to eq(
      "https://archiveofourown.org/works/1",
    )
  end

  it "clears metadata when the edit payload has no AO3 fields" do
    topic = Fabricate(:topic, category: category, user: user, title: "Metadata to clear")
    topic.custom_fields = ao3_fields
    topic.save!
    Ao3FanficForum::Metadata.sync_from_topic!(topic)

    expect(Ao3FanficForum::TopicMetadata.exists?(topic_id: topic.id)).to eq(true)

    put "/ao3-fanfic/topics/#{topic.id}/metadata.json",
        params: { topic_custom_fields: {} }.to_json,
        headers: {
          "CONTENT_TYPE" => "application/json",
        }

    expect(response.status).to eq(200)
    expect(response.parsed_body["ao3_fanfic"]).to eq(nil)
    expect(Ao3FanficForum::TopicMetadata.exists?(topic_id: topic.id)).to eq(false)
  end

  it "filters visible topics by fandom, ship, warning, and discussion type" do
    matching = Fabricate(:topic, category: category, title: "Matching fic rec")
    matching.custom_fields = ao3_fields
    matching.save!
    Ao3FanficForum::Metadata.sync_from_topic!(matching)

    other = Fabricate(:topic, category: category, title: "Other fandom fic rec")
    other.custom_fields = ao3_fields("ao3_fandom_tags" => ["Leverage"].to_json)
    other.save!
    Ao3FanficForum::Metadata.sync_from_topic!(other)

    get "/ao3-fanfic/topics.json",
        params: {
          discussion_type: "fic_recommendation",
          fandom: "The Untamed",
          ship: "Lan Wangji/Wei Wuxian",
          warning: "Creator Chose Not To Use Archive Warnings",
        }

    expect(response.status).to eq(200)

    topic_ids = response.parsed_body["topics"].map { |topic| topic["id"] }
    expect(topic_ids).to include(matching.id)
    expect(topic_ids).not_to include(other.id)
  end

  it "rejects oversized filter lists before building the query" do
    get "/ao3-fanfic/topics.json", params: { fandom: Array.new(9) { |index| "Fandom #{index}" } }

    expect(response.status).to eq(400)
    expect(response.parsed_body["errors"].join(" ")).to include(
      I18n.t("ao3_fanfic.errors.too_many_filter_values", count: 8),
    )
  end

  it "returns visible fandom, ship, and warning terms" do
    topic = Fabricate(:topic, category: category, title: "Indexed fic rec")
    topic.custom_fields = ao3_fields
    topic.save!
    Ao3FanficForum::Metadata.sync_from_topic!(topic)

    private_category = Fabricate(:private_category, group: Fabricate(:group))
    private_topic = Fabricate(:topic, category: private_category, title: "Private fic rec")
    private_topic.custom_fields = ao3_fields("ao3_fandom_tags" => ["Leverage"].to_json)
    private_topic.save!
    Ao3FanficForum::Metadata.sync_from_topic!(private_topic)

    get "/ao3-fanfic/terms.json", params: { limit: 5 }

    expect(response.status).to eq(200)
    expect(response.parsed_body.dig("terms", "fandom").first).to include(
      "value" => "The Untamed",
      "normalized" => "the-untamed",
      "topic_count" => 1,
    )
    expect(response.parsed_body.dig("terms", "ship").first).to include(
      "value" => "Lan Wangji/Wei Wuxian",
      "normalized" => "lan-wangji-wei-wuxian",
      "topic_count" => 1,
    )
    expect(response.parsed_body.dig("terms", "warning").first).to include(
      "value" => "Creator Chose Not To Use Archive Warnings",
      "normalized" => "creator-chose-not-to-use-archive-warnings",
      "topic_count" => 1,
    )
    fandom_values = response.parsed_body.dig("terms", "fandom").map { |term| term["value"] }
    expect(fandom_values).not_to include("Leverage")
  end
end
