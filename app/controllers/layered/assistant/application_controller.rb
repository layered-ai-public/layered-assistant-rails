module Layered
  module Assistant
    class ApplicationController < ActionController::Base
      include Pagy::Method
      include Layered::Ui::AuthenticationHelper

      before_action :layered_assistant_authorize!

      helper Rails.application.routes.url_helpers

      private

      def layered_assistant_authorize!
        block = Layered::Assistant.authorize_block

        unless block
          head :forbidden
          return
        end

        instance_exec(&block)
      end

      def scoped(model_class)
        block = Layered::Assistant.scope_block
        return model_class.all unless block

        result = instance_exec(model_class, &block)
        unless result.is_a?(ActiveRecord::Relation)
          raise ArgumentError,
            "Layered::Assistant.scope must return an ActiveRecord::Relation, got #{result.class}"
        end
        result
      end
    end
  end
end
