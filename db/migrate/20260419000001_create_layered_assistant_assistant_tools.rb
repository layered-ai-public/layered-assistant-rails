class CreateLayeredAssistantAssistantTools < ActiveRecord::Migration[8.0]
  def change
    create_table :layered_assistant_assistant_tools, if_not_exists: true do |t|
      t.references :assistant, null: false, foreign_key: { to_table: :layered_assistant_assistants }
      t.references :tool, null: false, foreign_key: { to_table: :layered_assistant_tools }
      t.timestamps
    end

    add_index :layered_assistant_assistant_tools, [:assistant_id, :tool_id], unique: true, name: "idx_assistant_tools_on_assistant_and_tool"

    add_column :layered_assistant_assistants, :assistant_tools_count, :bigint, default: 0, null: false
  end
end
