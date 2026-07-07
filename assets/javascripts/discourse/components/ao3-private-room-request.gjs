import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import getURL from "discourse/lib/get-url";
import { i18n } from "discourse-i18n";

const EMPTY_REQUEST = {
  fandom: "",
  ship: "",
  purpose: "",
  spoilerPolicy: "",
  comfortNotes: "",
};

export default class Ao3PrivateRoomRequest extends Component {
  @service currentUser;

  @tracked request = { ...EMPTY_REQUEST };
  @tracked saving = false;
  @tracked error = null;
  @tracked successUrl = null;
  @tracked status = null;
  @tracked statusLoading = false;
  @tracked supporterRequired = false;
  @tracked subscribeUrlOverride = null;

  constructor() {
    super(...arguments);

    if (this.currentUser) {
      this.loadStatus();
    }
  }

  get subscribeUrl() {
    return getURL(
      this.subscribeUrlOverride ||
        this.status?.subscribe_url ||
        "/ao3-fanfic/supporter"
    );
  }

  get privateRoomsUrl() {
    if (!this.status?.private_rooms_url) {
      return null;
    }

    return getURL(this.status.private_rooms_url);
  }

  get signupUrl() {
    return getURL("/ao3-fanfic/signup");
  }

  get hasPrivateRoomAccess() {
    return this.status?.has_private_room_access || false;
  }

  get shouldShowRequestForm() {
    if (!this.currentUser) {
      return false;
    }

    if (this.statusLoading) {
      return false;
    }

    if (!this.status) {
      return true;
    }

    return this.hasPrivateRoomAccess;
  }

  get shouldShowSupporterGate() {
    return (
      this.currentUser &&
      !this.statusLoading &&
      this.status &&
      !this.hasPrivateRoomAccess
    );
  }

  get payload() {
    return {
      fandom: this.request.fandom,
      ship: this.request.ship,
      purpose: this.request.purpose,
      spoiler_policy: this.request.spoilerPolicy,
      comfort_notes: this.request.comfortNotes,
    };
  }

  responseMessage(error) {
    const payload = error?.jqXHR?.responseJSON || error?.responseJSON || {};
    const message = payload.errors?.[0] || i18n("ao3_fanfic.room_request.error");

    if (payload.subscribe_url) {
      this.subscribeUrlOverride = payload.subscribe_url;
      this.supporterRequired = true;
    }

    return message;
  }

  @action
  async loadStatus() {
    this.statusLoading = true;

    try {
      this.status = await ajax(getURL("/ao3-fanfic/supporter-status.json"));
    } catch {
      this.status = null;
    } finally {
      this.statusLoading = false;
    }
  }

  @action
  updateField(field, event) {
    this.request = { ...this.request, [field]: event.target.value };
  }

  @action
  async submit(event) {
    event.preventDefault();
    this.saving = true;
    this.error = null;
    this.supporterRequired = false;
    this.successUrl = null;

    try {
      const payload = await ajax(getURL("/ao3-fanfic/room-requests.json"), {
        type: "POST",
        data: {
          room_request: this.payload,
        },
      });
      this.successUrl = getURL(payload.topic_url);
      this.request = { ...EMPTY_REQUEST };
      await this.loadStatus();
    } catch (error) {
      this.error = this.responseMessage(error);
    } finally {
      this.saving = false;
    }
  }

  <template>
    <section class="ao3-room-request" aria-labelledby="ao3-room-request-title" ...attributes>
      <div class="ao3-room-request__heading">
        <h3 id="ao3-room-request-title">{{i18n "ao3_fanfic.room_request.title"}}</h3>
        <p>{{i18n "ao3_fanfic.room_request.body"}}</p>
      </div>

