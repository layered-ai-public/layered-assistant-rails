require "test_helper"

module Layered
  module Assistant
    class ToolsControllerTest < ActionDispatch::IntegrationTest
      test "should get index" do
        get "/layered/assistant/tools"
        assert_response :success
        assert_select "table.l-ui-table"
      end

      test "should get new" do
        get "/layered/assistant/tools/new"
        assert_response :success
        assert_select "form.l-ui-form"
      end

      test "should create tool with valid params" do
        assert_difference("Tool.count", 1) do
          post "/layered/assistant/tools", params: { tool: { name: "new_tool", description: "A test tool", input_schema: '{"type":"object","properties":{}}' } }
        end

        assert_redirected_to "/layered/assistant/tools"
        assert_equal "Tool was successfully created.", flash[:notice]
      end

      test "should not create tool with invalid params" do
        assert_no_difference("Tool.count") do
          post "/layered/assistant/tools", params: { tool: { name: "" } }
        end

        assert_response :unprocessable_entity
        assert_select ".l-ui-form__errors"
      end

      test "should get edit" do
        tool = layered_assistant_tools(:weather)

        get "/layered/assistant/tools/#{tool.id}/edit"
        assert_response :success
        assert_select "input[value=?]", tool.name
      end

      test "should update tool with valid params" do
        tool = layered_assistant_tools(:weather)

        patch "/layered/assistant/tools/#{tool.id}", params: { tool: { name: "updated_weather", description: "New description" } }
        assert_redirected_to "/layered/assistant/tools"
        assert_equal "Tool was successfully updated.", flash[:notice]

        tool.reload
        assert_equal "updated_weather", tool.name
        assert_equal "New description", tool.description
      end

      test "should not update tool with invalid params" do
        tool = layered_assistant_tools(:weather)

        patch "/layered/assistant/tools/#{tool.id}", params: { tool: { name: "" } }
        assert_response :unprocessable_entity
        assert_select ".l-ui-form__errors"
      end

      test "should destroy tool without assistants" do
        tool = Tool.create!(name: "disposable_tool")

        assert_difference("Tool.count", -1) do
          delete "/layered/assistant/tools/#{tool.id}"
        end

        assert_redirected_to "/layered/assistant/tools"
        assert_equal "Tool was successfully deleted.", flash[:notice]
      end

      test "should not destroy tool with assistants" do
        tool = layered_assistant_tools(:weather)

        assert_no_difference("Tool.count") do
          delete "/layered/assistant/tools/#{tool.id}"
        end

        assert_redirected_to "/layered/assistant/tools"
        assert_match(/Tool could not be deleted/, flash[:alert])
      end

      test "should return 404 for out-of-scope tool on edit" do
        tool = layered_assistant_tools(:weather)
        tool.update!(owner: nil)

        Layered::Assistant.scope do |model_class|
          model_class.where(owner: l_ui_current_user)
        end

        get "/layered/assistant/tools/#{tool.id}/edit"
        assert_response :not_found
      ensure
        Layered::Assistant.class_variable_set(:@@scope_block, nil)
      end

      test "should return 404 for out-of-scope tool on update" do
        tool = layered_assistant_tools(:weather)
        tool.update!(owner: nil)

        Layered::Assistant.scope do |model_class|
          model_class.where(owner: l_ui_current_user)
        end

        patch "/layered/assistant/tools/#{tool.id}", params: { tool: { name: "hijacked" } }
        assert_response :not_found

        tool.reload
        assert_equal "get_weather", tool.name
      ensure
        Layered::Assistant.class_variable_set(:@@scope_block, nil)
      end

      test "should return 404 for out-of-scope tool on destroy" do
        tool = layered_assistant_tools(:weather)
        tool.update!(owner: nil)

        Layered::Assistant.scope do |model_class|
          model_class.where(owner: l_ui_current_user)
        end

        assert_no_difference("Tool.count") do
          delete "/layered/assistant/tools/#{tool.id}"
        end

        assert_response :not_found
      ensure
        Layered::Assistant.class_variable_set(:@@scope_block, nil)
      end
    end
  end
end
