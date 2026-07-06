import Component from "@glimmer/component";
import getURL from "discourse/lib/get-url";
import { i18n } from "discourse-i18n";

export default class Ao3AuthPanel extends Component {
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

  get modeLabel() {
    return i18n(
      this.isSignup
        ? "ao3_fanfic.auth.signup_mode_label"
        : "ao3_fanfic.auth.login_mode_label"
    );
  }

  get subscribeUrl() {
    return getURL("/ao3-fanfic/supporter");
  }

  <template>
    <section
      class="ao3-auth-panel"
      aria-label={{i18n "ao3_fanfic.auth.panel_label"}}
    >
      <div class="ao3-auth-panel__brand">
        <span class="ao3-auth-panel__mark">AO3Chat</span>
        <span class="ao3-auth-panel__mode">{{this.modeLabel}}</span>
        <span class="ao3-auth-panel__rule"></span>
      </div>

      <div class="ao3-auth-panel__copy">
        <h2>{{this.title}}</h2>
        <p>{{this.body}}</p>
      </div>

      <div class="ao3-auth-panel__identity">
        <span>{{i18n "ao3_fanfic.auth.identity_label"}}</span>
        <strong>{{i18n "ao3_fanfic.auth.identity_title"}}</strong>
        <em>{{i18n "ao3_fanfic.auth.identity_body"}}</em>
      </div>

      <ul class="ao3-auth-panel__facts">
        <li>{{i18n "ao3_fanfic.auth.facts.reader_identity"}}</li>
        <li>{{i18n "ao3_fanfic.auth.facts.restricted_rooms"}}</li>
        <li>{{i18n "ao3_fanfic.auth.facts.private_rooms"}}</li>
      </ul>

      <a href={{this.subscribeUrl}} class="ao3-auth-panel__supporter">
        {{i18n "ao3_fanfic.auth.supporter_link"}}
      </a>
    </section>
  </template>
}
