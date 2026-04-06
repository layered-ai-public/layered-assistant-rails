module Layered
  module Assistant
    class SystemPromptService
      def call(assistant:)
        parts = []

        if assistant.persona&.instructions.present?
          parts << "**Persona**\n\n#{assistant.persona.instructions}"
        end

        parts << assistant.instructions if assistant.instructions.present?

        parts.join("\n\n").presence
      end
    end
  end
end
