module Layered
  module Assistant
    module Public
      class ApplicationController < Layered::Assistant::ApplicationController
        skip_before_action :layered_assistant_authorize!
        include SessionConversations

        private

        def set_public_assistant
          @assistant = Assistant.publicly_available.find(params[:assistant_id] || params[:id])
        end
      end
    end
  end
end
