module Layered
  module Assistant
    class SystemPromptService
      def call(assistant:)
        parts = []

        if assistant.persona&.instructions.present?
          parts << "**Persona**\n\n#{assistant.persona.instructions}"
        end

        if assistant.skills.any?
          skill_instructions = assistant.skills.filter_map { |s| s.instructions.presence }
          if skill_instructions.any?
            parts << "**Skills**\n\n#{skill_instructions.join("\n\n")}"
          end
        end

        parts << assistant.instructions if assistant.instructions.present?

        parts.join("\n\n").presence
      end
    end
  end
end
