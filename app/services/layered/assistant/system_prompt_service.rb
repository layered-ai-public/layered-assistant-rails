module Layered
  module Assistant
    class SystemPromptService
      def call(assistant:)
        [assistant.persona&.instructions, assistant.system_prompt].compact_blank.join("\n\n").presence
      end
    end
  end
end
