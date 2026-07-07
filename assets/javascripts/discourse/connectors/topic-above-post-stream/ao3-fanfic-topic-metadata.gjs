import Ao3FanficThreadDetails from "discourse/plugins/discourse-ao3-fanfic-forum/discourse/components/ao3-fanfic-thread-details";

const Ao3FanficTopicMetadata = <template>
  <Ao3FanficThreadDetails @topic={{@outletArgs.model}} @context="topic" />
</template>;

export default Ao3FanficTopicMetadata;
