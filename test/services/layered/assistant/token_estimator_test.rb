require "test_helper"

module Layered
  module Assistant
    class TokenEstimatorTest < ActiveSupport::TestCase
      test "estimates tokens using OpenAI rough token count" do
        assert_equal 3, TokenEstimator.estimate("Hello world!")
      end

      test "returns nil for blank text" do
        assert_nil TokenEstimator.estimate(nil)
        assert_nil TokenEstimator.estimate("")
        assert_nil TokenEstimator.estimate("   ")
      end

      test "handles short strings" do
        assert_equal 1, TokenEstimator.estimate("Hello")
        assert_equal 1, TokenEstimator.estimate("Hi")
      end

      test "handles longer strings" do
        assert_equal 2, TokenEstimator.estimate("12345678")
      end
    end
  end
end
