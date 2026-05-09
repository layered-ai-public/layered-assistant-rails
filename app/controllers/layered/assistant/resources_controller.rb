module Layered
  module Assistant
    class ResourcesController < Layered::Resource::ResourcesController
      include Layered::Assistant::Authorization
    end
  end
end
