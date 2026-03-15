require "test_helper"

module Layered
  module Assistant
    module Clients
      class OpenAITest < ActiveSupport::TestCase
        setup do
          @provider = layered_assistant_providers(:openai)
        end

        test "raises error when API key is blank" do
          @provider.update!(secret: nil)

          assert_raises(StandardError, /API key is not set/) do
            Clients::OpenAI.new(@provider)
          end
        end

        test "formats messages using OpenAI format" do
          conversation = layered_assistant_conversations(:greeting)
          service = MessagesService.new
          result = service.format(conversation.messages, provider: @provider)

          assert_equal "user", result[:messages].first[:role]
          assert_kind_of String, result[:messages].first[:content]
          assert_equal "Hello there", result[:messages].first[:content]
        end

        test "includes system messages inline in messages array" do
          conversation = layered_assistant_conversations(:greeting)
          conversation.messages.create!(role: :system, content: "Be helpful.", created_at: 10.minutes.ago)

          service = MessagesService.new
          result = service.format(conversation.messages, provider: @provider)

          system_msg = result[:messages].find { |m| m[:role] == "system" }
          assert_not_nil system_msg
          assert_equal "Be helpful.", system_msg[:content]
          assert_nil result[:system]
        end
      end
    end
  end
end
