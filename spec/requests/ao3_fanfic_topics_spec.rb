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
      "ao3_visibility" => "public",
      "ao3_post_anonymously" => "true",
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

    expect(response.status).to eq(200)

    topic = Topic.last
    metadata = Ao3FanficForum::TopicMetadata.find_by(topic_id: topic.id)

    expect(metadata.discussion_type).to eq("fic_recommendation")
    expect(metadata.fic_title).to eq("A Good Fic")
    expect(metadata.post_anonymously).to eq(true)
    expect(
      Ao3FanficForum::TopicTerm.exists?(
        topic_id: topic.id,
        term_type: "fandom",
        normalized: "the-untamed",
      ),
    ).to eq(true)
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
end
