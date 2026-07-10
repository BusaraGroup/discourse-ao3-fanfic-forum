import Component from "@glimmer/component";
import { service } from "@ember/service";
import getURL from "discourse/lib/get-url";
import Category from "discourse/models/category";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import Ao3FanficBrowser from "discourse/plugins/discourse-ao3-fanfic-forum/discourse/components/ao3-fanfic-browser";
import Ao3PrivateRoomRequest from "discourse/plugins/discourse-ao3-fanfic-forum/discourse/components/ao3-private-room-request";

const FANDOM_LABEL_OVERRIDES = {
  "ao3-tools": "AO3 tools",
  bts: "BTS",
  "k-pop": "K-POP",
};

function parseListSetting(value) {
  return (value || "")
    .toString()
    .split(/[|\n,]/)
    .map((item) => item.trim())
    .filter(Boolean);
}

function titleForSlug(slug) {
  if (FANDOM_LABEL_OVERRIDES[slug]) {
    return FANDOM_LABEL_OVERRIDES[slug];
  }

  return slug
    .split("-")
    .filter(Boolean)
    .map((word) => `${word.charAt(0).toUpperCase()}${word.slice(1)}`)
    .join(" ");
}

export default class Ao3FanficHome extends Component {
  static shouldRender(args, { siteSettings }) {
    return siteSettings.ao3_fanfic_enabled;
  }

  @service currentUser;
  @service siteSettings;

  get subscribeUrl() {
    return getURL("/ao3-fanfic/supporter");
  }

  get accountUrl() {
    return getURL("/ao3-fanfic/account");
  }

  get loginUrl() {
    return getURL("/ao3-fanfic/login");
  }

  get signupUrl() {
    return getURL("/ao3-fanfic/signup");
  }

  get newTopicUrl() {
    return getURL("/new-topic");
  }

  get tagsUrl() {
    return getURL("/tags");
  }

  get privateRoomsUrl() {
    return this.categoryUrl(
      this.siteSettings.ao3_fanfic_private_rooms_category_slug
    );
  }

  get welcomeDeskUrl() {
    return this.categoryUrl("welcome-desk");
  }

  get ficRecsUrl() {
    return this.categoryUrl("fic-recs");
  }

  get chapterDiscussionsUrl() {
    return this.categoryUrl("chapter-discussions");
  }

  get lookingForFicUrl() {
    return this.categoryUrl("looking-for-a-fic");
  }

  get spoilerZoneUrl() {
    return this.categoryUrl("spoiler-zone");
  }

  get contentWarningsUrl() {
    return this.categoryUrl("content-warnings");
  }

  get fandomSpacesUrl() {
    return this.categoryUrl("fandom-spaces");
  }

  get siteHelpUrl() {
    return this.categoryUrl("site-help");
  }

  get supporterPriceLabel() {
    return this.siteSettings.ao3_fanfic_supporter_price_label;
  }

  get featuredFandoms() {
    return parseListSetting(
      this.siteSettings.ao3_fanfic_featured_fandom_slugs
    ).map((slug) => {
      const category = this.categoryForSlug(slug);

      return {
        slug,
        name: category?.name || titleForSlug(slug),
        url: this.categoryUrl(slug),
      };
    });
  }

  categoryForSlug(slug) {
    return Category.list()?.find((item) => {
      return item.slug === slug || Category.slugFor(item) === slug;
    });
  }

  categoryUrl(slug) {
    const category = this.categoryForSlug(slug);

    if (category?.url) {
      return getURL(category.url);
    }

    if (category?.id) {
      return getURL(`/c/${Category.slugFor(category)}/${category.id}`);
    }

    return getURL(`/c/${slug}`);
  }

  <template>
    <section class="ao3-home" ...attributes>
      <div class="ao3-home__main">
        <div class="ao3-home__heading">
          <h1>{{i18n "ao3_fanfic.home.title"}}</h1>
          <p>{{i18n "ao3_fanfic.home.subtitle"}}</p>
        </div>

