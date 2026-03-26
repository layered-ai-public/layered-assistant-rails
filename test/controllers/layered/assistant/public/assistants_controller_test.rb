require "test_helper"

module Layered
  module Assistant
    module Public
      class AssistantsControllerTest < ActionDispatch::IntegrationTest
        setup do
          sign_out :user
        end

        test "should get index without authentication" do
          get "/layered/assistant/public/assistants"
          assert_response :success
          assert_select "table.l-ui-table"
        end

        test "index shows only public assistants" do
          get "/layered/assistant/public/assistants"
          assert_response :success
          assert_select "table.l-ui-table tbody tr", count: 2
        end

        test "should show public assistant" do
          assistant = layered_assistant_assistants(:coding)
          get "/layered/assistant/public/assistants/#{assistant.id}"
          assert_response :redirect
          follow_redirect!
          assert_response :success
          assert_select "select.l-ui-select"
        end

        test "should not show private assistant" do
          assistant = layered_assistant_assistants(:private)
          get "/layered/assistant/public/assistants/#{assistant.id}"
          assert_response :not_found
        end
      end
    end
  end
end
