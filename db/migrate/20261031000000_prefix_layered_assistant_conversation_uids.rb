class PrefixLayeredAssistantConversationUids < ActiveRecord::Migration[8.0]
  # Conversation uids become conversation_<uuid>. Existing tokens are
  # replaced, so old conversation URLs stop resolving; the integer primary
  # key is untouched.
  def up
    select_values("SELECT id FROM layered_assistant_conversations").each do |id|
      execute "UPDATE layered_assistant_conversations SET uid = #{quote("conversation_#{SecureRandom.uuid}")} WHERE id = #{id.to_i}"
    end
  end

  def down
    # Irreversible data change; the prefixed uids remain valid.
  end
end
