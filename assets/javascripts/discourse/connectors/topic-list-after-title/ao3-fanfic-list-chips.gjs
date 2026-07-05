import Ao3FanficTopicChips from "discourse/plugins/discourse-ao3-fanfic-forum/discourse/components/ao3-fanfic-topic-chips";

const Ao3FanficListChips = <template>
  <Ao3FanficTopicChips @topic={{@outletArgs.topic}} @context="list" />
</template>;

export default Ao3FanficListChips;
