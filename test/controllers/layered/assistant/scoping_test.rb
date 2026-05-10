require "test_helper"

module Layered
  module Assistant
    class ScopingTest < ActionDispatch::IntegrationTest
      test "owned conversation is visible to its owner" do
        conversation = layered_assistant_conversations(:greeting)
        get "/layered/assistant/conversations/#{conversation.id}"
        assert_response :success
      end

      test "unowned conversation returns 404" do
        conversation = layered_assistant_conversations(:greeting)
        conversation.update!(owner: nil)
        get "/layered/assistant/conversations/#{conversation.id}"
        assert_response :not_found
      end

      test "conversation owned by another user returns 404" do
        conversation = layered_assistant_conversations(:greeting)
        other = User.create!(name: "Other", email: "other@example.com", password: "password")
        conversation.update!(owner: other)
        get "/layered/assistant/conversations/#{conversation.id}"
        assert_response :not_found
      end
    end
  end
end
