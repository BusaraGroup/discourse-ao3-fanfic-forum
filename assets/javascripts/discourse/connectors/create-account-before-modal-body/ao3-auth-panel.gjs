import Ao3AuthPanel from "discourse/plugins/discourse-ao3-fanfic-forum/discourse/components/ao3-auth-panel";
import routeAction from "discourse/helpers/route-action";

const Ao3SignupAuthPanel = <template>
  <Ao3AuthPanel
    @mode="signup"
    @accountAction={{routeAction "showLogin"}}
  />
</template>;

export default Ao3SignupAuthPanel;
