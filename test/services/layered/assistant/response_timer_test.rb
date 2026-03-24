require "test_helper"

module Layered
  module Assistant
    class ResponseTimerTest < ActiveSupport::TestCase
      test "timing_attrs returns empty hash before start!" do
        timer = ResponseTimer.new
        assert_equal({}, timer.timing_attrs)
      end

      test "started? is false before start!" do
        timer = ResponseTimer.new
        assert_not timer.started?
      end

      test "started? is true after start!" do
        timer = ResponseTimer.new
        timer.start!
        assert timer.started?
      end

      test "timing_attrs includes response_ms after start!" do
        timer = ResponseTimer.new
        timer.start!
        attrs = timer.timing_attrs
        assert attrs.key?(:response_ms)
        assert attrs[:response_ms] >= 0
      end

      test "timing_attrs does not include ttft_ms without record_first_token!" do
        timer = ResponseTimer.new
        timer.start!
        assert_not timer.timing_attrs.key?(:ttft_ms)
      end

      test "timing_attrs includes ttft_ms after record_first_token!" do
        timer = ResponseTimer.new
        timer.start!
        timer.record_first_token!
        attrs = timer.timing_attrs
        assert attrs.key?(:ttft_ms)
        assert attrs[:ttft_ms] >= 0
      end

      test "ttft_ms is less than or equal to response_ms" do
        timer = ResponseTimer.new
        timer.start!
        timer.record_first_token!
        attrs = timer.timing_attrs
        assert attrs[:ttft_ms] <= attrs[:response_ms]
      end

      test "record_first_token! is idempotent" do
        timer = ResponseTimer.new
        timer.start!
        timer.record_first_token!
        first = timer.timing_attrs[:ttft_ms]
        timer.record_first_token!
        second = timer.timing_attrs[:ttft_ms]
        assert_equal first, second
      end
    end
  end
end
