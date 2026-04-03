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
          post "/layered/assistant/personas", params: { persona: { name: "New Persona", description: "A test persona", instructions: "Be helpful." } }
        end

        assert_redirected_to "/layered/assistant/personas"
        assert_equal "Persona was successfully created.", flash[:notice]
      end

      test "should not create persona with invalid params" do
        assert_no_difference("Persona.count") do
          post "/layered/assistant/personas", params: { persona: { name: "" } }
        end

        assert_response :unprocessable_entity
        assert_select ".l-ui-form__errors"
      end

      test "should get edit" do
        persona = layered_assistant_personas(:friendly)

        get "/layered/assistant/personas/#{persona.id}/edit"
        assert_response :success
        assert_select "input[value=?]", persona.name
      end

      test "should update persona with valid params" do
        persona = layered_assistant_personas(:friendly)

        patch "/layered/assistant/personas/#{persona.id}", params: { persona: { name: "Updated Name", description: "New description" } }
        assert_redirected_to "/layered/assistant/personas"
        assert_equal "Persona was successfully updated.", flash[:notice]

        persona.reload
        assert_equal "Updated Name", persona.name
        assert_equal "New description", persona.description
      end

      test "should not update persona with invalid params" do
        persona = layered_assistant_personas(:friendly)

        patch "/layered/assistant/personas/#{persona.id}", params: { persona: { name: "" } }
        assert_response :unprocessable_entity
        assert_select ".l-ui-form__errors"
      end

      test "should destroy persona without assistants" do
        persona = Persona.create!(name: "Disposable")

        assert_difference("Persona.count", -1) do
          delete "/layered/assistant/personas/#{persona.id}"
        end

        assert_redirected_to "/layered/assistant/personas"
        assert_equal "Persona was successfully deleted.", flash[:notice]
      end

      test "should not destroy persona with assistants" do
        persona = layered_assistant_personas(:friendly)

        assert_no_difference("Persona.count") do
          delete "/layered/assistant/personas/#{persona.id}"
        end

        assert_redirected_to "/layered/assistant/personas"
        assert_equal "Persona could not be deleted because it is assigned to assistants.", flash[:alert]
      end
    end
  end
end
