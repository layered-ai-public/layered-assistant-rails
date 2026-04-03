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

      test "returns system prompt when no persona" do
        assistant = Assistant.new(name: "Test", system_prompt: "Be helpful.")
        assert_equal "Be helpful.", @service.call(assistant: assistant)
      end

      test "returns persona instructions when no system prompt" do
        persona = layered_assistant_personas(:friendly)
        assistant = Assistant.new(name: "Test", persona: persona)
        assert_equal persona.instructions, @service.call(assistant: assistant)
      end

      test "prepends persona instructions to system prompt" do
        persona = layered_assistant_personas(:friendly)
        assistant = Assistant.new(name: "Test", persona: persona, system_prompt: "Be concise.")
        result = @service.call(assistant: assistant)
        assert_equal "#{persona.instructions}\n\n#{assistant.system_prompt}", result
      end

      test "ignores persona with blank instructions" do
        persona = layered_assistant_personas(:empty)
        assistant = Assistant.new(name: "Test", persona: persona, system_prompt: "Be helpful.")
        assert_equal "Be helpful.", @service.call(assistant: assistant)
      end
    end
  end
end
