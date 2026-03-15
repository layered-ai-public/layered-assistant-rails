module Layered
  module Assistant
    class ChunkService
      STOP_CHECK_INTERVAL = 5

      def initialize(message, provider:)
        @message = message
        @provider = provider
        @input_tokens = 0
        @output_tokens = 0
        @chunk_count = 0
        @stopped = false
      end

      def call(chunk)
        return if @stopped

        @chunk_count += 1
        if @chunk_count % STOP_CHECK_INTERVAL == 0
          @stopped = @message.reload.stopped?
          return if @stopped
        end

        Rails.logger.debug { "[ChunkService] #{chunk.inspect}" }
        text = extract_text(chunk)
        extract_usage(chunk)

        if text
          @message.update(content: (@message.content || "") + text)
          @message.broadcast_chunk(text)
        end

        if chunk_finished?(chunk) || usage_chunk?(chunk)
          save_token_usage
          @message.broadcast_updated
          @message.broadcast_response_complete
        end
      end

      private

      def extract_text(chunk)
        text = if @provider.protocol == "openai"
          chunk.dig("choices", 0, "delta", "content")
        else
          chunk.dig("delta", "text") if chunk["type"] == "content_block_delta"
        end
        text unless text.nil? || text.empty?
      end

      def chunk_finished?(chunk)
        if @provider.protocol == "openai"
          chunk.dig("choices", 0, "finish_reason").present?
        else
          chunk["type"] == "message_stop"
        end
      end

      def usage_chunk?(chunk)
        @provider.protocol == "openai" && chunk["usage"].present? && chunk.dig("choices")&.empty?
      end

      def extract_usage(chunk)
        if @provider.protocol == "openai"
          if (usage = chunk["usage"])
            @input_tokens = usage["prompt_tokens"].to_i
            @output_tokens = usage["completion_tokens"].to_i
          end
        else
          if chunk["type"] == "message_start" && (usage = chunk.dig("message", "usage"))
            @input_tokens = usage["input_tokens"].to_i
          end
          if chunk["type"] == "message_delta" && (usage = chunk["usage"])
            @output_tokens = usage["output_tokens"].to_i
          end
        end
      end

      def save_token_usage
        if @input_tokens == 0 && @output_tokens == 0
          estimated = TokenEstimator.estimate(@message.content)
          return unless estimated

          @message.update!(output_tokens: estimated, tokens_estimated: true)
        else
          @message.update!(input_tokens: @input_tokens, output_tokens: @output_tokens)
        end

        @message.conversation.update_token_totals!
      end
    end
  end
end
