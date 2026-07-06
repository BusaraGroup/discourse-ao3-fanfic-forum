import Ao3AuthPanel from "discourse/plugins/discourse-ao3-fanfic-forum/discourse/components/ao3-auth-panel";
import routeAction from "discourse/helpers/route-action";

const Ao3LoginAuthPanel = <template>
  <Ao3AuthPanel
    @mode="login"
    @accountAction={{routeAction "showCreateAccount"}}
  />
</template>;

export default Ao3LoginAuthPanel;
