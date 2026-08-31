module Layered
  module Assistant
    class ChunkService
      STOP_CHECK_INTERVAL = 25
      BROADCAST_INTERVAL_MS = 25

      def initialize(message, provider:, started_at: nil)
        @message = message
        @parser = ChunkParser.new(provider.protocol)
        @timer = ResponseTimer.new
        @timer.start! if started_at
        @input_tokens = 0
        @output_tokens = 0
        @resolved_model = nil
        @reasoning = +""
        @tool_calls = ToolCallAccumulator.new
        @chunk_count = 0
        @stopped = false
        @last_broadcast_at = 0
        @broadcast_pending = false
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
            attrs = @timer.timing_attrs.merge(resolved_model_attrs)
            unless attrs.empty?
              @message.update!(**attrs)
              @message.broadcast_updated
            end
            return
          end
        end

        Rails.logger.debug { "[ChunkService] #{chunk.inspect}" }
        text = @parser.text(chunk)
        @input_tokens  = @parser.input_tokens(chunk)  || @input_tokens
        @output_tokens = @parser.output_tokens(chunk) || @output_tokens
        @resolved_model = @parser.model(chunk) || @resolved_model

        # Reasoning tokens are output tokens, so they set TTFT just as text does.
        if (reasoning = @parser.reasoning(chunk))
          @timer.record_first_token!
          @reasoning << reasoning
        end

        if (fragments = @parser.tool_calls(chunk))
          @timer.record_first_token!
          fragments.each { |fragment| @tool_calls.add(**fragment) }
        end

        if text
          @timer.record_first_token!
          @message.update!(content: (@message.content || "") + text)
          broadcast_throttled
        end

        if @parser.finished?(chunk) || @parser.usage_ready?(chunk)
          save_tool_calls
          fall_back_to_reasoning
          save_token_usage
          @message.broadcast_streaming_content if @broadcast_pending
          @message.broadcast_updated
        end
      end

      private

      def broadcast_throttled
        now = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
        if now - @last_broadcast_at < BROADCAST_INTERVAL_MS
          @broadcast_pending = true
          return
        end

        @last_broadcast_at = now
        @broadcast_pending = false
        @message.broadcast_streaming_content
      end

      def save_tool_calls
        return unless @tool_calls.any?

        @message.update!(tool_calls: @tool_calls.to_a)
      end

      # When a model answers entirely in the reasoning field there is no content
      # to show, which leaves the message stuck on the typing indicator. Adopt
      # the reasoning as the reply rather than rendering an empty bubble.
      def fall_back_to_reasoning
        return if @reasoning.empty? || @message.content.present? || @tool_calls.any?

        @message.update!(content: @reasoning)
        @broadcast_pending = true
      end

      def resolved_model_attrs
        @resolved_model.present? ? { resolved_model: @resolved_model } : {}
      end

      def save_token_usage
        attrs = @timer.timing_attrs.merge(resolved_model_attrs)
        if @input_tokens == 0 && @output_tokens == 0
          estimated = TokenEstimator.estimate(@message.content)
          attrs.merge!(output_tokens: estimated, tokens_estimated: true) if estimated
        else
          attrs.merge!(input_tokens: @input_tokens, output_tokens: @output_tokens)
        end
        return if attrs.empty?

        @message.update!(**attrs)
        @message.conversation.update_token_totals! if attrs.key?(:output_tokens)
      end
    end
  end
end
