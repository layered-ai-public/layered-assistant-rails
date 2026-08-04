module Layered
  module Assistant
    class ChunkParser
      def initialize(protocol)
        @openai = protocol == "openai"
      end

      def text(chunk)
        t = if @openai
          chunk.dig("choices", 0, "delta", "content")
        else
          chunk.dig("delta", "text") if chunk["type"] == "content_block_delta"
        end
        t unless t.nil? || t.empty?
      end

      # Some models stream their whole reply in the reasoning field and leave
      # content empty (DeepSeek via OpenRouter does this). Kept apart from
      # #text so reasoning is only ever shown when no content arrives at all.
      def reasoning(chunk)
        return unless @openai

        r = chunk.dig("choices", 0, "delta", "reasoning")
        r unless r.nil? || r.empty?
      end

      # The model that actually served the request. Usually the one that was
      # asked for, but routers (e.g. OpenRouter's Auto Router) resolve to a
      # different model per request.
      def model(chunk)
        m = if @openai
          chunk["model"]
        else
          chunk.dig("message", "model") if chunk["type"] == "message_start"
        end
        m unless m.nil? || m.empty?
      end

      def finished?(chunk)
        if @openai
          chunk.dig("choices", 0, "finish_reason").present?
        else
          chunk["type"] == "message_stop"
        end
      end

      # Usage arrives on a final chunk with no choices (OpenAI, Fireworks) or
      # on the finish_reason chunk itself (OpenRouter), so accept either.
      def usage_ready?(chunk)
        return false unless @openai
        return false if chunk["usage"].blank?

        choices = chunk["choices"]
        choices.blank? || choices.first&.dig("finish_reason").present?
      end

      def input_tokens(chunk)
        if @openai
          chunk.dig("usage", "prompt_tokens")&.to_i if usage_ready?(chunk)
        elsif chunk["type"] == "message_start"
          chunk.dig("message", "usage", "input_tokens")&.to_i
        end
      end

      def output_tokens(chunk)
        if @openai
          chunk.dig("usage", "completion_tokens")&.to_i if usage_ready?(chunk)
        elsif chunk["type"] == "message_delta"
          chunk.dig("usage", "output_tokens")&.to_i
        end
      end
    end
  end
end
