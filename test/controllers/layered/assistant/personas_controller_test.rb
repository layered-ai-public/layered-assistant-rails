require "test_helper"

module Layered
  module Assistant
    class PersonasControllerTest < ActionDispatch::IntegrationTest
      test "should get index" do
        get "/layered/assistant/personas"
        assert_response :success
        assert_select "table.l-ui-table"
      end

      test "should get new" do
        get "/layered/assistant/personas/new"
        assert_response :success
        assert_select "form.l-ui-form"
      end

      test "should create persona with valid params" do
        assert_difference("Persona.count", 1) do
          post "/layered/assistant/personas", params: { persona: { name: "New Persona", instructions: "Be helpful." } }
        end

        assert_response :redirect
      end

      test "should not create persona with invalid params" do
        assert_no_difference("Persona.count") do
          post "/layered/assistant/personas", params: { persona: { name: "" } }
        end

        assert_response :unprocessable_entity
      end

      test "should get edit" do
        persona = layered_assistant_personas(:friendly)

        get "/layered/assistant/personas/#{persona.id}/edit"
        assert_response :success
        assert_select "input[value=?]", persona.name
      end

      test "should update persona with valid params" do
        persona = layered_assistant_personas(:friendly)

        patch "/layered/assistant/personas/#{persona.id}", params: { persona: { name: "Updated Name" } }
        assert_response :redirect

        persona.reload
        assert_equal "Updated Name", persona.name
      end

      test "should not update persona with invalid params" do
        persona = layered_assistant_personas(:friendly)

        patch "/layered/assistant/personas/#{persona.id}", params: { persona: { name: "" } }
        assert_response :unprocessable_entity
      end

      test "should destroy persona without assistants" do
        persona = Persona.create!(name: "Disposable", instructions: "Temporary.")

        assert_difference("Persona.count", -1) do
          delete "/layered/assistant/personas/#{persona.id}"
        end

        assert_response :redirect
      end
    end
  end
end
