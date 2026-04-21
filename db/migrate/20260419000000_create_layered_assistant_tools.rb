class CreateLayeredAssistantTools < ActiveRecord::Migration[8.0]
  def change
    create_table :layered_assistant_tools, if_not_exists: true do |t|
      t.string :uid, null: false, index: { unique: true }
      t.references :owner, polymorphic: true
      t.string :name, null: false
      t.text :description
      t.text :input_schema
      t.bigint :assistants_count, default: 0, null: false
      t.timestamps
    end
  end
end
