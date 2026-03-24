module Layered
  module Assistant
    class ResponseTimer
      def initialize
        @started_at = nil
        @first_token_at = nil
      end

      def start!
        @started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end

      def record_first_token!
        @first_token_at ||= Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end

      def timing_attrs
        return {} unless @started_at

        now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        attrs = { response_ms: ((now - @started_at) * 1000).round }
        attrs[:ttft_ms] = ((@first_token_at - @started_at) * 1000).round if @first_token_at
        attrs
      end

      def started?
        !@started_at.nil?
      end
    end
  end
end
