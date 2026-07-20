import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { eq } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";

const FIELDS = {
  discussionType: "ao3_discussion_type",
  fandomTags: "ao3_fandom_tags",
  shipTags: "ao3_ship_tags",
  contentWarnings: "ao3_content_warnings",
  spoilerLabel: "ao3_spoiler_label",
  spoilerUntil: "ao3_spoiler_until",
  ficUrl: "ao3_fic_url",
  ficTitle: "ao3_fic_title",
  ficAuthor: "ao3_fic_author",
  chapterRef: "ao3_chapter_ref",
};

function splitList(value) {
  return (value || "")
    .split(/[,\n|]/)
    .map((item) => item.trim().replace(/\s+/g, " "))
    .filter(Boolean)
    .filter((item, index, array) => {
      const key = item.toLowerCase();
      return (
        array.findIndex((candidate) => candidate.toLowerCase() === key) ===
        index
      );
    });
}

function parseStoredList(value) {
  if (Array.isArray(value)) {
    return value;
  }

  if (typeof value !== "string") {
    return [];
  }

  const trimmed = value.trim();

  if (trimmed.startsWith("[")) {
    try {
      const parsed = JSON.parse(trimmed);
      return Array.isArray(parsed) ? parsed : [];
    } catch {
      return splitList(value);
    }
  }

  return splitList(value);
}

function listText(value) {
  return parseStoredList(value).join(", ");
}

function dateValue(value) {
  if (!value) {
    return "";
  }

  return value.slice(0, 10);
}

function existingMetadata(model) {
  return (
    model.ao3FanficDraft?.topicCustomFields ||
    model.ao3FanficDraft ||
    model.ao3Fanfic ||
    model.topic?.ao3_fanfic ||
    model.topic?.ao3Fanfic ||
    {}
  );
}

function stateFromMetadata(metadata) {
  return {
    discussionType:
      metadata.discussion_type || metadata.ao3_discussion_type || "general",
    fandomTagsText: listText(metadata.fandom_tags || metadata.ao3_fandom_tags),
    shipTagsText: listText(metadata.ship_tags || metadata.ao3_ship_tags),
    contentWarningsText: listText(
      metadata.content_warnings || metadata.ao3_content_warnings
    ),
    spoilerLabel: metadata.spoiler_label || metadata.ao3_spoiler_label || "",
    spoilerUntil: dateValue(
      metadata.spoiler_until || metadata.ao3_spoiler_until
    ),
    ficUrl: metadata.fic_url || metadata.ao3_fic_url || "",
    ficTitle: metadata.fic_title || metadata.ao3_fic_title || "",
    ficAuthor: metadata.fic_author || metadata.ao3_fic_author || "",
    chapterRef: metadata.chapter_ref || metadata.ao3_chapter_ref || "",
  };
}

function hasMeaningfulMetadata(state) {
  return Boolean(
    state.discussionType !== "general" ||
    splitList(state.fandomTagsText).length > 0 ||
    splitList(state.shipTagsText).length > 0 ||
    splitList(state.contentWarningsText).length > 0 ||
    state.spoilerLabel.trim() ||
    state.spoilerUntil ||
    state.ficUrl.trim() ||
    state.ficTitle.trim() ||
    state.ficAuthor.trim() ||
    state.chapterRef.trim()
  );
}

function topicCustomFields(state) {
  if (!hasMeaningfulMetadata(state)) {
    return {};
  }

  return {
    [FIELDS.discussionType]: state.discussionType,
    [FIELDS.fandomTags]: JSON.stringify(splitList(state.fandomTagsText)),
    [FIELDS.shipTags]: JSON.stringify(splitList(state.shipTagsText)),
    [FIELDS.contentWarnings]: JSON.stringify(
      splitList(state.contentWarningsText)
    ),
    [FIELDS.spoilerLabel]: state.spoilerLabel,
    [FIELDS.spoilerUntil]: state.spoilerUntil,
    [FIELDS.ficUrl]: state.ficUrl,
    [FIELDS.ficTitle]: state.ficTitle,
    [FIELDS.ficAuthor]: state.ficAuthor,
    [FIELDS.chapterRef]: state.chapterRef,
  };
}

export default class Ao3FanficFields extends Component {
  static shouldRender(args, context) {
    return (
      context.siteSettings.ao3_fanfic_enabled &&
      args.model?.topicFirstPost &&
      !args.model?.creatingPrivateMessage
    );
  }

  @tracked state;

  constructor() {
    super(...arguments);
    this.state = stateFromMetadata(existingMetadata(this.model));
    this.syncModel();
  }

  get model() {
    return this.args.outletArgs.model;
  }

  syncModel() {
    this.model.set("ao3Fanfic", {
      ...this.state,
      topicCustomFields: topicCustomFields(this.state),
    });
  }

  updateState(changes) {
    this.state = { ...this.state, ...changes };
    this.syncModel();
  }

  @action
  updateDiscussionType(event) {
    this.updateState({ discussionType: event.target.value });
  }

  @action
  updateText(field, event) {
    this.updateState({ [field]: event.target.value });
  }

