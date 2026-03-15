class AddStoppedToLayeredAssistantMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :layered_assistant_messages, :stopped, :boolean, default: false, null: false
  end
end
