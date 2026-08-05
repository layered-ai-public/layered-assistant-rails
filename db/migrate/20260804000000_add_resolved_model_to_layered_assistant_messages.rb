class AddResolvedModelToLayeredAssistantMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :layered_assistant_messages, :resolved_model, :string
  end
end
