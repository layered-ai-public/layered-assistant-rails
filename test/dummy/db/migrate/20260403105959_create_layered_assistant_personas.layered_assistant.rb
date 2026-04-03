# This migration comes from layered_assistant (originally 20260403000000)
class CreateLayeredAssistantPersonas < ActiveRecord::Migration[8.1]
  def change
    create_table :layered_assistant_personas, if_not_exists: true do |t|
      t.string :uid, null: false, index: { unique: true }
      t.references :owner, polymorphic: true
      t.string :name, null: false
      t.text :description
      t.text :instructions
      t.bigint :assistants_count, default: 0, null: false
      t.timestamps
    end
  end
end
