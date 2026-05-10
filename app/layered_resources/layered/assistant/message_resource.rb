module Layered
  module Assistant
    class MessageResource < Layered::Resource::Base
      model Layered::Assistant::Message

      columns [
        { attribute: :role, primary: true },
        {
          attribute: :content,
          sortable: false,
          render: ->(record, view) { view.truncate(record.content.to_s, length: 100) }
        },
        {
          attribute: :model_id,
          label: "Model",
          sortable: false,
          render: ->(record) { record.model&.name }
        },
        {
          attribute: :total_tokens,
          label: "Tokens",
          sortable: false,
          render: ->(record, view) {
            next if record.total_tokens.zero?

            label = "#{record.tokens_estimated? ? '~' : ''}#{view.number_with_delimiter(record.total_tokens)}"
            view.tag.span(label, class: "l-ui-badge--default l-ui-badge--rounded")
          }
        },
        {
          attribute: :tokens_per_second,
          label: "Tok/s",
          sortable: false,
          render: ->(record, view) {
            next unless record.tokens_per_second

            view.tag.span(record.tokens_per_second, class: "l-ui-badge--default l-ui-badge--rounded")
          }
        },
        {
          attribute: :ttft_ms,
          label: "TTFT",
          render: ->(record, view) {
            next unless record.ttft_ms

            view.tag.span("#{record.ttft_ms}ms", class: "l-ui-badge--default l-ui-badge--rounded")
          }
        },
        {
          attribute: :created_at,
          label: "Created",
          render: ->(record) { record.created_at.to_fs(:short) }
        }
      ]

      default_sort attribute: :created_at, direction: :asc

      def self.scope(controller)
        parent_conversation(controller).messages.includes(:model)
      end

      def self.parent_conversation(controller)
        Layered::Assistant::Conversation
          .owned_by(controller.l_ui_current_user)
          .find(controller.params[:conversation_id])
      end
    end
  end
end
