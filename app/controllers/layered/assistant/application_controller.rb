module Layered
  module Assistant
    class ApplicationController < ActionController::Base
      include Pagy::Method
      include Layered::Ui::AuthenticationHelper

      before_action :layered_assistant_authorize!

      helper Rails.application.routes.url_helpers

      private

      # The record ownership is stamped with on create and filtered by on
      # reads. Configure an owner block in the initialiser to scope records
      # to something other than the signed-in user (e.g. their organisation).
      def current_owner
        block = Layered::Assistant.owner_block

        block ? instance_exec(&block) : l_ui_current_user
      end

      # Owner stamping on create goes through this bang variant: persisting
      # a record with a nil owner would leave it invisible to every scoped
      # read, so a missing owner fails loudly instead.
      def current_owner!
        current_owner || raise(MissingOwnerError, "current_owner is nil - the authorize block admitted a request without a signed-in user, or the owner block returned nil")
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
