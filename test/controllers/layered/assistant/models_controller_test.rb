require "test_helper"

module Layered
  module Assistant
    class ModelsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @provider = layered_assistant_providers(:anthropic)
      end

      test "should get index" do
        get "/layered/assistant/providers/#{@provider.id}/models"
        assert_response :success
        assert_select "table.l-ui-table"
      end

      test "should get new" do
        get "/layered/assistant/providers/#{@provider.id}/models/new"
        assert_response :success
        assert_select "form.l-ui-form"
      end

      test "should create model with valid params" do
        assert_difference("Model.count", 1) do
          post "/layered/assistant/providers/#{@provider.id}/models", params: { model: { name: "New Model", identifier: "new-model" } }
        end

        assert_redirected_to "/layered/assistant/providers/#{@provider.id}/models"
        assert_equal "Model created", flash[:notice]
      end

      test "should not create model with invalid params" do
        assert_no_difference("Model.count") do
          post "/layered/assistant/providers/#{@provider.id}/models", params: { model: { name: "", identifier: "" } }
        end

        assert_response :unprocessable_entity
        assert_select ".l-ui-form__errors"
      end

      test "should get edit" do
        model = layered_assistant_models(:sonnet)

        get "/layered/assistant/providers/#{@provider.id}/models/#{model.id}/edit"
        assert_response :success
        assert_select "input[value=?]", model.name
      end

      test "should update model with valid params" do
        model = layered_assistant_models(:sonnet)

        patch "/layered/assistant/providers/#{@provider.id}/models/#{model.id}", params: { model: { name: "Updated Name", identifier: "updated-id" } }
        assert_redirected_to "/layered/assistant/providers/#{@provider.id}/models"
        assert_equal "Model updated", flash[:notice]

        model.reload
        assert_equal "Updated Name", model.name
        assert_equal "updated-id", model.identifier
      end

      test "should not update model with invalid params" do
        model = layered_assistant_models(:sonnet)

        patch "/layered/assistant/providers/#{@provider.id}/models/#{model.id}", params: { model: { name: "", identifier: "" } }
        assert_response :unprocessable_entity
        assert_select ".l-ui-form__errors"
      end

      test "should destroy model without associations" do
        model = layered_assistant_models(:haiku)

        assert_difference("Model.count", -1) do
          delete "/layered/assistant/providers/#{@provider.id}/models/#{model.id}"
        end

        assert_redirected_to "/layered/assistant/providers/#{@provider.id}/models"
        assert_equal "Model deleted", flash[:notice]
      end

      test "should not destroy model with assistants" do
        model = layered_assistant_models(:sonnet)

        assert_no_difference("Model.count") do
          delete "/layered/assistant/providers/#{@provider.id}/models/#{model.id}"
        end

        assert_redirected_to "/layered/assistant/providers/#{@provider.id}/models"
        assert flash[:alert].present?, "Expected an alert about deletion restriction"
      end
    end
  end
end
