import { ajax } from "discourse/lib/ajax";
import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "ao3-fanfic-forum",

  initialize(container) {
    const siteSettings = container.lookup("service:site-settings");

    if (!siteSettings.ao3_fanfic_enabled) {
      return;
    }

    withPluginApi((api) => {
      api.addTrackedTopicProperties("ao3_fanfic");
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
    });
  },
};