        <div class="ao3-home__auth">
          {{#if this.currentUser}}
            <a
              href={{this.newTopicUrl}}
              class="btn btn-primary ao3-home__button"
            >
              {{dIcon "plus"}}
              {{i18n "ao3_fanfic.home.new_topic"}}
            </a>
          {{else}}
            <a
              href={{this.loginUrl}}
              class="btn btn-primary ao3-home__button"
              data-auto-route="true"
            >
              {{dIcon "arrow-right"}}
              {{i18n "ao3_fanfic.home.login"}}
            </a>
            <a
              href={{this.signupUrl}}
              class="btn btn-default ao3-home__button"
              data-auto-route="true"
            >
              {{dIcon "users"}}
              {{i18n "ao3_fanfic.home.create_account"}}
            </a>
            <a
              href={{this.accountUrl}}
              class="ao3-home__account-link"
              data-auto-route="true"
            >
              {{i18n "ao3_fanfic.home.account_link"}}
            </a>
          {{/if}}
        </div>

        <div
          class="ao3-home__filters"
          aria-label={{i18n "ao3_fanfic.home.filters_label"}}
        >
          <a href={{this.fandomSpacesUrl}} class="ao3-home-filter">
            <span class="ao3-home-filter__icon">{{dIcon "users"}}</span>
            <span class="ao3-home-filter__copy">
              <span class="ao3-home-filter__label">{{i18n
                  "ao3_fanfic.home.fandoms"
                }}</span>
              <span class="ao3-home-filter__value">{{i18n
                  "ao3_fanfic.home.fandoms_value"
                }}</span>
            </span>
            {{dIcon "arrow-right" class="ao3-home-filter__arrow"}}
          </a>
          <a href={{this.tagsUrl}} class="ao3-home-filter">
            <span class="ao3-home-filter__icon">{{dIcon "heart"}}</span>
            <span class="ao3-home-filter__copy">
              <span class="ao3-home-filter__label">{{i18n
                  "ao3_fanfic.home.ships"
                }}</span>
              <span class="ao3-home-filter__value">{{i18n
                  "ao3_fanfic.home.ships_value"
                }}</span>
            </span>
            {{dIcon "arrow-right" class="ao3-home-filter__arrow"}}
          </a>
          <a href={{this.spoilerZoneUrl}} class="ao3-home-filter">
            <span class="ao3-home-filter__icon">{{dIcon "eye-slash"}}</span>
            <span class="ao3-home-filter__copy">
              <span class="ao3-home-filter__label">{{i18n
                  "ao3_fanfic.home.spoilers"
                }}</span>
              <span class="ao3-home-filter__value">{{i18n
                  "ao3_fanfic.home.spoilers_value"
                }}</span>
            </span>
            {{dIcon "arrow-right" class="ao3-home-filter__arrow"}}
          </a>
          <a href={{this.contentWarningsUrl}} class="ao3-home-filter">
            <span class="ao3-home-filter__icon">{{dIcon
                "triangle-exclamation"
              }}</span>
            <span class="ao3-home-filter__copy">
              <span class="ao3-home-filter__label">{{i18n
                  "ao3_fanfic.home.warnings"
                }}</span>
              <span class="ao3-home-filter__value">{{i18n
                  "ao3_fanfic.home.warnings_value"
                }}</span>
            </span>
            {{dIcon "arrow-right" class="ao3-home-filter__arrow"}}
          </a>
        </div>

        {{#if this.featuredFandoms.length}}
          <section
            class="ao3-home__featured"
            aria-labelledby="ao3-featured-fandoms-title"
          >
            <div>
              <h2 id="ao3-featured-fandoms-title">
                {{i18n "ao3_fanfic.home.featured_fandoms_title"}}
              </h2>
              <p>{{i18n "ao3_fanfic.home.featured_fandoms_body"}}</p>
            </div>

            <nav
              class="ao3-home__featured-list"
              aria-label={{i18n "ao3_fanfic.home.featured_fandoms_label"}}
            >
              {{#each this.featuredFandoms as |fandom|}}
                <a href={{fandom.url}} class="ao3-featured-fandom">
                  <span class="ao3-featured-fandom__name">{{fandom.name}}</span>
                  {{dIcon "arrow-right" class="ao3-featured-fandom__arrow"}}
                </a>
              {{/each}}
            </nav>
          </section>
        {{/if}}

        <nav
          class="ao3-home__quick-links"
          aria-label={{i18n "ao3_fanfic.home.quick_links_label"}}
        >
          <a href={{this.welcomeDeskUrl}}>
            <span>{{i18n "ao3_fanfic.home.welcome_desk"}}</span>
            {{dIcon "arrow-right"}}
          </a>
          <a href={{this.ficRecsUrl}}>
            <span>{{i18n "ao3_fanfic.home.fic_recs"}}</span>
            {{dIcon "arrow-right"}}
          </a>
          <a href={{this.chapterDiscussionsUrl}}>
            <span>{{i18n "ao3_fanfic.home.chapter_threads"}}</span>
            {{dIcon "arrow-right"}}
          </a>
          <a href={{this.lookingForFicUrl}}>
            <span>{{i18n "ao3_fanfic.home.looking_for_fic"}}</span>
            {{dIcon "arrow-right"}}
          </a>
          <a href={{this.fandomSpacesUrl}}>
            <span>{{i18n "ao3_fanfic.home.fandom_spaces"}}</span>
            {{dIcon "arrow-right"}}
          </a>
          <a href={{this.siteHelpUrl}}>
            <span>{{i18n "ao3_fanfic.home.site_help"}}</span>
            {{dIcon "arrow-right"}}
          </a>
          <a href={{this.privateRoomsUrl}}>
            <span>{{i18n "ao3_fanfic.home.private_rooms"}}</span>
            {{dIcon "lock"}}
          </a>
        </nav>
      </div>

      {{#if this.siteSettings.ao3_fanfic_paid_rooms_enabled}}
        <aside class="ao3-home__supporter">
          <div class="ao3-supporter-card">
            <div class="ao3-supporter-card__heading">
              <h2>{{i18n "ao3_fanfic.home.supporter_title"}}</h2>
              <span>
                {{dIcon "lock"}}
                {{i18n "ao3_fanfic.home.supporter_badge"}}
              </span>
            </div>
            <p>{{i18n "ao3_fanfic.home.supporter_body"}}</p>
            <ul>
              <li>{{i18n
                  "ao3_fanfic.home.supporter_features.private_rooms"
                }}</li>
              <li>{{i18n
                  "ao3_fanfic.home.supporter_features.archive_access"
                }}</li>
              <li>{{i18n "ao3_fanfic.home.supporter_features.events"}}</li>
              <li>{{i18n "ao3_fanfic.home.supporter_features.support"}}</li>
            </ul>
            <div class="ao3-supporter-card__price">
              <span>{{i18n "ao3_fanfic.home.supporter_price_prefix"}}</span>
              <strong>{{this.supporterPriceLabel}}</strong>
            </div>
            <a
              href={{this.subscribeUrl}}
              class="btn btn-primary ao3-supporter-card__button"
              data-auto-route="true"
            >
              {{dIcon "arrow-right"}}
              {{i18n "ao3_fanfic.home.supporter_cta"}}
            </a>
            <Ao3PrivateRoomRequest />
          </div>
        </aside>
      {{/if}}

      <Ao3FanficBrowser />
    </section>
  </template>
}
