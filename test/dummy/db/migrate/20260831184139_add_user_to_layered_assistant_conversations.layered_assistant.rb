# This migration comes from layered_assistant (originally 20260901000001)
class AddUserToLayeredAssistantConversations < ActiveRecord::Migration[8.0]
  def change
    add_reference :layered_assistant_conversations, :user, polymorphic: true, null: true, index: true
  end
end
