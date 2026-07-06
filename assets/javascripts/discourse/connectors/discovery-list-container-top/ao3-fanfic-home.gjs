import Component from "@glimmer/component";
import { service } from "@ember/service";
import routeAction from "discourse/helpers/route-action";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";

export default class Ao3FanficHome extends Component {
  static shouldRender(args, { siteSettings }) {
    return siteSettings.ao3_fanfic_enabled;
  }

  @service currentUser;
  @service siteSettings;

  get subscribeUrl() {
    return this.siteSettings.ao3_fanfic_subscribe_url || "/s";
  }

  get privateRoomsUrl() {
    return `/c/${this.siteSettings.ao3_fanfic_private_rooms_category_slug}`;
  }

  get supporterPriceLabel() {
    return this.siteSettings.ao3_fanfic_supporter_price_label;
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
            <a href="/new-topic" class="btn btn-primary ao3-home__button">
              {{i18n "ao3_fanfic.home.new_topic"}}
            </a>
          {{else}}
            <DButton
              class="btn-primary ao3-home__button"
              @action={{routeAction "showLogin"}}
              @label="ao3_fanfic.home.login"
            />
            <DButton
              class="btn-default ao3-home__button"
              @action={{routeAction "showCreateAccount"}}
              @label="ao3_fanfic.home.create_account"
            />
          {{/if}}
        </div>

        <div class="ao3-home__filters" aria-label={{i18n "ao3_fanfic.home.filters_label"}}>
          <a href="/tags" class="ao3-home-filter">
            <span class="ao3-home-filter__label">{{i18n "ao3_fanfic.home.fandoms"}}</span>
            <span class="ao3-home-filter__value">{{i18n "ao3_fanfic.home.fandoms_value"}}</span>
          </a>
          <a href="/tags" class="ao3-home-filter">
            <span class="ao3-home-filter__label">{{i18n "ao3_fanfic.home.ships"}}</span>
            <span class="ao3-home-filter__value">{{i18n "ao3_fanfic.home.ships_value"}}</span>
          </a>
          <a href="/latest?spoiler_safe=true" class="ao3-home-filter">
            <span class="ao3-home-filter__label">{{i18n "ao3_fanfic.home.spoilers"}}</span>
            <span class="ao3-home-filter__value">{{i18n "ao3_fanfic.home.spoilers_value"}}</span>
          </a>
          <a href="/latest?exclude_warning=Major%20Character%20Death" class="ao3-home-filter">
            <span class="ao3-home-filter__label">{{i18n "ao3_fanfic.home.warnings"}}</span>
            <span class="ao3-home-filter__value">{{i18n "ao3_fanfic.home.warnings_value"}}</span>
          </a>
        </div>

        <nav class="ao3-home__quick-links" aria-label={{i18n "ao3_fanfic.home.quick_links_label"}}>
          <a href="/c/fic-recs">{{i18n "ao3_fanfic.home.fic_recs"}}</a>
          <a href="/c/chapter-discussions">{{i18n "ao3_fanfic.home.chapter_threads"}}</a>
          <a href="/c/looking-for-a-fic">{{i18n "ao3_fanfic.home.looking_for_fic"}}</a>
          <a href="/c/fandom-spaces">{{i18n "ao3_fanfic.home.fandom_spaces"}}</a>
          <a href={{this.privateRoomsUrl}}>{{i18n "ao3_fanfic.home.private_rooms"}}</a>
        </nav>
      </div>

      {{#if this.siteSettings.ao3_fanfic_paid_rooms_enabled}}
        <aside class="ao3-home__supporter">
          <div class="ao3-supporter-card">
            <div class="ao3-supporter-card__heading">
              <h2>{{i18n "ao3_fanfic.home.supporter_title"}}</h2>
              <span>{{i18n "ao3_fanfic.home.supporter_badge"}}</span>
            </div>
            <p>{{i18n "ao3_fanfic.home.supporter_body"}}</p>
            <ul>
              <li>{{i18n "ao3_fanfic.home.supporter_features.private_rooms"}}</li>
              <li>{{i18n "ao3_fanfic.home.supporter_features.archive_access"}}</li>
              <li>{{i18n "ao3_fanfic.home.supporter_features.events"}}</li>
              <li>{{i18n "ao3_fanfic.home.supporter_features.support"}}</li>
            </ul>
            <div class="ao3-supporter-card__price">
              <span>{{i18n "ao3_fanfic.home.supporter_price_prefix"}}</span>
              <strong>{{this.supporterPriceLabel}}</strong>
            </div>
            <a href={{this.subscribeUrl}} class="btn btn-primary ao3-supporter-card__button">
              {{i18n "ao3_fanfic.home.supporter_cta"}}
            </a>
          </div>
        </aside>
      {{/if}}
    </section>
  </template>
}
