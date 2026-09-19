# This migration comes from layered_assistant (originally 20260919000000)
class AddToolStatusToLayeredAssistantMessages < ActiveRecord::Migration[8.0]
  def change
    # Set on a tool message whose tool asked to be approved before it ran.
    # Null for a call that needed no consent, which is every call made before
    # this column existed.
    add_column :layered_assistant_messages, :tool_status, :string
  end
end
