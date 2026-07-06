import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import getURL from "discourse/lib/get-url";
import { eq } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";
import Ao3FanficTopicChips from "discourse/plugins/discourse-ao3-fanfic-forum/discourse/components/ao3-fanfic-topic-chips";

const EMPTY_FILTERS = {
  discussionType: "",
  fandom: "",
  ship: "",
  warning: "",
  excludeWarning: "",
  spoilerSafe: true,
};

function compactText(value) {
  return (value || "").trim().replace(/\s+/g, " ");
}

export default class Ao3FanficBrowser extends Component {
  @tracked filters = { ...EMPTY_FILTERS };
  @tracked topics = [];
  @tracked loading = false;
  @tracked loaded = false;
  @tracked error = null;

  constructor() {
    super(...arguments);
    this.loadTopics();
  }

  get hasTopics() {
    return this.topics.length > 0;
  }

  get queryParams() {
    const params = { per_page: 8 };
    const mappings = {
      discussion_type: this.filters.discussionType,
      fandom: this.filters.fandom,
      ship: this.filters.ship,
      warning: this.filters.warning,
      exclude_warning: this.filters.excludeWarning,
    };

    Object.entries(mappings).forEach(([key, value]) => {
      const compacted = compactText(value);

      if (compacted) {
        params[key] = compacted;
      }
    });

    if (this.filters.spoilerSafe) {
      params.spoiler_safe = true;
    }

    return params;
  }

  topicUrl(topic) {
    if (topic.url) {
      return getURL(topic.url);
    }

    if (topic.slug && topic.id) {
      return getURL(`/t/${topic.slug}/${topic.id}`);
    }

    return getURL(`/t/${topic.id}`);
  }

  ficLabel(metadata) {
    if (metadata?.fic_title && metadata?.fic_author) {
      return i18n("ao3_fanfic.browser.fic_by", {
        title: metadata.fic_title,
        author: metadata.fic_author,
      });
    }

    if (metadata?.fic_title) {
      return metadata.fic_title;
    }

    if (metadata?.fic_author) {
      return i18n("ao3_fanfic.browser.fic_author", {
        author: metadata.fic_author,
      });
    }

    return "";
  }

  chapterLabel(metadata) {
    if (!metadata?.chapter_ref) {
      return "";
    }

    return i18n("ao3_fanfic.browser.chapter", {
      chapter: metadata.chapter_ref,
    });
  }

  normalizeTopic(topic) {
    const metadata = topic.ao3_fanfic || {};

    return {
      ...topic,
      title:
        topic.title || topic.fancy_title || i18n("ao3_fanfic.browser.untitled"),
      url: this.topicUrl(topic),
      metadata,
      ficLabel: this.ficLabel(metadata),
      chapterLabel: this.chapterLabel(metadata),
      replies: topic.reply_count ?? Math.max((topic.posts_count || 1) - 1, 0),
      views: topic.views ?? 0,
    };
  }

  @action
  async loadTopics(event) {
    event?.preventDefault();
    this.loading = true;
    this.error = null;

    try {
      const payload = await ajax(getURL("/ao3-fanfic/topics.json"), {
        data: this.queryParams,
      });
      this.topics = (payload.topics || []).map((topic) =>
        this.normalizeTopic(topic)
      );
      this.loaded = true;
    } catch {
      this.error = i18n("ao3_fanfic.browser.error");
    } finally {
      this.loading = false;
    }
  }

  @action
  updateDiscussionType(event) {
    this.filters = { ...this.filters, discussionType: event.target.value };
  }

  @action
  updateText(field, event) {
    this.filters = { ...this.filters, [field]: event.target.value };
  }

  @action
  updateSpoilerSafe(event) {
    this.filters = { ...this.filters, spoilerSafe: event.target.checked };
  }

  @action
  clearFilters(event) {
    event.preventDefault();
    this.filters = { ...EMPTY_FILTERS };
    this.loadTopics();
  }

  <template>
    <section class="ao3-browser" aria-labelledby="ao3-browser-title" ...attributes>
      <div class="ao3-browser__heading">
        <div>
          <h2 id="ao3-browser-title">{{i18n "ao3_fanfic.browser.title"}}</h2>
          <p>{{i18n "ao3_fanfic.browser.subtitle"}}</p>
        </div>
      </div>

