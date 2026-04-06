class AddResponseTimingToLayeredAssistantMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :layered_assistant_messages, :ttft_ms, :integer
    add_column :layered_assistant_messages, :response_ms, :integer
  end
end
