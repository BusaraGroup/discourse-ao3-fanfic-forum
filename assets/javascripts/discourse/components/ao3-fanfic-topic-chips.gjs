import Component from "@glimmer/component";
import { i18n } from "discourse-i18n";

export default class Ao3FanficTopicChips extends Component {
  get metadata() {
    return this.args.metadata || this.args.topic?.ao3_fanfic;
  }

  get visible() {
    return this.metadata?.present;
  }

  get typeLabel() {
    return i18n(`ao3_fanfic.discussion_types.${this.metadata.discussion_type}`);
  }

  get fandomTags() {
    return this.metadata.fandom_tags || [];
  }

  get shipTags() {
    return this.metadata.ship_tags || [];
  }

  get contentWarnings() {
    return this.metadata.content_warnings || [];
  }

  <template>
    {{#if this.visible}}
      <div class="ao3-topic-chips ao3-topic-chips--{{@context}}">
        <span
          class="ao3-topic-chip ao3-topic-chip--type"
        >{{this.typeLabel}}</span>

        {{#each this.fandomTags as |tag|}}
          <span class="ao3-topic-chip ao3-topic-chip--fandom">{{tag}}</span>
        {{/each}}

        {{#each this.shipTags as |tag|}}
          <span class="ao3-topic-chip ao3-topic-chip--ship">{{tag}}</span>
        {{/each}}

        {{#if this.metadata.spoiler_label}}
          <span class="ao3-topic-chip ao3-topic-chip--spoiler">
            {{i18n "ao3_fanfic.chips.spoiler"}}:
            {{this.metadata.spoiler_label}}
          </span>
        {{/if}}

        {{#each this.contentWarnings as |warning|}}
          <span
            class="ao3-topic-chip ao3-topic-chip--warning"
          >{{warning}}</span>
        {{/each}}
      </div>
    {{/if}}
  </template>
}
