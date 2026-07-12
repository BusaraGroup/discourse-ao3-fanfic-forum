import { ajax } from "discourse/lib/ajax";
import getURL, { withoutPrefix } from "discourse/lib/get-url";
import { withPluginApi } from "discourse/lib/plugin-api";

const SERVER_RENDERED_LINK_SELECTOR = "a[href]";
const CREATE_ACCOUNT_BUTTON_SELECTOR = ".sign-up-button";
const LOGIN_BUTTON_SELECTOR = ".login-button";
const SERVER_RENDERED_PATHS = new Set([
  "/ao3-fanfic/account",
  "/ao3-fanfic/login",
  "/ao3-fanfic/password-reset",
  "/ao3-fanfic/signup",
  "/ao3-fanfic/supporter",
]);
let serverNavigationBound = false;

function isServerRenderedPath(url) {
  if (!url) {
    return false;
  }

  try {
    const parsed = new URL(url, window.location.origin);

    return (
      parsed.origin === window.location.origin &&
      SERVER_RENDERED_PATHS.has(withoutPrefix(parsed.pathname))
    );
  } catch {
    return false;
  }
}

function redirectToServerPath(path) {
  window.location.assign(getURL(path));
}

function forceServerNavigation(event) {
  if (
    event.defaultPrevented ||
    event.button !== 0 ||
    event.metaKey ||
    event.altKey ||
    event.ctrlKey ||
    event.shiftKey
  ) {
    return;
  }

  const target = event.target;
  if (!(target instanceof Element)) {
    return;
  }

  if (target.closest(LOGIN_BUTTON_SELECTOR)) {
    event.preventDefault();
    event.stopPropagation();
    redirectToServerPath("/ao3-fanfic/login");
    return;
  }

  if (target.closest(CREATE_ACCOUNT_BUTTON_SELECTOR)) {
    event.preventDefault();
    event.stopPropagation();
    redirectToServerPath("/ao3-fanfic/signup");
    return;
  }

  const link = target.closest(SERVER_RENDERED_LINK_SELECTOR);
  if (!link || !isServerRenderedPath(link.href)) {
    return;
  }

  event.preventDefault();
  event.stopPropagation();
  window.location.assign(link.href);
}

function bindServerNavigation() {
  if (serverNavigationBound) {
    return;
  }

  serverNavigationBound = true;
  document.addEventListener("click", forceServerNavigation, true);
}

export default {
  name: "ao3-fanfic-forum",

  initialize(container) {
    const siteSettings = container.lookup("service:site-settings");

    if (!siteSettings.ao3_fanfic_enabled) {
      return;
    }

    withPluginApi((api) => {
      api.addTrackedTopicProperties("ao3_fanfic");
      api.registerValueTransformer(
        "full-page-refresh-on-navigation",
        ({ value, context }) => {
          return isServerRenderedPath(context?.url) ? true : value;
        }
      );
      api.modifyClass(
        "route:application",
        (Superclass) =>
          class extends Superclass {
            showLogin() {
              redirectToServerPath("/ao3-fanfic/login");
            }

            showCreateAccount() {
              redirectToServerPath("/ao3-fanfic/signup");
            }
          }
      );
      api.modifyClass(
        "route:login",
        (Superclass) =>
          class extends Superclass {
            beforeModel() {
              redirectToServerPath("/ao3-fanfic/login");
            }
          }
      );
      api.modifyClass(
        "route:signup",
        (Superclass) =>
          class extends Superclass {
            beforeModel() {
              redirectToServerPath("/ao3-fanfic/signup");
            }
          }
      );
      api.serializeOnCreate(
        "topic_custom_fields",
        "ao3Fanfic.topicCustomFields"
      );
      api.serializeToDraft("ao3_fanfic_draft", "ao3Fanfic");

      api.modifyClass(
        "model:composer",
        (Superclass) =>
          class extends Superclass {
            editPost(opts) {
              const shouldSaveAo3Metadata = this.editingFirstPost;
              const topic = this.topic;
              const topicId = topic?.id;
              const fields = this.ao3Fanfic?.topicCustomFields;

              return super.editPost(opts).then((result) => {
                if (!shouldSaveAo3Metadata || !topicId || !fields) {
                  return result;
                }

                return ajax(`/ao3-fanfic/topics/${topicId}/metadata.json`, {
                  type: "PUT",
                  data: JSON.stringify({ topic_custom_fields: fields }),
                  contentType: "application/json",
                }).then((payload) => {
                  topic.set("ao3_fanfic", payload.ao3_fanfic);
                  return result;
                });
              });
            }
          }
      );

      bindServerNavigation();
    });

    bindServerNavigation();
  },
};
