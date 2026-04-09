require "test_helper"

module Layered
  module Assistant
    class SystemPromptServiceTest < ActiveSupport::TestCase
      setup do
        @service = SystemPromptService.new
      end

      test "returns nil when both persona and system prompt are blank" do
        assistant = Assistant.new(name: "Test")
        assert_nil @service.call(assistant: assistant)
      end

      test "returns instructions when no persona" do
        assistant = Assistant.new(name: "Test", instructions: "Be helpful.")
        assert_equal "Be helpful.", @service.call(assistant: assistant)
      end

      test "returns persona instructions with heading when no assistant instructions" do
        persona = layered_assistant_personas(:friendly)
        assistant = Assistant.new(name: "Test", persona: persona)
        assert_equal "## Persona\n\n#{persona.instructions}", @service.call(assistant: assistant)
      end

      test "prepends persona instructions with heading to assistant instructions" do
        persona = layered_assistant_personas(:friendly)
        assistant = Assistant.new(name: "Test", persona: persona, instructions: "Be concise.")
        result = @service.call(assistant: assistant)
        assert_equal "## Persona\n\n#{persona.instructions}\n\nBe concise.", result
      end

      test "ignores persona with blank instructions" do
        persona = layered_assistant_personas(:empty)
        assistant = Assistant.new(name: "Test", persona: persona, instructions: "Be helpful.")
        assert_equal "Be helpful.", @service.call(assistant: assistant)
      end

      test "includes skill instructions with name and heading" do
        assistant = layered_assistant_assistants(:general)
        skill = layered_assistant_skills(:research)
        assistant.skills = [skill]
        result = @service.call(assistant: assistant)
        assert_includes result, "## Skills"
        assert_includes result, "### #{skill.name}"
        assert_includes result, skill.instructions
      end

      test "separates multiple skills with horizontal rules" do
        assistant = Assistant.new(name: "Test")
        assistant.skills = [layered_assistant_skills(:research), layered_assistant_skills(:coding)]
        assistant.save!
        result = @service.call(assistant: assistant)
        assert_includes result, "---"
        assert_includes result, "### Research"
        assert_includes result, "### Coding"
      end

      test "combines persona, skills, and assistant instructions" do
        persona = layered_assistant_personas(:friendly)
        assistant = Assistant.new(name: "Test", persona: persona, instructions: "Be concise.")
        assistant.skills = [layered_assistant_skills(:research), layered_assistant_skills(:coding)]
        assistant.save!
        result = @service.call(assistant: assistant)
        assert_match(/Persona.*Skills.*Research.*---.*Coding.*Be concise\./m, result)
      end

      test "ignores skills with blank instructions" do
        assistant = Assistant.new(name: "Test", instructions: "Be helpful.")
        assistant.skills = [layered_assistant_skills(:empty)]
        assistant.save!
        assert_equal "Be helpful.", @service.call(assistant: assistant)
      end

      test "returns nil when assistant has only skills with blank instructions" do
        assistant = Assistant.new(name: "Test")
        assistant.skills = [layered_assistant_skills(:empty)]
        assistant.save!
        assert_nil @service.call(assistant: assistant)
      end
    end
  end
end
