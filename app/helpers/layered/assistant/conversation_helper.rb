module Layered
  module Assistant
    module ConversationHelper
      # Renders a conversation - its messages and composer - anywhere in a
      # host app view, such as the main viewport:
      #
      #   <%= layered_assistant_conversation(@conversation) %>
      #
      # The host is responsible for loading the conversation through its own
      # scoping. The models offered in the composer are those available to
      # the conversation's owner. Wrap it in +l-ui-conversation__container+
      # for the standard layout.
      #
      # Live updates are broadcast to CSS classes rather than element ids, so
      # the same conversation can be shown here and in the panel at once.
      def layered_assistant_conversation(conversation)
        messages = conversation.messages.includes(:model).by_created_at
        models = Model.available.merge(Provider.owned_by(conversation.owner))
        selected_model_id = messages.last&.model_id || conversation.assistant.default_model_id || models.first&.id

        render "layered/assistant/conversations/conversation",
          conversation: conversation,
          messages: messages,
          models: models,
          selected_model_id: selected_model_id
      end
    end
  end
end
