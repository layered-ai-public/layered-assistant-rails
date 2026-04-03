module Layered
  module Assistant
    class Persona < ApplicationRecord
      # UID
      has_secure_token :uid

      # Associations
      belongs_to :owner, polymorphic: true, optional: true
      has_many :assistants, dependent: :restrict_with_error

      # Validations
      validates :name, presence: true

      # Scopes
      scope :by_name, -> { order(name: :asc, created_at: :desc) }
      scope :by_created_at, -> { order(created_at: :desc) }
    end
  end
end
