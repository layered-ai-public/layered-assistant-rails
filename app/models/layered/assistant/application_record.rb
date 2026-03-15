module Layered
  module Assistant
    class ApplicationRecord < ::ApplicationRecord
      self.abstract_class = true
    end
  end
end
