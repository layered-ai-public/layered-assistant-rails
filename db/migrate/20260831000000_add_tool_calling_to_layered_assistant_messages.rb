class AddToolCallingToLayeredAssistantMessages < ActiveRecord::Migration[8.0]
  def change
    # Set on an assistant message: the tool calls the model asked for.
    add_column :layered_assistant_messages, :tool_calls, :json

    # Set on a tool message: the call it answers, and what it was called with.
    add_column :layered_assistant_messages, :tool_call_id, :string
    add_column :layered_assistant_messages, :tool_name, :string
    add_column :layered_assistant_messages, :tool_arguments, :text
  end
end
