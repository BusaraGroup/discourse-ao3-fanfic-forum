import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import { i18n } from "discourse-i18n";
import Ao3FanficHome from "discourse/plugins/discourse-ao3-fanfic-forum/discourse/connectors/discovery-list-container-top/ao3-fanfic-home";
import Ao3FanficRoom from "discourse/plugins/discourse-ao3-fanfic-forum/discourse/connectors/discovery-list-container-top/ao3-fanfic-room";

module("Integration | Connector | AO3 fanfic discovery", function (hooks) {
  setupRenderingTest(hooks);

  test("the discovery homepage is limited to unscoped topic lists", function (assert) {
    const context = { siteSettings: { ao3_fanfic_enabled: true } };
    const owner = {
      lookup() {
        return { currentURL: "/" };
      },
    };

    assert.true(
      Ao3FanficHome.shouldRender({}, context, owner),
      "the homepage renders at the site root"
    );
    assert.false(
      Ao3FanficHome.shouldRender({ category: { id: 7 } }, context, owner),
      "the homepage does not render inside a room"
    );
    assert.false(
      Ao3FanficHome.shouldRender({ tag: { id: "dramione" } }, context, owner),
      "the homepage does not render on a tag list"
    );

    owner.lookup = () => ({ currentURL: "/latest" });
    assert.false(
      Ao3FanficHome.shouldRender({}, context, owner),
      "the homepage does not render on other topic lists"
    );
  });

  test("a room displays its identity and scoped search", async function (assert) {
    this.set("outletArgs", {
      category: {
        descriptionText: "Discuss stories and recommendations.",
        displayName: "Harry Potter",
        topic_count: 12,
        url: "/c/harry-potter/7",
      },
    });

    await render(
      <template><Ao3FanficRoom @outletArgs={{this.outletArgs}} /></template>
    );

    assert
      .dom(".ao3-room h1")
      .hasText("Harry Potter", "the room name is shown");
    assert
      .dom(".ao3-room__identity p")
      .hasText(
        "Discuss stories and recommendations.",
        "the room description is shown"
      );
    assert
      .dom(".ao3-room__count")
      .hasText(
        i18n("ao3_fanfic.room.discussion_count", { count: 12 }),
        "the discussion count is shown"
      );
    assert
      .dom('.ao3-room__search input[name="search"]')
      .hasAttribute("type", "search", "the room has a search field");
    assert
      .dom(".ao3-room__search")
      .hasAttribute("method", "get", "search uses the category topic filter");
  });
});
