import Ao3FanficTopicChips from "discourse/plugins/discourse-ao3-fanfic-forum/discourse/components/ao3-fanfic-topic-chips";

const Ao3FanficTopicMetadata = <template>
  <Ao3FanficTopicChips @topic={{@outletArgs.model}} @context="topic" />
</template>;

export default Ao3FanficTopicMetadata;
