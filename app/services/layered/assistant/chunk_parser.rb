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
      # Anthropic thinking blocks are not covered here; they always come
      # alongside content, so there is nothing to fall back to.
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

      # Fragments of the tool calls the model is asking for, or nil when the
      # chunk carries none. Both protocols stream a call as an opening
      # fragment naming the tool followed by its arguments as JSON string
      # fragments; `key` is what ties the fragments of one call together.
      def tool_calls(chunk)
        @openai ? openai_tool_calls(chunk) : anthropic_tool_calls(chunk)
      end

      private

      def openai_tool_calls(chunk)
        calls = chunk.dig("choices", 0, "delta", "tool_calls")
        return if calls.blank?

        calls.map do |call|
          {
            key: call["index"] || 0,
            id: call["id"],
            name: call.dig("function", "name"),
            arguments: call.dig("function", "arguments")
          }
        end
      end

      def anthropic_tool_calls(chunk)
        case chunk["type"]
        when "content_block_start"
          block = chunk["content_block"]
          return unless block && block["type"] == "tool_use"

          [ { key: chunk["index"], id: block["id"], name: block["name"] } ]
        when "content_block_delta"
          delta = chunk["delta"]
          return unless delta && delta["type"] == "input_json_delta"

          [ { key: chunk["index"], arguments: delta["partial_json"] } ]
        end
      end
    end
  end
end
