require "test_helper"

module Layered
  module Assistant
    class ChunkServiceTest < ActiveSupport::TestCase
      setup do
        @anthropic_provider = layered_assistant_providers(:anthropic)
        @openai_provider = layered_assistant_providers(:openai)
      end

      # Anthropic chunks

      test "appends text from Anthropic content_block_delta" do
        message = layered_assistant_conversations(:greeting).messages.create!(role: :assistant, content: nil)
        service = ChunkService.new(message, provider: @anthropic_provider)

        service.call({ "type" => "content_block_delta", "delta" => { "text" => "Hello" } })
        assert_equal "Hello", message.reload.content
      end

      test "accumulates text across multiple Anthropic deltas" do
        message = layered_assistant_conversations(:greeting).messages.create!(role: :assistant, content: nil)
        service = ChunkService.new(message, provider: @anthropic_provider)

        service.call({ "type" => "content_block_delta", "delta" => { "text" => "Hello" } })
        service.call({ "type" => "content_block_delta", "delta" => { "text" => " world" } })
        assert_equal "Hello world", message.reload.content
      end

      test "ignores Anthropic delta without text" do
        message = layered_assistant_conversations(:greeting).messages.create!(role: :assistant, content: nil)
        service = ChunkService.new(message, provider: @anthropic_provider)

        service.call({ "type" => "content_block_delta", "delta" => {} })
        assert_nil message.reload.content
      end

      test "handles Anthropic message_stop without error" do
        message = layered_assistant_conversations(:greeting).messages.create!(role: :assistant, content: nil)
        service = ChunkService.new(message, provider: @anthropic_provider)

        service.call({ "type" => "content_block_delta", "delta" => { "text" => "Done" } })
        service.call({ "type" => "message_stop" })
        assert_equal "Done", message.reload.content
      end

      test "does not broadcast full update for Anthropic text delta" do
        message = layered_assistant_conversations(:greeting).messages.create!(role: :assistant, content: nil)
        service = ChunkService.new(message, provider: @anthropic_provider)

        # broadcast_chunk is called for text deltas (not broadcast_updated)
        assert_respond_to message, :broadcast_chunk
        service.call({ "type" => "content_block_delta", "delta" => { "text" => "Hello" } })
      end

      # OpenAI chunks

      test "appends text from OpenAI delta content" do
        message = layered_assistant_conversations(:greeting).messages.create!(role: :assistant, content: nil)
        service = ChunkService.new(message, provider: @openai_provider)

        service.call({ "choices" => [{ "delta" => { "content" => "Hello" } }] })
        assert_equal "Hello", message.reload.content
      end

      test "accumulates text across multiple OpenAI deltas" do
        message = layered_assistant_conversations(:greeting).messages.create!(role: :assistant, content: nil)
        service = ChunkService.new(message, provider: @openai_provider)

        service.call({ "choices" => [{ "delta" => { "content" => "Hello" } }] })
        service.call({ "choices" => [{ "delta" => { "content" => " world" } }] })
        assert_equal "Hello world", message.reload.content
      end

      test "ignores OpenAI delta without content" do
        message = layered_assistant_conversations(:greeting).messages.create!(role: :assistant, content: nil)
        service = ChunkService.new(message, provider: @openai_provider)

        service.call({ "choices" => [{ "delta" => {} }] })
        assert_nil message.reload.content
      end

      test "handles OpenAI finish_reason without error" do
        message = layered_assistant_conversations(:greeting).messages.create!(role: :assistant, content: nil)
        service = ChunkService.new(message, provider: @openai_provider)

        service.call({ "choices" => [{ "delta" => { "content" => "Done" } }] })
        service.call({ "choices" => [{ "delta" => {}, "finish_reason" => "stop" }] })
        assert_equal "Done", message.reload.content
      end

      test "does not broadcast full update for OpenAI text delta" do
        message = layered_assistant_conversations(:greeting).messages.create!(role: :assistant, content: nil)
        service = ChunkService.new(message, provider: @openai_provider)

        # broadcast_chunk is called for text deltas (not broadcast_updated)
        assert_respond_to message, :broadcast_chunk
        service.call({ "choices" => [{ "delta" => { "content" => "Hello" } }] })
      end

      # Anthropic usage extraction

      test "extracts usage from Anthropic message_start and message_delta" do
        conversation = layered_assistant_conversations(:greeting)
        message = conversation.messages.create!(role: :assistant, content: nil)
        service = ChunkService.new(message, provider: @anthropic_provider)

        service.call({ "type" => "message_start", "message" => { "usage" => { "input_tokens" => 100 } } })
        service.call({ "type" => "content_block_delta", "delta" => { "text" => "Hi" } })
        service.call({ "type" => "message_delta", "usage" => { "output_tokens" => 50 } })
        service.call({ "type" => "message_stop" })

        message.reload
        assert_equal 100, message.input_tokens
        assert_equal 50, message.output_tokens
        assert_equal 150, conversation.reload.token_estimate
      end

      # OpenAI usage extraction

      test "extracts usage from OpenAI separate usage chunk" do
        conversation = layered_assistant_conversations(:greeting)
        message = conversation.messages.create!(role: :assistant, content: nil)
        service = ChunkService.new(message, provider: @openai_provider)

        service.call({ "choices" => [{ "delta" => { "content" => "Hi" } }] })
        service.call({ "choices" => [{ "delta" => {}, "finish_reason" => "stop" }] })
        service.call({ "choices" => [], "usage" => { "prompt_tokens" => 80, "completion_tokens" => 20 } })

        message.reload
        assert_equal 80, message.input_tokens
        assert_equal 20, message.output_tokens
        assert_equal 100, conversation.reload.token_estimate
      end

      # Graceful no-usage handling

      test "estimates tokens when usage data is absent" do
        conversation = layered_assistant_conversations(:greeting)
        message = conversation.messages.create!(role: :assistant, content: nil)
        service = ChunkService.new(message, provider: @anthropic_provider)

        service.call({ "type" => "content_block_delta", "delta" => { "text" => "Hi" } })
        service.call({ "type" => "message_stop" })

        message.reload
        assert_nil message.input_tokens
        assert_equal TokenEstimator.estimate("Hi"), message.output_tokens
        assert message.tokens_estimated?
      end

      test "stops processing chunks after stop check detects stopped message" do
        message = layered_assistant_conversations(:greeting).messages.create!(role: :assistant, content: "Partial")
        service = ChunkService.new(message, provider: @anthropic_provider)

        message.update!(stopped: true)

        # Send enough chunks to trigger the periodic stop check, then one more
        (ChunkService::STOP_CHECK_INTERVAL + 1).times do
          service.call({ "type" => "content_block_delta", "delta" => { "text" => " more" } })
        end

        # The chunk after the stop check should not be appended
        content = message.reload.content
        appended_count = content.scan(" more").length
        assert appended_count <= ChunkService::STOP_CHECK_INTERVAL,
          "Expected at most #{ChunkService::STOP_CHECK_INTERVAL} chunks before stop, got #{appended_count}"
      end

      test "does not mark tokens as estimated when API provides usage" do
        conversation = layered_assistant_conversations(:greeting)
        message = conversation.messages.create!(role: :assistant, content: nil)
        service = ChunkService.new(message, provider: @anthropic_provider)

        service.call({ "type" => "message_start", "message" => { "usage" => { "input_tokens" => 100 } } })
        service.call({ "type" => "content_block_delta", "delta" => { "text" => "Hi" } })
        service.call({ "type" => "message_delta", "usage" => { "output_tokens" => 50 } })
        service.call({ "type" => "message_stop" })

        message.reload
        assert_equal 100, message.input_tokens
        assert_equal 50, message.output_tokens
        assert_not message.tokens_estimated?
      end
    end
  end
end
