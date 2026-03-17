require "test_helper"

module Layered
  module Assistant
    class ScopingTest < ActionDispatch::IntegrationTest
      teardown do
        # Remove scope block so other tests are not affected
        Layered::Assistant.class_variable_set(:@@scope_block, nil)
      end

      test "records are unscoped by default" do
        get "/layered/assistant/conversations"
        assert_response :success
      end

      test "scope block restricts visible conversations" do
        conversation = layered_assistant_conversations(:greeting)
        conversation.update!(owner: users(:one))

        Layered::Assistant.scope do |model_class|
          if model_class == Layered::Assistant::Conversation
            model_class.where(owner: l_ui_current_user)
          else
            model_class.all
          end
        end

        get "/layered/assistant/conversations/#{conversation.id}"
        assert_response :success
      end

      test "scope block returns 404 for records outside scope" do
        conversation = layered_assistant_conversations(:greeting)
        conversation.update!(owner: nil)

        Layered::Assistant.scope do |model_class|
          if model_class == Layered::Assistant::Conversation
            model_class.where(owner: l_ui_current_user)
          else
            model_class.all
          end
        end

        get "/layered/assistant/conversations/#{conversation.id}"
        assert_response :not_found
      end

      test "scope block has access to controller context" do
        Layered::Assistant.scope do |model_class|
          if l_ui_current_user.present?
            model_class.all
          else
            model_class.none
          end
        end

        get "/layered/assistant/conversations"
        assert_response :success
      end
    end
  end
end
