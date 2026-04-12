require "test_helper"

module Layered
  module Assistant
    class SkillsControllerTest < ActionDispatch::IntegrationTest
      test "should get index" do
        get "/layered/assistant/skills"
        assert_response :success
        assert_select "table.l-ui-table"
      end

      test "should get new" do
        get "/layered/assistant/skills/new"
        assert_response :success
        assert_select "form.l-ui-form"
      end

      test "should create skill with valid params" do
        assert_difference("Skill.count", 1) do
          post "/layered/assistant/skills", params: { skill: { name: "New Skill", description: "A test skill", instructions: "Do the thing." } }
        end

        assert_response :redirect
      end

      test "should not create skill with invalid params" do
        assert_no_difference("Skill.count") do
          post "/layered/assistant/skills", params: { skill: { name: "" } }
        end

        assert_response :unprocessable_entity
      end

      test "should get edit" do
        skill = layered_assistant_skills(:research)

        get "/layered/assistant/skills/#{skill.id}/edit"
        assert_response :success
        assert_select "input[value=?]", skill.name
      end

      test "should update skill with valid params" do
        skill = layered_assistant_skills(:research)

        patch "/layered/assistant/skills/#{skill.id}", params: { skill: { name: "Updated Name", description: "New description" } }
        assert_response :redirect

        skill.reload
        assert_equal "Updated Name", skill.name
        assert_equal "New description", skill.description
      end

      test "should not update skill with invalid params" do
        skill = layered_assistant_skills(:research)

        patch "/layered/assistant/skills/#{skill.id}", params: { skill: { name: "" } }
        assert_response :unprocessable_entity
      end

      test "should destroy skill without assistants" do
        skill = Skill.create!(name: "Disposable")

        assert_difference("Skill.count", -1) do
          delete "/layered/assistant/skills/#{skill.id}"
        end

        assert_response :redirect
      end
    end
  end
end
