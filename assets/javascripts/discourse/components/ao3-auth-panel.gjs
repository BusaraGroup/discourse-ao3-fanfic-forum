import Component from "@glimmer/component";
import { service } from "@ember/service";
import getURL from "discourse/lib/get-url";
import { i18n } from "discourse-i18n";

export default class Ao3AuthPanel extends Component {
  @service siteSettings;

  get isSignup() {
    return this.args.mode === "signup";
  }

  get title() {
    return i18n(
      this.isSignup
        ? "ao3_fanfic.auth.signup_title"
        : "ao3_fanfic.auth.login_title"
    );
  }

  get body() {
    return i18n(
      this.isSignup
        ? "ao3_fanfic.auth.signup_body"
        : "ao3_fanfic.auth.login_body"
    );
  }

  get subscribeUrl() {
    return getURL(this.siteSettings.ao3_fanfic_subscribe_url || "/s");
  }

  <template>
    <section
      class="ao3-auth-panel"
      aria-label={{i18n "ao3_fanfic.auth.panel_label"}}
    >
      <div class="ao3-auth-panel__brand">
        <span class="ao3-auth-panel__mark">AO3Chat</span>
        <span class="ao3-auth-panel__rule"></span>
      </div>

      <div class="ao3-auth-panel__copy">
        <h2>{{this.title}}</h2>
        <p>{{this.body}}</p>
      </div>

      <ul class="ao3-auth-panel__facts">
        <li>{{i18n "ao3_fanfic.auth.facts.reader_identity"}}</li>
        <li>{{i18n "ao3_fanfic.auth.facts.anonymous_posts"}}</li>
        <li>{{i18n "ao3_fanfic.auth.facts.private_rooms"}}</li>
      </ul>

      <a href={{this.subscribeUrl}} class="ao3-auth-panel__supporter">
        {{i18n "ao3_fanfic.auth.supporter_link"}}
      </a>
    </section>
  </template>
}
