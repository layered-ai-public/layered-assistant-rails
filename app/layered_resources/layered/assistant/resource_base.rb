module Layered
  module Assistant
    class ResourceBase < Layered::Resource::Base
      owned_by :owner, via: :l_ui_current_user
    end
  end
end
