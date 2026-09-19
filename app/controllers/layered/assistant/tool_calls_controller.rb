module Layered
  module Assistant
    # Approving or declining a tool call that asked for consent before it ran.
    class ToolCallsController < ApplicationController
      DECISIONS = { "approve" => "approved", "decline" => "declined" }.freeze

      before_action :set_conversation

      def update
        status = DECISIONS[params[:decision]]
        return head :unprocessable_entity unless status

        message = @conversation.messages.find(params[:id])

        # Conditional so that two decisions arriving at once cannot both win,
        # and so a second click or a stale tab changes nothing.
        decided = Message.where(id: message.id, tool_status: "pending")
          .update_all(tool_status: status, updated_at: Time.current)
        return head :no_content if decided.zero?

        message.reload.broadcast_updated
        Messages::ToolCallJob.perform_later(message.id)

        head :no_content
      end

      private

      def set_conversation
        @conversation = scoped(Conversation).find_by!(uid: params[:conversation_id])
      end
    end
  end
end
