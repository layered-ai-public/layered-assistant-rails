class AddToolUseToLayeredAssistantMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :layered_assistant_messages, :tool_calls, :text
    add_column :layered_assistant_messages, :tool_call_id, :string
  end
end
