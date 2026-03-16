# This migration comes from layered_assistant (originally 20260315100000)
class AddResponseTimingToLayeredAssistantMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :layered_assistant_messages, :ttft_ms, :integer
    add_column :layered_assistant_messages, :response_ms, :integer
  end
end
