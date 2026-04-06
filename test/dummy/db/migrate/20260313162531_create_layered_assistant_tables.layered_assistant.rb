# This migration comes from layered_assistant (originally 20260312000000)
class CreateLayeredAssistantTables < ActiveRecord::Migration[8.0]
  def change
    create_table :layered_assistant_providers, if_not_exists: true do |t|
      t.references :owner, polymorphic: true
      t.string :protocol, null: false
      t.string :name, null: false
      t.string :url
      t.string :secret
      t.boolean :enabled, default: true, null: false
      t.integer :position, null: false
      t.integer :models_count, default: 0, null: false
      t.timestamps
    end

    create_table :layered_assistant_models, if_not_exists: true do |t|
      t.references :provider, null: false, foreign_key: { to_table: :layered_assistant_providers }
      t.string :identifier, null: false
      t.string :name, null: false
      t.boolean :enabled, default: true, null: false
      t.integer :position, null: false
      t.bigint :assistants_count, default: 0, null: false
      t.bigint :messages_count, default: 0, null: false
      t.timestamps
    end

    create_table :layered_assistant_assistants, if_not_exists: true do |t|
      t.references :owner, polymorphic: true
      t.references :default_model, foreign_key: { to_table: :layered_assistant_models }
      t.string :name, null: false
      t.text :description
      t.text :system_prompt
      t.boolean :public, default: false, null: false
      t.bigint :conversations_count, default: 0, null: false
      t.timestamps

      t.string :uid, null: false
      t.index :uid, unique: true
    end

    create_table :layered_assistant_conversations, if_not_exists: true do |t|
      t.references :owner, polymorphic: true
      t.references :subject, polymorphic: true
      t.references :assistant, null: false, foreign_key: { to_table: :layered_assistant_assistants }
      t.string :name, null: false
      t.bigint :input_tokens
      t.bigint :output_tokens
      t.bigint :token_estimate
      t.bigint :messages_count, default: 0, null: false
      t.timestamps

      t.string :uid, null: false
      t.index :uid, unique: true
    end

    create_table :layered_assistant_messages, if_not_exists: true do |t|
      t.references :conversation, null: false, foreign_key: { to_table: :layered_assistant_conversations }
      t.references :model, foreign_key: { to_table: :layered_assistant_models }
      t.string :role, null: false, default: "system"
      t.text :content
      t.bigint :input_tokens
      t.bigint :output_tokens
      t.boolean :tokens_estimated, default: false, null: false
      t.timestamps

      t.string :uid, null: false
      t.index :uid, unique: true
    end
  end
end
