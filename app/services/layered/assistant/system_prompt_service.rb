module Layered
  module Assistant
    class SystemPromptService
      def call(assistant:)
        [assistant.persona&.instructions, assistant.instructions].compact_blank.join("\n\n").presence
      end
    end
  end
end
