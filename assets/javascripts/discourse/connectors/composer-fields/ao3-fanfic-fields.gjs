import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
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
  visibility: "ao3_visibility",
  spaceGroupId: "ao3_space_group_id",
  postAnonymously: "ao3_post_anonymously",
};

function splitList(value) {
  return (value || "")
    .split(/[,\n|]/)
    .map((item) => item.trim().replace(/\s+/g, " "))
    .filter(Boolean)
    .filter((item, index, array) => {
      const key = item.toLowerCase();
      return array.findIndex((candidate) => candidate.toLowerCase() === key) === index;
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

function booleanValue(value, fallback) {
  if (typeof value === "boolean") {
    return value;
  }

  if (typeof value === "string") {
    return value === "true";
  }

  return fallback;
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

function stateFromMetadata(metadata, defaultAnonymous) {
  return {
    discussionType: metadata.discussion_type || metadata.ao3_discussion_type || "general",
    fandomTagsText: listText(metadata.fandom_tags || metadata.ao3_fandom_tags),
    shipTagsText: listText(metadata.ship_tags || metadata.ao3_ship_tags),
    contentWarningsText: listText(
      metadata.content_warnings || metadata.ao3_content_warnings
    ),
    spoilerLabel: metadata.spoiler_label || metadata.ao3_spoiler_label || "",
    spoilerUntil: dateValue(metadata.spoiler_until || metadata.ao3_spoiler_until),
    ficUrl: metadata.fic_url || metadata.ao3_fic_url || "",
    ficTitle: metadata.fic_title || metadata.ao3_fic_title || "",
    ficAuthor: metadata.fic_author || metadata.ao3_fic_author || "",
    chapterRef: metadata.chapter_ref || metadata.ao3_chapter_ref || "",
    visibility: metadata.visibility || metadata.ao3_visibility || "public",
    spaceGroupId: metadata.space_group_id || metadata.ao3_space_group_id || "",
    postAnonymously: booleanValue(
      metadata.post_anonymously ?? metadata.ao3_post_anonymously,
      defaultAnonymous
    ),
  };
}

function topicCustomFields(state) {
  return {
    [FIELDS.discussionType]: state.discussionType,
    [FIELDS.fandomTags]: JSON.stringify(splitList(state.fandomTagsText)),
    [FIELDS.shipTags]: JSON.stringify(splitList(state.shipTagsText)),
    [FIELDS.contentWarnings]: JSON.stringify(splitList(state.contentWarningsText)),
    [FIELDS.spoilerLabel]: state.spoilerLabel,
    [FIELDS.spoilerUntil]: state.spoilerUntil,
    [FIELDS.ficUrl]: state.ficUrl,
    [FIELDS.ficTitle]: state.ficTitle,
    [FIELDS.ficAuthor]: state.ficAuthor,
    [FIELDS.chapterRef]: state.chapterRef,
    [FIELDS.visibility]: state.visibility,
    [FIELDS.spaceGroupId]: `${state.spaceGroupId || ""}`,
    [FIELDS.postAnonymously]: state.postAnonymously ? "true" : "false",
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

  @service siteSettings;
  @tracked state;

  constructor() {
    super(...arguments);
    this.state = stateFromMetadata(
      existingMetadata(this.model),
      this.siteSettings.ao3_fanfic_default_anonymous
    );
    if (this.state.visibility === "space" && !this.state.spaceGroupId) {
      this.state = { ...this.state, spaceGroupId: this.defaultSpaceGroupId };
    }
    this.syncModel();
  }

  get model() {
    return this.args.outletArgs.model;
  }

  get defaultSpaceGroupId() {
    return (
      this.siteSettings.ao3_fanfic_allowed_space_groups
        ?.toString()
        .split("|")
        .filter(Boolean)[0] || ""
    );
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
  updateVisibility(event) {
    const visibility = event.target.value;
    const changes = { visibility };

    if (visibility === "space" && !this.state.spaceGroupId) {
      changes.spaceGroupId = this.defaultSpaceGroupId;
    }

    this.updateState(changes);
  }

  @action
  updateText(field, event) {
    this.updateState({ [field]: event.target.value });
  }

  @action
  updateAnonymous(event) {
    this.updateState({ postAnonymously: event.target.checked });
  }

  <template>
    <fieldset class="ao3-composer-fields">
      <legend>{{i18n "ao3_fanfic.composer.legend"}}</legend>

      <div class="ao3-composer-fields__grid">
        <label>
          <span>{{i18n "ao3_fanfic.composer.discussion_type"}}</span>
          <select {{on "change" this.updateDiscussionType}}>
            <option value="general" selected={{eq this.state.discussionType "general"}}>
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
            value={{this.state.fandomTagsText}}
            placeholder={{i18n "ao3_fanfic.composer.list_placeholder"}}
            {{on "input" (fn this.updateText "fandomTagsText")}}
          />
        </label>

        <label>
          <span>{{i18n "ao3_fanfic.composer.ship_tags"}}</span>
          <input
            value={{this.state.shipTagsText}}
            placeholder={{i18n "ao3_fanfic.composer.list_placeholder"}}
            {{on "input" (fn this.updateText "shipTagsText")}}
          />
        </label>

        <label>
          <span>{{i18n "ao3_fanfic.composer.content_warnings"}}</span>
          <input
            value={{this.state.contentWarningsText}}
            placeholder={{i18n "ao3_fanfic.composer.list_placeholder"}}
            {{on "input" (fn this.updateText "contentWarningsText")}}
          />
        </label>

        <label>
          <span>{{i18n "ao3_fanfic.composer.spoiler_label"}}</span>
          <input
            value={{this.state.spoilerLabel}}
            {{on "input" (fn this.updateText "spoilerLabel")}}
          />
        </label>

        <label>
          <span>{{i18n "ao3_fanfic.composer.spoiler_until"}}</span>
          <input
            type="date"
            value={{this.state.spoilerUntil}}
            {{on "input" (fn this.updateText "spoilerUntil")}}
          />
        </label>

        <label>
          <span>{{i18n "ao3_fanfic.composer.fic_url"}}</span>
          <input
            value={{this.state.ficUrl}}
            inputmode="url"
            {{on "input" (fn this.updateText "ficUrl")}}
          />
        </label>

        <label>
          <span>{{i18n "ao3_fanfic.composer.fic_title"}}</span>
          <input
            value={{this.state.ficTitle}}
            {{on "input" (fn this.updateText "ficTitle")}}
          />
        </label>

        <label>
          <span>{{i18n "ao3_fanfic.composer.fic_author"}}</span>
          <input
            value={{this.state.ficAuthor}}
            {{on "input" (fn this.updateText "ficAuthor")}}
          />
        </label>

        <label>
          <span>{{i18n "ao3_fanfic.composer.chapter_ref"}}</span>
          <input
            value={{this.state.chapterRef}}
            {{on "input" (fn this.updateText "chapterRef")}}
          />
        </label>

        <label>
          <span>{{i18n "ao3_fanfic.composer.visibility"}}</span>
          <select {{on "change" this.updateVisibility}}>
            <option value="public" selected={{eq this.state.visibility "public"}}>
              {{i18n "ao3_fanfic.visibilities.public"}}
            </option>
            <option value="members" selected={{eq this.state.visibility "members"}}>
              {{i18n "ao3_fanfic.visibilities.members"}}
            </option>
            <option value="space" selected={{eq this.state.visibility "space"}}>
              {{i18n "ao3_fanfic.visibilities.space"}}
            </option>
          </select>
        </label>

        {{#if (eq this.state.visibility "space")}}
          <label>
            <span>{{i18n "ao3_fanfic.composer.space_group_id"}}</span>
            <input
              type="number"
              min="1"
              value={{this.state.spaceGroupId}}
              {{on "input" (fn this.updateText "spaceGroupId")}}
            />
          </label>
        {{/if}}
      </div>

      <label class="ao3-composer-fields__checkbox">
        <input
          type="checkbox"
          checked={{this.state.postAnonymously}}
          {{on "change" this.updateAnonymous}}
        />
        <span>{{i18n "ao3_fanfic.composer.anonymous"}}</span>
      </label>
    </fieldset>
  </template>
}
