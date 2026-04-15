class LayeredAssistantResource < Layered::ManagedResource::Base
  def self.scope(controller)
    block = Layered::Assistant.scope_block
    return model.all unless block

    controller.instance_exec(model, &block)
  end

  def self.build_record(controller)
    record = scope(controller).build
    record.owner = controller.send(:current_user) if controller.respond_to?(:current_user, true)
    record
  end
end
