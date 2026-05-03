module Layered
  module Assistant
    class Engine < ::Rails::Engine
      isolate_namespace Layered::Assistant

      initializer "layered-assistant-rails.inflections", before: :set_autoload_paths do
        ActiveSupport::Inflector.inflections do |inflect|
          inflect.acronym "OpenAI"
        end
      end

      initializer "layered-assistant-rails.importmap", before: "importmap" do |app|
        app.config.importmap.paths << Engine.root.join("config/importmap.rb")
      end

      initializer "layered-assistant-rails.assets" do |app|
        app.config.assets.paths << Engine.root.join("app/javascript")
        app.config.assets.paths << Engine.root.join("app/assets/images")
      end

      initializer "layered-assistant-rails.helpers" do
        ActiveSupport.on_load(:action_controller_base) do
          helper Layered::Assistant::AccessHelper
          helper Layered::Assistant::MessagesHelper
          helper Layered::Assistant::PanelHelper
        end
      end
    end
  end
end
