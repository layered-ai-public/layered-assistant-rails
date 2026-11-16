require "test_helper"

module Layered
  module Assistant
    class ConversationHelperTest < ActionView::TestCase
      include ConversationHelper
      include MessagesHelper

      setup do
        @conversation = layered_assistant_conversations(:greeting)
      end

      test "renders the conversation's messages and composer" do
        result = layered_assistant_conversation(@conversation)

        assert_includes result, "<turbo-cable-stream-source"
        assert_includes result, %(class="#{dom_id(@conversation)}_messages l-ui-conversation")
        assert_includes result, %(id="#{dom_id(@conversation, :composer_form)}")
        @conversation.messages.where(role: :user).each do |message|
          assert_includes result, dom_id(message)
        end
      end

      test "offers only models available to the conversation's owner" do
        foreign_provider = Provider.create!(name: "Other", protocol: "anthropic", owner: User.where.not(id: @conversation.owner_id).first!)
        foreign_model = foreign_provider.models.create!(name: "Foreign", identifier: "foreign-model")

        result = layered_assistant_conversation(@conversation)

        assert_includes result, layered_assistant_models(:sonnet).name
        assert_not_includes result, foreign_model.name
      end
    end
  end
end