      {{#if this.statusLoading}}
        <p class="ao3-room-request__status">
          {{i18n "ao3_fanfic.room_request.status_loading"}}
        </p>
      {{else if this.hasPrivateRoomAccess}}
        <p class="ao3-room-request__status ao3-room-request__status--success">
          {{i18n "ao3_fanfic.room_request.access_active"}}
          {{#if this.privateRoomsUrl}}
            <a href={{this.privateRoomsUrl}}>{{i18n "ao3_fanfic.room_request.private_rooms_link"}}</a>
          {{/if}}
        </p>
      {{/if}}

      {{#if this.currentUser}}
        {{#if this.shouldShowRequestForm}}
          <form class="ao3-room-request__form" {{on "submit" this.submit}}>
            <label class="ao3-room-request__field">
              <span>{{i18n "ao3_fanfic.room_request.fandom"}}</span>
              <input
                required
                maxlength="120"
                value={{this.request.fandom}}
                {{on "input" (fn this.updateField "fandom")}}
              />
            </label>

            <label class="ao3-room-request__field">
              <span>{{i18n "ao3_fanfic.room_request.ship"}}</span>
              <input
                maxlength="120"
                value={{this.request.ship}}
                {{on "input" (fn this.updateField "ship")}}
              />
            </label>

            <label class="ao3-room-request__field">
              <span>{{i18n "ao3_fanfic.room_request.purpose"}}</span>
              <textarea
                maxlength="800"
                value={{this.request.purpose}}
                {{on "input" (fn this.updateField "purpose")}}
              ></textarea>
            </label>

            <label class="ao3-room-request__field">
              <span>{{i18n "ao3_fanfic.room_request.spoiler_policy"}}</span>
              <input
                maxlength="300"
                value={{this.request.spoilerPolicy}}
                {{on "input" (fn this.updateField "spoilerPolicy")}}
              />
            </label>

            <label class="ao3-room-request__field">
              <span>{{i18n "ao3_fanfic.room_request.comfort_notes"}}</span>
              <textarea
                maxlength="500"
                value={{this.request.comfortNotes}}
                {{on "input" (fn this.updateField "comfortNotes")}}
              ></textarea>
            </label>

            {{#if this.error}}
              <p class="ao3-room-request__status ao3-room-request__status--error">
                {{this.error}}
              </p>
            {{/if}}

            {{#if this.successUrl}}
              <p class="ao3-room-request__status ao3-room-request__status--success">
                {{i18n "ao3_fanfic.room_request.success"}}
                <a href={{this.successUrl}}>{{i18n "ao3_fanfic.room_request.view_request"}}</a>
              </p>
            {{/if}}

            {{#if this.supporterRequired}}
              <a
                class="btn btn-default ao3-room-request__subscribe"
                href={{this.subscribeUrl}}
                data-auto-route="true"
              >
                {{i18n "ao3_fanfic.room_request.supporter_cta"}}
              </a>
            {{/if}}

            <button
              type="submit"
              class="btn btn-primary ao3-room-request__submit"
              disabled={{this.saving}}
            >
              {{#if this.saving}}
                {{i18n "ao3_fanfic.room_request.saving"}}
              {{else}}
                {{i18n "ao3_fanfic.room_request.submit"}}
              {{/if}}
            </button>
          </form>
        {{else if this.shouldShowSupporterGate}}
          <div class="ao3-room-request__gate">
            <h4>{{i18n "ao3_fanfic.room_request.supporter_required_title"}}</h4>
            <p>{{i18n "ao3_fanfic.room_request.supporter_required_body"}}</p>
            <a
              class="btn btn-primary ao3-room-request__subscribe"
              href={{this.subscribeUrl}}
              data-auto-route="true"
            >
              {{i18n "ao3_fanfic.room_request.supporter_cta"}}
            </a>
          </div>
        {{/if}}
      {{else}}
        <div class="ao3-room-request__login">
          <p>{{i18n "ao3_fanfic.room_request.login_note"}}</p>
          <a
            href={{this.signupUrl}}
            class="btn btn-primary ao3-room-request__join"
            data-auto-route="true"
          >
            {{i18n "ao3_fanfic.room_request.join"}}
          </a>
        </div>
      {{/if}}
    </section>
  </template>
}