      <form class="ao3-browser__form" {{on "submit" this.loadTopics}}>
        <label class="ao3-browser__field">
          <span>{{i18n "ao3_fanfic.browser.discussion_type"}}</span>
          <select {{on "change" this.updateDiscussionType}}>
            <option value="" selected={{eq this.filters.discussionType ""}}>
              {{i18n "ao3_fanfic.browser.any_type"}}
            </option>
            <option value="general" selected={{eq this.filters.discussionType "general"}}>
              {{i18n "ao3_fanfic.discussion_types.general"}}
            </option>
            <option
              value="fic_recommendation"
              selected={{eq this.filters.discussionType "fic_recommendation"}}
            >
              {{i18n "ao3_fanfic.discussion_types.fic_recommendation"}}
            </option>
            <option
              value="chapter_discussion"
              selected={{eq this.filters.discussionType "chapter_discussion"}}
            >
              {{i18n "ao3_fanfic.discussion_types.chapter_discussion"}}
            </option>
            <option
              value="looking_for_fic"
              selected={{eq this.filters.discussionType "looking_for_fic"}}
            >
              {{i18n "ao3_fanfic.discussion_types.looking_for_fic"}}
            </option>
          </select>
        </label>

        <label class="ao3-browser__field">
          <span>{{i18n "ao3_fanfic.browser.fandom"}}</span>
          <input value={{this.filters.fandom}} {{on "input" (fn this.updateText "fandom")}} />
        </label>

        <label class="ao3-browser__field">
          <span>{{i18n "ao3_fanfic.browser.ship"}}</span>
          <input value={{this.filters.ship}} {{on "input" (fn this.updateText "ship")}} />
        </label>

        <label class="ao3-browser__field">
          <span>{{i18n "ao3_fanfic.browser.warning"}}</span>
          <input value={{this.filters.warning}} {{on "input" (fn this.updateText "warning")}} />
        </label>

        <label class="ao3-browser__field">
          <span>{{i18n "ao3_fanfic.browser.exclude_warning"}}</span>
          <input
            value={{this.filters.excludeWarning}}
            {{on "input" (fn this.updateText "excludeWarning")}}
          />
        </label>

        <label class="ao3-browser__toggle">
          <input
            type="checkbox"
            checked={{this.filters.spoilerSafe}}
            {{on "change" this.updateSpoilerSafe}}
          />
          <span>{{i18n "ao3_fanfic.browser.spoiler_safe"}}</span>
        </label>

        <div class="ao3-browser__actions">
          <button type="submit" class="btn btn-primary">{{i18n "ao3_fanfic.browser.apply"}}</button>
          <button type="button" class="btn btn-default" {{on "click" this.clearFilters}}>
            {{i18n "ao3_fanfic.browser.clear"}}
          </button>
        </div>
      </form>

      <div class="ao3-browser__results" aria-live="polite" aria-busy={{this.loading}}>
        {{#if this.loading}}
          <p class="ao3-browser__status">{{i18n "ao3_fanfic.browser.loading"}}</p>
        {{else if this.error}}
          <p class="ao3-browser__status ao3-browser__status--error">{{this.error}}</p>
        {{else if this.hasTopics}}
          <p class="ao3-browser__count">
            {{i18n "ao3_fanfic.browser.results_label" count=this.topics.length}}
          </p>

          <ol class="ao3-browser__list">
            {{#each this.topics as |topic|}}
              <li class="ao3-browser__row">
                <div class="ao3-browser__topic">
                  <a class="ao3-browser__title" href={{topic.url}}>{{topic.title}}</a>

                  {{#if topic.ficLabel}}
                    <span class="ao3-browser__fic">{{topic.ficLabel}}</span>
                  {{/if}}

                  {{#if topic.chapterLabel}}
                    <span class="ao3-browser__chapter">{{topic.chapterLabel}}</span>
                  {{/if}}

                  <Ao3FanficTopicChips @metadata={{topic.metadata}} @context="browser" />
                </div>

                <div class="ao3-browser__stats">
                  <span>{{i18n "ao3_fanfic.browser.replies" count=topic.replies}}</span>
                  <span>{{i18n "ao3_fanfic.browser.views" count=topic.views}}</span>
                </div>
              </li>
            {{/each}}
          </ol>
        {{else if this.loaded}}
          <p class="ao3-browser__status">{{i18n "ao3_fanfic.browser.empty"}}</p>
        {{/if}}
      </div>
    </section>
  </template>
}
