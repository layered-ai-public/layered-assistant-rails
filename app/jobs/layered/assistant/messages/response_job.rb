module Layered
  module Assistant
    module Messages
      class ResponseJob < ApplicationJob
        queue_as :default

        def perform(message_id)
          message = Message.includes(model: :provider, conversation: [:assistant, :messages]).find(message_id)
          ResponseService.new(message).call
        end
      end
    end
  end
end
