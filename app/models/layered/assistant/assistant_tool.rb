module Layered
  module Assistant
    class AssistantTool < ApplicationRecord
      # Associations
      belongs_to :assistant, counter_cache: :assistant_tools_count
      belongs_to :tool, counter_cache: :assistants_count

      # Validations
      validates :tool_id, uniqueness: { scope: :assistant_id }
    end
  end
end
