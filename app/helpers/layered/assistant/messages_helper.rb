module Layered
  module Assistant
    module MessagesHelper
      MIN_RESPONSE_MS_FOR_TPS = 100

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
