import Ao3FanficThreadDetails from "discourse/plugins/discourse-ao3-fanfic-forum/discourse/components/ao3-fanfic-thread-details";

const Ao3FanficListDetails = <template>
  <Ao3FanficThreadDetails @topic={{@outletArgs.topic}} @context="list" />
</template>;

export default Ao3FanficListDetails;
