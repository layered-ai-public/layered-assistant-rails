module Layered
  module Assistant
    module Messages
      class ResponseJob < ApplicationJob
        queue_as :default

        def perform(message_id)
          message = Message.includes(model: :provider, conversation: [ :assistant, :messages ]).find(message_id)

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
            chunk_service.mark_started!
            ClientService.new.call(message: message, stream_proc: stream_proc)
          rescue => e
            Rails.logger.error("Response generation failed: #{e.message}")
            existing = message.reload.content
            error_note = "Something went wrong while generating a response."
            message.update(content: existing.present? ? "#{existing}\n\n---\n\n#{error_note}" : error_note)
            message.broadcast_updated
          end

          return if message.reload.stopped?

          # A response that asked for tools is not finished: the tools run and
          # a fresh assistant message picks the answer back up, so the composer
          # stays disabled until that one completes.
          if message.tool_calls.any?
            ToolRunnerService.new.call(message: message)
          else
            message.broadcast_response_complete
          end
        end
      end
    end
  end
end
