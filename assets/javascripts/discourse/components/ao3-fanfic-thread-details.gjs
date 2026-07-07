import Component from "@glimmer/component";
import { i18n } from "discourse-i18n";
import Ao3FanficTopicChips from "discourse/plugins/discourse-ao3-fanfic-forum/discourse/components/ao3-fanfic-topic-chips";

export default class Ao3FanficThreadDetails extends Component {
  get metadata() {
    return this.args.metadata || this.args.topic?.ao3_fanfic;
  }

  get visible() {
    return this.metadata?.present;
  }

  get ficLabel() {
    if (this.metadata?.fic_title && this.metadata?.fic_author) {
      return i18n("ao3_fanfic.browser.fic_by", {
        title: this.metadata.fic_title,
        author: this.metadata.fic_author,
      });
    }

    if (this.metadata?.fic_title) {
      return this.metadata.fic_title;
    }

    if (this.metadata?.fic_author) {
      return i18n("ao3_fanfic.browser.fic_author", {
        author: this.metadata.fic_author,
      });
    }

    if (this.metadata?.fic_url) {
      return i18n("ao3_fanfic.browser.fic_link");
    }

    return "";
  }

  get chapterLabel() {
    if (!this.metadata?.chapter_ref) {
      return "";
    }

    return i18n("ao3_fanfic.browser.chapter", {
      chapter: this.metadata.chapter_ref,
    });
  }

  get hasContextLine() {
    return this.ficLabel || this.chapterLabel;
  }

  <template>
    {{#if this.visible}}
      <div class="ao3-thread-details ao3-thread-details--{{@context}}">
        {{#if this.hasContextLine}}
          <div class="ao3-thread-details__context">
            {{#if this.ficLabel}}
              <span>{{this.ficLabel}}</span>
            {{/if}}
            {{#if this.chapterLabel}}
              <strong>{{this.chapterLabel}}</strong>
            {{/if}}
          </div>
        {{/if}}

        <Ao3FanficTopicChips
          @metadata={{this.metadata}}
          @context={{@context}}
        />
      </div>
    {{/if}}
  </template>
}
