# This migration comes from layered_assistant (originally 20260317000000)
class NormaliseProviderProtocolValues < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE layered_assistant_providers SET protocol = 'anthropic' WHERE protocol = 'Anthropic'"
    execute "UPDATE layered_assistant_providers SET protocol = 'openai' WHERE protocol = 'OpenAI'"
  end

  def down
    execute "UPDATE layered_assistant_providers SET protocol = 'Anthropic' WHERE protocol = 'anthropic'"
    execute "UPDATE layered_assistant_providers SET protocol = 'OpenAI' WHERE protocol = 'openai'"
  end
end
