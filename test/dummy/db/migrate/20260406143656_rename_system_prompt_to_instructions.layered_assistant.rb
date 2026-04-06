# This migration comes from layered_assistant (originally 20260406000000)
class RenameSystemPromptToInstructions < ActiveRecord::Migration[8.0]
  def change
    rename_column :layered_assistant_assistants, :system_prompt, :instructions
  end
end
