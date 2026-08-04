module Layered
  module Assistant
    module Ownable
      extend ActiveSupport::Concern

      included do
        belongs_to :owner, polymorphic: true, optional: true

        scope :owned_by, ->(owner) { owner ? where(owner: owner) : none }
      end
    end
  end
end
