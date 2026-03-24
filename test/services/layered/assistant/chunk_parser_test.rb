require "test_helper"

module Layered
  module Assistant
    class ChunkParserTest < ActiveSupport::TestCase
      # Anthropic

      test "anthropic: text returns nil for non-delta chunk" do
        parser = ChunkParser.new("anthropic")
        assert_nil parser.text({ "type" => "message_start" })
      end

      test "anthropic: text returns nil for empty delta text" do
        parser = ChunkParser.new("anthropic")
        assert_nil parser.text({ "type" => "content_block_delta", "delta" => { "text" => "" } })
      end

      test "anthropic: text returns string for valid content_block_delta" do
        parser = ChunkParser.new("anthropic")
        assert_equal "Hello", parser.text({ "type" => "content_block_delta", "delta" => { "text" => "Hello" } })
      end

      test "anthropic: finished? is true for message_stop" do
        parser = ChunkParser.new("anthropic")
        assert parser.finished?({ "type" => "message_stop" })
      end

      test "anthropic: finished? is false for content_block_delta" do
        parser = ChunkParser.new("anthropic")
        assert_not parser.finished?({ "type" => "content_block_delta", "delta" => { "text" => "Hi" } })
      end

      test "anthropic: usage_ready? is always false" do
        parser = ChunkParser.new("anthropic")
        assert_not parser.usage_ready?({ "type" => "message_delta", "usage" => { "output_tokens" => 5 } })
      end

      test "anthropic: input_tokens returns count from message_start" do
        parser = ChunkParser.new("anthropic")
        chunk = { "type" => "message_start", "message" => { "usage" => { "input_tokens" => 100 } } }
        assert_equal 100, parser.input_tokens(chunk)
      end

      test "anthropic: input_tokens returns nil for non-message_start chunk" do
        parser = ChunkParser.new("anthropic")
        assert_nil parser.input_tokens({ "type" => "content_block_delta", "delta" => { "text" => "Hi" } })
      end

      test "anthropic: output_tokens returns count from message_delta" do
        parser = ChunkParser.new("anthropic")
        chunk = { "type" => "message_delta", "usage" => { "output_tokens" => 50 } }
        assert_equal 50, parser.output_tokens(chunk)
      end

      test "anthropic: output_tokens returns nil for non-message_delta chunk" do
        parser = ChunkParser.new("anthropic")
        assert_nil parser.output_tokens({ "type" => "message_start" })
      end

      # OpenAI

      test "openai: text returns nil for delta without content" do
        parser = ChunkParser.new("openai")
        assert_nil parser.text({ "choices" => [{ "delta" => {} }] })
      end

      test "openai: text returns nil for empty string content" do
        parser = ChunkParser.new("openai")
        assert_nil parser.text({ "choices" => [{ "delta" => { "content" => "" } }] })
      end

      test "openai: text returns string for valid delta content" do
        parser = ChunkParser.new("openai")
        assert_equal "Hi", parser.text({ "choices" => [{ "delta" => { "content" => "Hi" } }] })
      end

      test "openai: finished? is true when finish_reason present" do
        parser = ChunkParser.new("openai")
        assert parser.finished?({ "choices" => [{ "delta" => {}, "finish_reason" => "stop" }] })
      end

      test "openai: finished? is false when no finish_reason" do
        parser = ChunkParser.new("openai")
        assert_not parser.finished?({ "choices" => [{ "delta" => { "content" => "Hi" } }] })
      end

      test "openai: usage_ready? is true for usage-only chunk" do
        parser = ChunkParser.new("openai")
        assert parser.usage_ready?({ "choices" => [], "usage" => { "prompt_tokens" => 80, "completion_tokens" => 20 } })
      end

      test "openai: usage_ready? is false for regular delta chunk" do
        parser = ChunkParser.new("openai")
        assert_not parser.usage_ready?({ "choices" => [{ "delta" => { "content" => "Hi" } }] })
      end

      test "openai: input_tokens returns prompt_tokens from usage chunk" do
        parser = ChunkParser.new("openai")
        chunk = { "choices" => [], "usage" => { "prompt_tokens" => 80, "completion_tokens" => 20 } }
        assert_equal 80, parser.input_tokens(chunk)
      end

      test "openai: input_tokens returns nil for regular delta chunk" do
        parser = ChunkParser.new("openai")
        assert_nil parser.input_tokens({ "choices" => [{ "delta" => { "content" => "Hi" } }] })
      end

      test "openai: output_tokens returns completion_tokens from usage chunk" do
        parser = ChunkParser.new("openai")
        chunk = { "choices" => [], "usage" => { "prompt_tokens" => 80, "completion_tokens" => 20 } }
        assert_equal 20, parser.output_tokens(chunk)
      end

      test "openai: output_tokens returns nil for regular delta chunk" do
        parser = ChunkParser.new("openai")
        assert_nil parser.output_tokens({ "choices" => [{ "delta" => { "content" => "Hi" } }] })
      end
    end
  end
end
