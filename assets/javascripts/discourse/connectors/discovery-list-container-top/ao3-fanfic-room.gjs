import Component from "@glimmer/component";
import { service } from "@ember/service";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";

export default class Ao3FanficRoom extends Component {
  static shouldRender(args, { siteSettings }) {
    return (
      siteSettings.ao3_fanfic_enabled && Boolean(args.category) && !args.tag
    );
  }

  @service router;

  get category() {
    return this.args.outletArgs.category;
  }

  get categoryName() {
    return this.category.displayName || this.category.name;
  }

  get searchTerm() {
    return this.router.currentRoute?.queryParams?.search || "";
  }

  <template>
    <section class="ao3-room" aria-labelledby="ao3-room-title" ...attributes>
      <header class="ao3-room__header">
        <div class="ao3-room__identity">
          <span class="ao3-room__eyebrow">{{i18n
              "ao3_fanfic.room.eyebrow"
            }}</span>
          <h1 id="ao3-room-title">{{this.categoryName}}</h1>
          {{#if this.category.descriptionText}}
            <p>{{this.category.descriptionText}}</p>
          {{/if}}
        </div>

        <span class="ao3-room__count">
          {{i18n
            "ao3_fanfic.room.discussion_count"
            count=this.category.topic_count
          }}
        </span>
      </header>

      <form
        class="ao3-room__search"
        action={{this.category.url}}
        method="get"
        role="search"
      >
        <label for="ao3-room-search">{{i18n
            "ao3_fanfic.room.search_label"
          }}</label>
        <div class="ao3-room__search-controls">
          <input
            id="ao3-room-search"
            name="search"
            type="search"
            autocomplete="off"
            spellcheck="false"
            value={{this.searchTerm}}
            placeholder={{i18n
              "ao3_fanfic.room.search_placeholder"
              room=this.categoryName
            }}
          />
          <button class="btn btn-default" type="submit">
            {{dIcon "magnifying-glass"}}
            <span>{{i18n "ao3_fanfic.room.search_action"}}</span>
          </button>
          {{#if this.searchTerm}}
            <a
              class="btn btn-flat ao3-room__clear"
              href={{this.category.url}}
              aria-label={{i18n "ao3_fanfic.room.clear_search"}}
              title={{i18n "ao3_fanfic.room.clear_search"}}
            >
              {{dIcon "xmark"}}
            </a>
          {{/if}}
        </div>
      </form>
    </section>
  </template>
}
