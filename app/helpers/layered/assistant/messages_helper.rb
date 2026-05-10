module Layered
  module Assistant
    module MessagesHelper
      def message_metadata_title(message)
        parts = []
        if message.total_tokens > 0
          prefix = message.tokens_estimated? ? "~" : ""
          parts << "#{prefix}#{number_with_delimiter(message.total_tokens)} tokens"
        end
        if (tps = message.tokens_per_second)
          parts << "#{tps} tok/s"
        end
        parts << "#{message.ttft_ms}ms TTFT" if message.ttft_ms
        parts.join(" · ")
      end
    end
  end
end
