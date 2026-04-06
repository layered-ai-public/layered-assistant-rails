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
        assert_equal "# Persona\n\n#{persona.instructions}", @service.call(assistant: assistant)
      end

      test "prepends persona instructions with heading to assistant instructions" do
        persona = layered_assistant_personas(:friendly)
        assistant = Assistant.new(name: "Test", persona: persona, instructions: "Be concise.")
        result = @service.call(assistant: assistant)
        assert_equal "# Persona\n\n#{persona.instructions}\n\nBe concise.", result
      end

      test "ignores persona with blank instructions" do
        persona = layered_assistant_personas(:empty)
        assistant = Assistant.new(name: "Test", persona: persona, instructions: "Be helpful.")
        assert_equal "Be helpful.", @service.call(assistant: assistant)
      end
    end
  end
end
