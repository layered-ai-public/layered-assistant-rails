module Layered
  module Assistant
    module Messages
      class ResponseJob < ApplicationJob
        queue_as :default

        def perform(message_id)
          message = Message.includes(model: :provider, conversation: [:assistant, :messages]).find(message_id)

          unless message.model&.provider
            message.update(content: "No provider is configured for this model.")
            message.broadcast_updated
            message.broadcast_response_complete
            return
          end

          provider = message.model.provider
          chunk_service = ChunkService.new(message, provider: provider)

          stream_proc = proc do |chunk, _bytesize|
            chunk_service.call(chunk)
          end

          begin
            ClientService.new.call(message: message, stream_proc: stream_proc)
          rescue => e
            Rails.logger.error("Response generation failed: #{e.message}")
            existing = message.reload.content
            error_note = "Something went wrong while generating a response."
            message.update(content: existing.present? ? "#{existing}\n\n---\n\n#{error_note}" : error_note)
            message.broadcast_updated
          end

          message.broadcast_response_complete unless message.reload.stopped?
        end
      end
    end
  end
end
