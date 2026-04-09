module Layered
  module Assistant
    class SystemPromptService
      def call(assistant:)
        parts = []

        if assistant.persona&.instructions.present?
          parts << "## Persona\n\n#{assistant.persona.instructions}"
        end

        if assistant.assistant_skills_count.positive?
          skill_sections = assistant.skills.filter_map do |s|
            "### #{s.name}\n\n#{s.instructions}" if s.instructions.present?
          end
          if skill_sections.any?
            parts << "## Skills\n\n#{skill_sections.join("\n\n---\n\n")}"
          end
        end

        parts << assistant.instructions if assistant.instructions.present?

        parts.join("\n\n").presence
      end
    end
  end
end
