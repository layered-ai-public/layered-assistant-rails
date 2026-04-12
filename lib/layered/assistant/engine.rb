module Layered
  module Assistant
    class Engine < ::Rails::Engine
      isolate_namespace Layered::Assistant

      initializer "layered-assistant-rails.autoload", before: :set_autoload_paths do |app|
        app.config.autoload_paths += [Engine.root.join("app/managed_resources").to_s]
      end

      initializer "layered-assistant-rails.managed_resource" do
        Layered::ManagedResource.managed_resource_before_action = :layered_assistant_authorize!

        ActiveSupport.on_load(:action_controller_base) do
          unless method_defined?(:layered_assistant_authorize!)
            define_method(:layered_assistant_authorize!) do
              block = Layered::Assistant.authorize_block
              unless block
                head :forbidden
                return
              end
              instance_exec(&block)
            end
            private :layered_assistant_authorize!
          end
        end
      end

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
