require "test_helper"

module Layered
  module Assistant
    class ToolCallAccumulatorTest < ActiveSupport::TestCase
      test "merges the fragments of one call" do
        accumulator = ToolCallAccumulator.new
        accumulator.add(key: 0, id: "call_1", name: "lookup")
        accumulator.add(key: 0, arguments: '{"term":')
        accumulator.add(key: 0, arguments: '"rails"}')

        assert_equal [ {
          "id" => "call_1",
          "type" => "function",
          "function" => { "name" => "lookup", "arguments" => '{"term":"rails"}' }
        } ], accumulator.to_a
      end

      test "keeps parallel calls apart and in arrival order" do
        accumulator = ToolCallAccumulator.new
        accumulator.add(key: 1, id: "call_a", name: "first", arguments: "{}")
        accumulator.add(key: 2, id: "call_b", name: "second", arguments: "{}")

        assert_equal [ "first", "second" ], accumulator.to_a.map { |call| call.dig("function", "name") }
      end

      test "a call with no streamed arguments gets an empty object" do
        accumulator = ToolCallAccumulator.new
        accumulator.add(key: 0, id: "call_1", name: "now")

        assert_equal "{}", accumulator.to_a.first.dig("function", "arguments")
      end

      test "any? reports whether the response asked for anything" do
        accumulator = ToolCallAccumulator.new
        assert_not accumulator.any?

        accumulator.add(key: 0, id: "call_1", name: "now")
        assert accumulator.any?
      end
    end
  end
end
