module Layered
  module Assistant
    module Authorization
      extend ActiveSupport::Concern

      included do
        include Layered::Ui::AuthenticationHelper
        before_action :layered_assistant_authorize!
      end

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
