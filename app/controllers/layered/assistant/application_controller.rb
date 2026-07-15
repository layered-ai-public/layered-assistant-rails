module Layered
  module Assistant
    class ApplicationController < ActionController::Base
      include Pagy::Method
      include Layered::Ui::AuthenticationHelper

      before_action :layered_assistant_authorize!

      helper Rails.application.routes.url_helpers

      private

      # The record ownership is stamped with on create and filtered by on
      # reads. Override to scope records to something other than the
      # signed-in user (e.g. their organisation).
      def current_owner
        l_ui_current_user
      end

      def scoped(model_class)
        model_class.owned_by(current_owner)
      end

      def layered_assistant_authorize!
        block = Layered::Assistant.authorize_block

        unless block
          head :forbidden
          return
        end

        instance_exec(&block)
      end
    end
  end
end
