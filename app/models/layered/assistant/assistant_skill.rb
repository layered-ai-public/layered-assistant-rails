module Layered
  module Assistant
    class AssistantSkill < ApplicationRecord
      # Associations
      belongs_to :assistant
      belongs_to :skill, counter_cache: :assistants_count
    end
  end
end
