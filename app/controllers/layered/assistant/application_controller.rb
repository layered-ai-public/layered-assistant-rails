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
    end
  end
end
