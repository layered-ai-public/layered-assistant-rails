module Layered
  module Assistant
    class ConversationResource < Layered::Resource::Base
      model Conversation

      # Conversations are addressed by uid, not id.
      lookup_attribute :uid

      columns [
        # The name links to the conversation itself, not its edit form.
        { attribute: :name, primary: true, link: false,
          render: ->(record, view) {
            view.link_to(record.name, view.layered_assistant.conversation_path(record),
                         data: { turbo_frame: "_top" })
          } },
        { attribute: :assistant_id, label: "Assistant", sortable: false,
          render: ->(record, view) {
            view.link_to(record.assistant.name,
                         view.layered_assistant.assistant_conversations_path(record.assistant),
                         data: { turbo_frame: "_top" })
          } },
        { attribute: :messages_count, label: "Messages",
          render: ->(record, view) {
            view.link_to(record.messages_count.to_i,
                         view.layered_assistant.conversation_messages_path(record),
                         data: { turbo_frame: "_top" })
          } },
        { attribute: :token_estimate, label: "Tokens",
          render: ->(record, view) { view.number_with_delimiter(record.token_estimate.to_i) } },
        # The person who did the talking, which is the owner itself until an
        # owner block scopes ownership elsewhere. Neither is set for an
        # anonymous visitor on a public assistant.
        { attribute: :user_id, label: "User", sortable: false,
          render: ->(record) { record.user.try(:name) || record.owner.try(:name) || "Guest" } },
        { attribute: :created_at, label: "Created",
          render: ->(record) { record.created_at.to_fs(:short) } }
      ]

      search_fields [ :name ]

      default_sort attribute: :created_at, direction: :desc

      # `assistant_id` carries no collection here: the options have to be
      # scoped to the owner, which only the controller can resolve.
      # ConversationsController fills them in per request, and drops the
      # field once the conversation exists - its assistant is fixed.
      fields [
        { attribute: :assistant_id, label: "Assistant", as: :select, include_blank: "Select an assistant:", required: true },
        # Left blank, the name is set from the first message, so the form
        # must not insist on one even though the model does.
        { attribute: :name, required: false, hint: "Auto-set from first message if left blank" }
      ]

      # Nested under an assistant, only that assistant's conversations are
      # listed, and an out-of-scope assistant 404s before any are reached.
      def self.scope(controller)
        scope = controller.send(:scoped, Conversation)
        if (assistant_id = controller.params[:assistant_id])
          scope = scope.where(assistant: controller.send(:scoped, Assistant).find(assistant_id))
        end
        scope.includes(:assistant, :owner, :user)
      end

      # Started from an assistant's conversations, the assistant is chosen
      # already - resolved through `scoped` so an out-of-scope one 404s.
      def self.build_record(controller)
        assistant_id = controller.params[:assistant_id]

        Conversation.new(
          owner: controller.send(:current_owner!),
          user: controller.send(:current_conversation_user),
          assistant: (controller.send(:scoped, Assistant).find(assistant_id) if assistant_id)
        )
      end

      # A new conversation opens straight into the chat; edits and deletes
      # return to the list they were made from.
      def self.after_save_path(controller, record)
        if controller.action_name == "create"
          controller.layered_assistant.conversation_path(record)
        else
          controller.layered_assistant.conversations_path
        end
      end
    end
  end
end
