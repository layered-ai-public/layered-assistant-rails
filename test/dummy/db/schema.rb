# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_19_093156) do
  create_table "layered_assistant_assistant_skills", force: :cascade do |t|
    t.integer "assistant_id", null: false
    t.datetime "created_at", null: false
    t.integer "skill_id", null: false
    t.datetime "updated_at", null: false
    t.index ["assistant_id", "skill_id"], name: "idx_assistant_skills_on_assistant_and_skill", unique: true
    t.index ["assistant_id"], name: "index_layered_assistant_assistant_skills_on_assistant_id"
    t.index ["skill_id"], name: "index_layered_assistant_assistant_skills_on_skill_id"
  end

  create_table "layered_assistant_assistant_tools", force: :cascade do |t|
    t.integer "assistant_id", null: false
    t.datetime "created_at", null: false
    t.integer "tool_id", null: false
    t.datetime "updated_at", null: false
    t.index ["assistant_id", "tool_id"], name: "idx_assistant_tools_on_assistant_and_tool", unique: true
    t.index ["assistant_id"], name: "index_layered_assistant_assistant_tools_on_assistant_id"
    t.index ["tool_id"], name: "index_layered_assistant_assistant_tools_on_tool_id"
  end

  create_table "layered_assistant_assistants", force: :cascade do |t|
    t.bigint "assistant_skills_count", default: 0, null: false
    t.bigint "assistant_tools_count", default: 0, null: false
    t.bigint "conversations_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "default_model_id"
    t.text "description"
    t.text "instructions"
    t.string "name", null: false
    t.integer "owner_id"
    t.string "owner_type"
    t.integer "persona_id"
    t.boolean "public", default: false, null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["default_model_id"], name: "index_layered_assistant_assistants_on_default_model_id"
    t.index ["owner_type", "owner_id"], name: "index_layered_assistant_assistants_on_owner"
    t.index ["persona_id"], name: "index_layered_assistant_assistants_on_persona_id"
    t.index ["uid"], name: "index_layered_assistant_assistants_on_uid", unique: true
  end

  create_table "layered_assistant_conversations", force: :cascade do |t|
    t.integer "assistant_id", null: false
    t.datetime "created_at", null: false
    t.bigint "input_tokens"
    t.bigint "messages_count", default: 0, null: false
    t.string "name", null: false
    t.bigint "output_tokens"
    t.integer "owner_id"
    t.string "owner_type"
    t.integer "subject_id"
    t.string "subject_type"
    t.bigint "token_estimate"
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["assistant_id"], name: "index_layered_assistant_conversations_on_assistant_id"
    t.index ["owner_type", "owner_id"], name: "index_layered_assistant_conversations_on_owner"
    t.index ["subject_type", "subject_id"], name: "index_layered_assistant_conversations_on_subject"
    t.index ["uid"], name: "index_layered_assistant_conversations_on_uid", unique: true
  end

  create_table "layered_assistant_messages", force: :cascade do |t|
    t.text "content"
    t.integer "conversation_id", null: false
    t.datetime "created_at", null: false
    t.bigint "input_tokens"
    t.integer "model_id"
    t.bigint "output_tokens"
    t.integer "response_ms"
    t.string "role", default: "system", null: false
    t.boolean "stopped", default: false, null: false
    t.boolean "tokens_estimated", default: false, null: false
    t.string "tool_call_id"
    t.text "tool_calls"
    t.integer "ttft_ms"
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id"], name: "index_layered_assistant_messages_on_conversation_id"
    t.index ["model_id"], name: "index_layered_assistant_messages_on_model_id"
    t.index ["uid"], name: "index_layered_assistant_messages_on_uid", unique: true
  end

  create_table "layered_assistant_models", force: :cascade do |t|
    t.bigint "assistants_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.boolean "enabled", default: true, null: false
    t.string "identifier", null: false
    t.bigint "messages_count", default: 0, null: false
    t.string "name", null: false
    t.integer "position", null: false
    t.integer "provider_id", null: false
    t.datetime "updated_at", null: false
    t.index ["provider_id"], name: "index_layered_assistant_models_on_provider_id"
  end

  create_table "layered_assistant_personas", force: :cascade do |t|
    t.bigint "assistants_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.text "instructions"
    t.string "name", null: false
    t.integer "owner_id"
    t.string "owner_type"
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id"], name: "index_layered_assistant_personas_on_owner"
    t.index ["uid"], name: "index_layered_assistant_personas_on_uid", unique: true
  end

  create_table "layered_assistant_providers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "enabled", default: true, null: false
    t.integer "models_count", default: 0, null: false
    t.string "name", null: false
    t.integer "owner_id"
    t.string "owner_type"
    t.integer "position", null: false
    t.string "protocol", null: false
    t.string "secret"
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["owner_type", "owner_id"], name: "index_layered_assistant_providers_on_owner"
  end

  create_table "layered_assistant_skills", force: :cascade do |t|
    t.bigint "assistants_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.text "instructions"
    t.string "name", null: false
    t.integer "owner_id"
    t.string "owner_type"
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id"], name: "index_layered_assistant_skills_on_owner"
    t.index ["uid"], name: "index_layered_assistant_skills_on_uid", unique: true
  end

  create_table "layered_assistant_tools", force: :cascade do |t|
    t.bigint "assistants_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.text "input_schema"
    t.string "name", null: false
    t.integer "owner_id"
    t.string "owner_type"
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id"], name: "index_layered_assistant_tools_on_owner"
    t.index ["uid"], name: "index_layered_assistant_tools_on_uid", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.datetime "locked_at"
    t.string "name", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.string "unconfirmed_email"
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "layered_assistant_assistant_skills", "layered_assistant_assistants", column: "assistant_id"
  add_foreign_key "layered_assistant_assistant_skills", "layered_assistant_skills", column: "skill_id"
  add_foreign_key "layered_assistant_assistant_tools", "layered_assistant_assistants", column: "assistant_id"
  add_foreign_key "layered_assistant_assistant_tools", "layered_assistant_tools", column: "tool_id"
  add_foreign_key "layered_assistant_assistants", "layered_assistant_models", column: "default_model_id"
  add_foreign_key "layered_assistant_assistants", "layered_assistant_personas", column: "persona_id"
  add_foreign_key "layered_assistant_conversations", "layered_assistant_assistants", column: "assistant_id"
  add_foreign_key "layered_assistant_messages", "layered_assistant_conversations", column: "conversation_id"
  add_foreign_key "layered_assistant_messages", "layered_assistant_models", column: "model_id"
  add_foreign_key "layered_assistant_models", "layered_assistant_providers", column: "provider_id"
end
