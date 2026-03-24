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

      def finished?(chunk)
        if @openai
          chunk.dig("choices", 0, "finish_reason").present?
        else
          chunk["type"] == "message_stop"
        end
      end

      def usage_ready?(chunk)
        @openai && chunk["usage"].present? && chunk.dig("choices")&.empty?
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
