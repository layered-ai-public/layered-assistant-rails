require "test_helper"

module Layered
  module Assistant
    module Clients
      class AnthropicTest < ActiveSupport::TestCase
        setup do
          @provider = layered_assistant_providers(:anthropic)
        end

        test "raises error when API key is blank" do
          @provider.update!(secret: nil)

          error = assert_raises(StandardError) do
            Clients::Anthropic.new(@provider)
          end
          assert_match(/API key is not set/, error.message)
        end

        test "formats messages using Anthropic format" do
          conversation = layered_assistant_conversations(:greeting)
          service = MessagesService.new
          result = service.format(conversation.messages, provider: @provider)

          assert_equal "user", result[:messages].first[:role]
          assert_kind_of Array, result[:messages].first[:content]
          assert_equal "text", result[:messages].first[:content].first[:type]
        end

        test "extracts system messages into separate key" do
          conversation = layered_assistant_conversations(:greeting)
          conversation.messages.create!(role: :system, content: "Be helpful.")

          service = MessagesService.new
          result = service.format(conversation.messages, provider: @provider)

          assert_equal "Be helpful.", result[:system]
          assert result[:messages].none? { |m| m[:role] == "system" }
        end
      end
    end
  end
end
