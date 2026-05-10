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

        assert_redirected_to "/layered/assistant/skills"
        assert_equal "Skill created", flash[:notice]
      end

      test "should not create skill with invalid params" do
        assert_no_difference("Skill.count") do
          post "/layered/assistant/skills", params: { skill: { name: "" } }
        end

        assert_response :unprocessable_entity
        assert_select ".l-ui-form__errors"
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
        assert_redirected_to "/layered/assistant/skills"
        assert_equal "Skill updated", flash[:notice]

        skill.reload
        assert_equal "Updated Name", skill.name
        assert_equal "New description", skill.description
      end

      test "should not update skill with invalid params" do
        skill = layered_assistant_skills(:research)

        patch "/layered/assistant/skills/#{skill.id}", params: { skill: { name: "" } }
        assert_response :unprocessable_entity
        assert_select ".l-ui-form__errors"
      end

      test "should destroy skill without assistants" do
        skill = Skill.create!(name: "Disposable", owner: users(:one))

        assert_difference("Skill.count", -1) do
          delete "/layered/assistant/skills/#{skill.id}"
        end

        assert_redirected_to "/layered/assistant/skills"
        assert_equal "Skill deleted", flash[:notice]
      end

      test "should return 404 for out-of-scope skill on edit" do
        skill = layered_assistant_skills(:research)
        skill.update!(owner: nil)

        get "/layered/assistant/skills/#{skill.id}/edit"
        assert_response :not_found
      end

      test "should return 404 for out-of-scope skill on update" do
        skill = layered_assistant_skills(:research)
        skill.update!(owner: nil)

        patch "/layered/assistant/skills/#{skill.id}", params: { skill: { name: "Hijacked" } }
        assert_response :not_found

        skill.reload
        assert_equal "Research", skill.name
      end

      test "should return 404 for out-of-scope skill on destroy" do
        skill = layered_assistant_skills(:research)
        skill.update!(owner: nil)

        assert_no_difference("Skill.count") do
          delete "/layered/assistant/skills/#{skill.id}"
        end

        assert_response :not_found
      end

      test "should not destroy skill with assistants" do
        skill = layered_assistant_skills(:research)

        assert_no_difference("Skill.count") do
          delete "/layered/assistant/skills/#{skill.id}"
        end

        assert_redirected_to "/layered/assistant/skills"
        assert_match(/Skill could not be deleted/, flash[:alert])
      end
    end
  end
end
