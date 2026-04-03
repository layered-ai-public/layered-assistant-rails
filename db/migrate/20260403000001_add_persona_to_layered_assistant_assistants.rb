class AddPersonaToLayeredAssistantAssistants < ActiveRecord::Migration[8.1]
  def change
    add_reference :layered_assistant_assistants, :persona, foreign_key: { to_table: :layered_assistant_personas }
  end
end
