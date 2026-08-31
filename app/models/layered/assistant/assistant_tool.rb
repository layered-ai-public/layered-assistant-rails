module Layered
  module Assistant
    # One tool an assistant is allowed to call, held by the name the model
    # calls it rather than a foreign key: tools are classes in the host
    # application, not records, and the set of them changes with a deploy.
    # A name with no matching class is ignored by ToolRegistry rather than
    # raising, so removing a tool class does not break the assistants that
    # referenced it.
    class AssistantTool < ApplicationRecord
      # Associations
      belongs_to :assistant, counter_cache: :assistant_tools_count

      # Validations
      validates :tool_name, presence: true
      validates :tool_name, uniqueness: { scope: :assistant_id }
    end
  end
end