  <template>
    <fieldset class="ao3-composer-fields">
      <legend>{{i18n "ao3_fanfic.composer.legend"}}</legend>
      <p class="ao3-composer-fields__note">
        {{i18n "ao3_fanfic.composer.privacy_note"}}
      </p>

      <div class="ao3-composer-fields__groups">
        <section class="ao3-composer-fields__group">
          <h3>{{i18n "ao3_fanfic.composer.groups.thread"}}</h3>
          <div class="ao3-composer-fields__grid">
            <label>
              <span>{{i18n "ao3_fanfic.composer.discussion_type"}}</span>
              <select
                name="ao3_discussion_type"
                autocomplete="off"
                {{on "change" this.updateDiscussionType}}
              >
                <option
                  value="general"
                  selected={{eq this.state.discussionType "general"}}
                >
                  {{i18n "ao3_fanfic.discussion_types.general"}}
                </option>
                <option
                  value="fic_recommendation"
                  selected={{eq this.state.discussionType "fic_recommendation"}}
                >
                  {{i18n "ao3_fanfic.discussion_types.fic_recommendation"}}
                </option>
                <option
                  value="chapter_discussion"
                  selected={{eq this.state.discussionType "chapter_discussion"}}
                >
                  {{i18n "ao3_fanfic.discussion_types.chapter_discussion"}}
                </option>
                <option
                  value="looking_for_fic"
                  selected={{eq this.state.discussionType "looking_for_fic"}}
                >
                  {{i18n "ao3_fanfic.discussion_types.looking_for_fic"}}
                </option>
              </select>
            </label>

            <label>
              <span>{{i18n "ao3_fanfic.composer.fandom_tags"}}</span>
              <input
                name="ao3_fandom_tags"
                autocomplete="off"
                spellcheck="false"
                value={{this.state.fandomTagsText}}
                placeholder={{i18n "ao3_fanfic.composer.list_placeholder"}}
                {{on "input" (fn this.updateText "fandomTagsText")}}
              />
            </label>

            <label>
              <span>{{i18n "ao3_fanfic.composer.ship_tags"}}</span>
              <input
                name="ao3_ship_tags"
                autocomplete="off"
                spellcheck="false"
                value={{this.state.shipTagsText}}
                placeholder={{i18n "ao3_fanfic.composer.list_placeholder"}}
                {{on "input" (fn this.updateText "shipTagsText")}}
              />
            </label>
          </div>
        </section>

        <section class="ao3-composer-fields__group">
          <h3>{{i18n "ao3_fanfic.composer.groups.safety"}}</h3>
          <div class="ao3-composer-fields__grid">
            <label>
              <span>{{i18n "ao3_fanfic.composer.content_warnings"}}</span>
              <input
                name="ao3_content_warnings"
                autocomplete="off"
                value={{this.state.contentWarningsText}}
                placeholder={{i18n "ao3_fanfic.composer.list_placeholder"}}
                {{on "input" (fn this.updateText "contentWarningsText")}}
              />
            </label>

            <label>
              <span>{{i18n "ao3_fanfic.composer.spoiler_label"}}</span>
              <input
                name="ao3_spoiler_label"
                autocomplete="off"
                value={{this.state.spoilerLabel}}
                {{on "input" (fn this.updateText "spoilerLabel")}}
              />
            </label>

            <label>
              <span>{{i18n "ao3_fanfic.composer.spoiler_until"}}</span>
              <input
                type="date"
                name="ao3_spoiler_until"
                autocomplete="off"
                value={{this.state.spoilerUntil}}
                {{on "input" (fn this.updateText "spoilerUntil")}}
              />
            </label>
          </div>
        </section>

        <section class="ao3-composer-fields__group">
          <h3>{{i18n "ao3_fanfic.composer.groups.fic"}}</h3>
          <div class="ao3-composer-fields__grid">
            <label>
              <span>{{i18n "ao3_fanfic.composer.fic_url"}}</span>
              <input
                type="url"
                name="ao3_fic_url"
                autocomplete="off"
                spellcheck="false"
                value={{this.state.ficUrl}}
                inputmode="url"
                {{on "input" (fn this.updateText "ficUrl")}}
              />
            </label>

            <label>
              <span>{{i18n "ao3_fanfic.composer.fic_title"}}</span>
              <input
                name="ao3_fic_title"
                autocomplete="off"
                value={{this.state.ficTitle}}
                {{on "input" (fn this.updateText "ficTitle")}}
              />
            </label>

            <label>
              <span>{{i18n "ao3_fanfic.composer.fic_author"}}</span>
              <input
                name="ao3_fic_author"
                autocomplete="off"
                value={{this.state.ficAuthor}}
                {{on "input" (fn this.updateText "ficAuthor")}}
              />
            </label>

            <label>
              <span>{{i18n "ao3_fanfic.composer.chapter_ref"}}</span>
              <input
                name="ao3_chapter_ref"
                autocomplete="off"
                value={{this.state.chapterRef}}
                {{on "input" (fn this.updateText "chapterRef")}}
              />
            </label>
          </div>
        </section>
      </div>
    </fieldset>
  </template>
}
