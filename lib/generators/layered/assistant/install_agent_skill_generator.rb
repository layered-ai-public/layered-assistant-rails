module Layered
  module Assistant
    module Generators
      class InstallAgentSkillGenerator < Rails::Generators::Base
        desc "Copy the layered-assistant-rails agent skill into the host application"

        def self.source_root
          Layered::Assistant::Engine.root
        end

        def copy_skill
          skill_source = File.join(self.class.source_root, ".claude/skills/layered-assistant-rails")
          skill_dest = ".claude/skills/layered-assistant-rails"

          directory skill_source, skill_dest
        end

        def show_instructions
          say ""
          say "Agent skill installed to .claude/skills/layered-assistant-rails/", :green
          say ""
        end
      end
    end
  end
end
