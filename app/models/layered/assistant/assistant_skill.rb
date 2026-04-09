module Layered
  module Assistant
    class AssistantSkill < ApplicationRecord
      # Associations
      belongs_to :assistant, counter_cache: :assistant_skills_count
      belongs_to :skill, counter_cache: :assistants_count

      # Validations
      validates :skill_id, uniqueness: { scope: :assistant_id }
    end
  end
end
