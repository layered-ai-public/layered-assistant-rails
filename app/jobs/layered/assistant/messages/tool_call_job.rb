module Layered
  module Assistant
    module Messages
      # Carries out a tool call once it has been approved, or writes down the
      # refusal, then picks the response back up. Runs out of band because a
      # tool can be slow and the answer streams back like any other.
      class ToolCallJob < ApplicationJob
        queue_as :default

        def perform(message_id)
          message = Message.find(message_id)
          # Nothing to do for a call still waiting on a decision. A call that
          # is already answered is not run again, but is still passed on: a
          # retry may be here because resuming the response is what failed.
          return if message.consent_pending?

          ToolRunnerService.new.resolve(message: message)
        end
      end
    end
  end
end
