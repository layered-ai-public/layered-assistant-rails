# This migration comes from layered_assistant (originally 20260406000002)
class CreateLayeredAssistantAssistantSkills < ActiveRecord::Migration[8.0]
  def change
    create_table :layered_assistant_assistant_skills, if_not_exists: true do |t|
      t.references :assistant, null: false, foreign_key: { to_table: :layered_assistant_assistants }
      t.references :skill, null: false, foreign_key: { to_table: :layered_assistant_skills }
      t.integer :position
      t.timestamps
    end

    add_index :layered_assistant_assistant_skills, [:assistant_id, :skill_id], unique: true, name: "idx_assistant_skills_on_assistant_and_skill"
  end
end
