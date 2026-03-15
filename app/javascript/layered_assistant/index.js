import { application } from "controllers/application"
import ComposerController from "layered_assistant/composer_controller"
import MessagesController from "layered_assistant/messages_controller"
import PanelController from "layered_assistant/panel_controller"
import PanelNavController from "layered_assistant/panel_nav_controller"
import ProviderTemplateController from "layered_assistant/provider_template_controller"

application.register("composer", ComposerController)
application.register("messages", MessagesController)
application.register("panel", PanelController)
application.register("panel-nav", PanelNavController)
application.register("provider-template", ProviderTemplateController)

import "layered_assistant/message_streaming"
