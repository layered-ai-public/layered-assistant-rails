require "test_helper"

module Layered
  module Assistant
    class AssistantsControllerTest < ActionDispatch::IntegrationTest
      test "should get index" do
        get "/layered/assistant/assistants"
        assert_response :success
        assert_select "table.l-ui-table"
      end

      test "should get new" do
        get "/layered/assistant/assistants/new"
        assert_response :success
        assert_select "form.l-ui-form"
      end

      test "should create assistant with valid params" do
        assert_difference("Assistant.count", 1) do
          post "/layered/assistant/assistants", params: { assistant: { name: "New Assistant", description: "A test assistant", instructions: "Be helpful." } }
        end

        assert_redirected_to "/layered/assistant/assistants"
        assert_equal "Assistant created", flash[:notice]

        assistant = Assistant.order(:id).last
        assert_equal users(:one), assistant.owner
      end

      test "should create public assistant" do
        model = layered_assistant_models(:sonnet)

        assert_difference("Assistant.count", 1) do
          post "/layered/assistant/assistants", params: { assistant: { name: "Public Assistant", public: true, default_model_id: model.id } }
        end

        assert Assistant.last.public
        assert_equal model, Assistant.last.default_model
      end

      test "should not create public assistant without default model" do
        assert_no_difference("Assistant.count") do
          post "/layered/assistant/assistants", params: { assistant: { name: "Public Assistant", public: true } }
        end

        assert_response :unprocessable_entity
      end

      test "should not create assistant with invalid params" do
        assert_no_difference("Assistant.count") do
          post "/layered/assistant/assistants", params: { assistant: { name: "" } }
        end

        assert_response :unprocessable_entity
        assert_select ".l-ui-form__errors"
      end

      test "should get edit" do
        assistant = layered_assistant_assistants(:general)

        get "/layered/assistant/assistants/#{assistant.id}/edit"
        assert_response :success
        assert_select "input[value=?]", assistant.name
      end

      test "should update assistant with valid params" do
        assistant = layered_assistant_assistants(:general)

        patch "/layered/assistant/assistants/#{assistant.id}", params: { assistant: { name: "Updated Name", description: "New description" } }
        assert_redirected_to "/layered/assistant/assistants"
        assert_equal "Assistant updated", flash[:notice]

        assistant.reload
        assert_equal "Updated Name", assistant.name
        assert_equal "New description", assistant.description
      end

      test "should not update assistant with invalid params" do
        assistant = layered_assistant_assistants(:general)

        patch "/layered/assistant/assistants/#{assistant.id}", params: { assistant: { name: "" } }
        assert_response :unprocessable_entity
        assert_select ".l-ui-form__errors"
      end

      test "should reject out-of-scope persona_id on create" do
        persona = layered_assistant_personas(:friendly)
        persona.update!(owner: nil)

        assert_no_difference("Assistant.count") do
          post "/layered/assistant/assistants", params: { assistant: { name: "Sneaky", persona_id: persona.id } }
        end

        assert_response :not_found
      end

      test "should reject out-of-scope persona_id on update" do
        assistant = layered_assistant_assistants(:general)
        persona = layered_assistant_personas(:formal)
        persona.update!(owner: nil)

        patch "/layered/assistant/assistants/#{assistant.id}", params: { assistant: { persona_id: persona.id } }
        assert_response :not_found

        assistant.reload
        assert_not_equal persona, assistant.persona
      end

      test "should destroy assistant" do
        assistant = Assistant.create!(name: "Disposable", owner: users(:one))

        assert_difference("Assistant.count", -1) do
          delete "/layered/assistant/assistants/#{assistant.id}"
        end

        assert_redirected_to "/layered/assistant/assistants"
        assert_equal "Assistant deleted", flash[:notice]
      end
    end
  end
end
