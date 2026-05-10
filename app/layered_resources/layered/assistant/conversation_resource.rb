module Layered
  module Assistant
    class ConversationResource < ResourceBase
      model Layered::Assistant::Conversation

      columns [
        {
          attribute: :name,
          primary: true,
          render: ->(record, view) {
            view.link_to(record.name, view.layered_assistant.conversation_path(record), data: { turbo_frame: "_top" })
          }
        },
        {
          attribute: :assistant_id,
          label: "Assistant",
          sortable: false,
          render: ->(record, view) {
            view.link_to(record.assistant.name, view.layered_assistant.assistant_conversations_path(record.assistant), data: { turbo_frame: "_top" })
          }
        },
        {
          attribute: :messages_count,
          label: "Messages",
          render: ->(record, view) {
            view.link_to(
              view.tag.span(record.messages_count.to_i, class: "l-ui-badge--default l-ui-badge--rounded"),
              view.layered_assistant.conversation_messages_path(record),
              data: { turbo_frame: "_top" }
            )
          }
        },
        {
          attribute: :token_estimate,
          label: "Tokens",
          render: ->(record, view) {
            view.tag.span(view.number_with_delimiter(record.token_estimate.to_i), class: "l-ui-badge--default l-ui-badge--rounded")
          }
        },
        {
          attribute: :owner_id,
          label: "User",
          sortable: false,
          render: ->(record) { record.owner.try(:name) || "Guest" }
        },
        {
          attribute: :created_at,
          label: "Created",
          render: ->(record) { record.created_at.to_fs(:short) }
        }
      ]

      fields [
        { attribute: :name },
        { attribute: :assistant_id }
      ]

      search_fields [ :name ]
      default_sort attribute: :created_at, direction: :desc

      def self.scope(controller)
        base = super
        if controller.params[:assistant_id].present?
          assistant = Layered::Assistant::Assistant
            .owned_by(controller.l_ui_current_user)
            .find(controller.params[:assistant_id])
          base.where(assistant: assistant)
        else
          base
        end
      end
    end
  end
end
