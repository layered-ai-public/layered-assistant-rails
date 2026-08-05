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
        assert_nil parser.text({ "choices" => [ { "delta" => {} } ] })
      end

      test "openai: text returns nil for empty string content" do
        parser = ChunkParser.new("openai")
        assert_nil parser.text({ "choices" => [ { "delta" => { "content" => "" } } ] })
      end

      test "openai: text returns string for valid delta content" do
        parser = ChunkParser.new("openai")
        assert_equal "Hi", parser.text({ "choices" => [ { "delta" => { "content" => "Hi" } } ] })
      end

      test "openai: finished? is true when finish_reason present" do
        parser = ChunkParser.new("openai")
        assert parser.finished?({ "choices" => [ { "delta" => {}, "finish_reason" => "stop" } ] })
      end

      test "openai: finished? is false when no finish_reason" do
        parser = ChunkParser.new("openai")
        assert_not parser.finished?({ "choices" => [ { "delta" => { "content" => "Hi" } } ] })
      end

      test "openai: usage_ready? is true for usage-only chunk" do
        parser = ChunkParser.new("openai")
        assert parser.usage_ready?({ "choices" => [], "usage" => { "prompt_tokens" => 80, "completion_tokens" => 20 } })
      end

      test "openai: usage_ready? is false for regular delta chunk" do
        parser = ChunkParser.new("openai")
        assert_not parser.usage_ready?({ "choices" => [ { "delta" => { "content" => "Hi" } } ] })
      end

      test "openai: input_tokens returns prompt_tokens from usage chunk" do
        parser = ChunkParser.new("openai")
        chunk = { "choices" => [], "usage" => { "prompt_tokens" => 80, "completion_tokens" => 20 } }
        assert_equal 80, parser.input_tokens(chunk)
      end

      test "openai: input_tokens returns nil for regular delta chunk" do
        parser = ChunkParser.new("openai")
        assert_nil parser.input_tokens({ "choices" => [ { "delta" => { "content" => "Hi" } } ] })
      end

      test "openai: output_tokens returns completion_tokens from usage chunk" do
        parser = ChunkParser.new("openai")
        chunk = { "choices" => [], "usage" => { "prompt_tokens" => 80, "completion_tokens" => 20 } }
        assert_equal 20, parser.output_tokens(chunk)
      end

      test "openai: output_tokens returns nil for regular delta chunk" do
        parser = ChunkParser.new("openai")
        assert_nil parser.output_tokens({ "choices" => [ { "delta" => { "content" => "Hi" } } ] })
      end

      # Reasoning

      test "openai: reasoning returns text from the reasoning delta" do
        parser = ChunkParser.new("openai")
        chunk = { "choices" => [ { "delta" => { "content" => "", "reasoning" => "Hello" } } ] }
        assert_equal "Hello", parser.reasoning(chunk)
      end

      test "openai: reasoning returns nil when absent or empty" do
        parser = ChunkParser.new("openai")
        assert_nil parser.reasoning({ "choices" => [ { "delta" => { "content" => "Hi" } } ] })
        assert_nil parser.reasoning({ "choices" => [ { "delta" => { "reasoning" => "" } } ] })
      end

      test "anthropic: reasoning returns nil" do
        parser = ChunkParser.new("anthropic")
        assert_nil parser.reasoning({ "type" => "content_block_delta", "delta" => { "text" => "Hi" } })
      end

      # Usage on a finish_reason chunk (OpenRouter)

      test "openai: usage_ready? is true when usage rides the finish_reason chunk" do
        parser = ChunkParser.new("openai")
        chunk = {
          "choices" => [ { "delta" => { "content" => "" }, "finish_reason" => "stop" } ],
          "usage" => { "prompt_tokens" => 98, "completion_tokens" => 11 }
        }
        assert parser.usage_ready?(chunk)
        assert_equal 98, parser.input_tokens(chunk)
        assert_equal 11, parser.output_tokens(chunk)
      end

      test "openai: usage_ready? is false for a mid-stream chunk carrying usage" do
        parser = ChunkParser.new("openai")
        chunk = {
          "choices" => [ { "delta" => { "content" => "Hi" }, "finish_reason" => nil } ],
          "usage" => { "prompt_tokens" => 10, "completion_tokens" => 1 }
        }
        assert_not parser.usage_ready?(chunk)
      end

      # Resolved model

      test "openai: model returns the model that served the request" do
        parser = ChunkParser.new("openai")
        chunk = { "model" => "z-ai/glm-5.2", "choices" => [ { "delta" => { "content" => "Hi" } } ] }
        assert_equal "z-ai/glm-5.2", parser.model(chunk)
      end

      test "openai: model returns nil when absent or blank" do
        parser = ChunkParser.new("openai")
        assert_nil parser.model({ "choices" => [ { "delta" => { "content" => "Hi" } } ] })
        assert_nil parser.model({ "model" => "" })
      end

      test "anthropic: model returns the model from message_start" do
        parser = ChunkParser.new("anthropic")
        chunk = { "type" => "message_start", "message" => { "model" => "claude-opus-5" } }
        assert_equal "claude-opus-5", parser.model(chunk)
      end

      test "anthropic: model returns nil for non-message_start chunk" do
        parser = ChunkParser.new("anthropic")
        assert_nil parser.model({ "type" => "content_block_delta", "delta" => { "text" => "Hi" } })
      end
    end
  end
end
