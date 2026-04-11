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

      # Returns a tool event hash or nil.
      # Possible events:
      #   { type: :start, id: "toolu_...", name: "tool_name" }
      #   { type: :delta, json: "partial_json_string" }
      #   { type: :block_stop } (end of any content block - caller tracks whether it's a tool block)
      def tool_event(chunk)
        return nil if @openai

        case chunk["type"]
        when "content_block_start"
          block = chunk["content_block"]
          if block && block["type"] == "tool_use"
            { type: :start, id: block["id"], name: block["name"] }
          end
        when "content_block_delta"
          delta = chunk["delta"]
          if delta && delta["type"] == "input_json_delta"
            { type: :delta, json: delta["partial_json"] || "" }
          end
        when "content_block_stop"
          { type: :block_stop }
        end
      end
    end
  end
end
