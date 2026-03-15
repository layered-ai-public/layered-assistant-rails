require "test_helper"

module Layered
  module Assistant
    class MessageTest < ActiveSupport::TestCase
      test "user message requires content" do
        message = layered_assistant_conversations(:greeting).messages.build(role: :user, content: nil)
        assert_not message.valid?
        assert_includes message.errors[:content], "can't be blank"
      end

      test "assistant message allows nil content" do
        message = layered_assistant_conversations(:greeting).messages.create!(role: :assistant, content: nil)
        assert message.persisted?
        assert_nil message.content
      end

      test "system message requires content" do
        message = layered_assistant_conversations(:greeting).messages.build(role: :system, content: nil)
        assert_not message.valid?
      end

      test "by_created_at orders ascending" do
        messages = layered_assistant_conversations(:greeting).messages.by_created_at
        assert_equal messages, messages.sort_by(&:created_at)
      end
    end
  end
end
