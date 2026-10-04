module Layered
  module Assistant
    # Messages are listed and deleted here; they are written through the
    # composer, so there are no fields and no form.
    class MessageResource < Layered::Resource::Base
      model Message

      columns [
        { attribute: :role, primary: true },
        { attribute: :content, sortable: false,
          render: ->(record, view) { view.truncate(record.content, length: 100) } },
        { attribute: :model_id, label: "Model", sortable: false,
          render: ->(record) { record.model&.name } },
        { attribute: :tokens, label: "Tokens", sortable: false,
          render: ->(record, view) {
            total = record.input_tokens.to_i + record.output_tokens.to_i
            "#{'~' if record.tokens_estimated?}#{view.number_with_delimiter(total)}" if total > 0
          } },
        { attribute: :tokens_per_second, label: "Tok/s", sortable: false,
          render: ->(record) {
            if record.output_tokens.to_i > 0 && record.response_ms.to_i >= MessagesHelper::MIN_RESPONSE_MS_FOR_TPS
              (record.output_tokens * 1000.0 / record.response_ms).round(1)
            end
          } },
        { attribute: :ttft_ms, label: "TTFT",
          render: ->(record) { "#{record.ttft_ms}ms" if record.ttft_ms } },
        { attribute: :created_at, label: "Created",
          render: ->(record) { record.created_at.to_fs(:short) } }
      ]

      search_fields [ :content ]

      default_sort attribute: :created_at, direction: :asc

      # The conversation is resolved through the engine's own scoping, so an
      # out-of-scope one 404s before any message is reached.
      def self.scope(controller)
        controller.send(:scoped, Conversation)
          .find_by!(uid: controller.params[:conversation_id])
          .messages.includes(:model)
      end
    end
  end
end
