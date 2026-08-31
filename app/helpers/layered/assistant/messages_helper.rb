module Layered
  module Assistant
    module MessagesHelper
      MIN_RESPONSE_MS_FOR_TPS = 100

      # Routers such as OpenRouter's Auto Router pick a model per request, so
      # the model that answered is not always the one that was asked for. Name
      # both when they differ.
      def message_model_label(message)
        name = message.model.name
        resolved = message.resolved_model
        return name if resolved.blank? || resolved.casecmp?(message.model.identifier)

        "#{name} · #{resolved}"
      end

      # An assistant message that only asked for tools has nothing of its own to
      # show - the tool messages that follow it report what happened - so its
      # bubble is left out entirely.
      def message_tool_request?(message)
        message.assistant? && message.content.blank? && message.tool_calls.any?
      end

      # Tool arguments and results are JSON in all but the simplest cases.
      # Pretty-print what parses and show the rest as it came.
      def tool_payload(payload)
        return "" if payload.blank?

        JSON.pretty_generate(JSON.parse(payload))
      rescue JSON::ParserError
        payload
      end

      def message_metadata_title(message)
        total_tokens = message.input_tokens.to_i + message.output_tokens.to_i
        parts = []
        if total_tokens > 0
          prefix = message.tokens_estimated? ? "~" : ""
          parts << "#{prefix}#{number_with_delimiter(total_tokens)} tokens"
        end
        if message.output_tokens.to_i > 0 && message.response_ms.to_i >= MIN_RESPONSE_MS_FOR_TPS
          tps = (message.output_tokens * 1000.0 / message.response_ms).round(1)
          parts << "#{tps} tok/s"
        end
        parts << "#{message.ttft_ms}ms TTFT" if message.ttft_ms
        parts.join(" · ")
      end
    end
  end
end
