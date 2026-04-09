class CreateLayeredAssistantAssistantSkills < ActiveRecord::Migration[8.0]
  def change
    create_table :layered_assistant_assistant_skills, if_not_exists: true do |t|
      t.references :assistant, null: false, foreign_key: { to_table: :layered_assistant_assistants }
      t.references :skill, null: false, foreign_key: { to_table: :layered_assistant_skills }
      t.timestamps
    end

    add_index :layered_assistant_assistant_skills, [:assistant_id, :skill_id], unique: true, name: "idx_assistant_skills_on_assistant_and_skill"

    add_column :layered_assistant_assistants, :assistant_skills_count, :bigint, default: 0, null: false
  end
end
