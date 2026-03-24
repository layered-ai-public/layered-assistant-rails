module Layered
  module Assistant
    class ChunkService
      STOP_CHECK_INTERVAL = 25

      def initialize(message, provider:, started_at: nil)
        @message = message
        @parser = ChunkParser.new(provider.protocol)
        @timer = ResponseTimer.new
        @timer.start! if started_at
        @input_tokens = 0
        @output_tokens = 0
        @chunk_count = 0
        @stopped = false
      end

      def mark_started!
        @timer.start!
      end

      def call(chunk)
        return if @stopped

        @chunk_count += 1
        if @chunk_count % STOP_CHECK_INTERVAL == 0
          @stopped = @message.reload.stopped?
          if @stopped
            attrs = @timer.timing_attrs
            unless attrs.empty?
              @message.update!(attrs)
              @message.broadcast_updated
            end
            return
          end
        end

        Rails.logger.debug { "[ChunkService] #{chunk.inspect}" }
        text = @parser.text(chunk)
        @input_tokens  = @parser.input_tokens(chunk)  || @input_tokens
        @output_tokens = @parser.output_tokens(chunk) || @output_tokens

        if text
          @timer.record_first_token!
          @message.update!(content: (@message.content || "") + text)
          @message.broadcast_chunk(text)
        end

        if @parser.finished?(chunk) || @parser.usage_ready?(chunk)
          save_token_usage
          @message.broadcast_updated
        end
      end

      private

      def save_token_usage
        timing = @timer.timing_attrs
        if @input_tokens == 0 && @output_tokens == 0
          estimated = TokenEstimator.estimate(@message.content)
          return unless estimated

          @message.update!(output_tokens: estimated, tokens_estimated: true, **timing)
        else
          @message.update!(input_tokens: @input_tokens, output_tokens: @output_tokens, **timing)
        end

        @message.conversation.update_token_totals!
      end
    end
  end
end
