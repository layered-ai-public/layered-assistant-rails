module Layered
  module Assistant
    class ResourcesController < Layered::Resource::ResourcesController
      include Layered::Assistant::Authorization

      rescue_from ActiveRecord::InvalidForeignKey do
        redirect_to @resource.after_save_path(self, @record),
          alert: "#{@resource.model.model_name.human} could not be deleted because it is in use."
      end
    end
  end
end
