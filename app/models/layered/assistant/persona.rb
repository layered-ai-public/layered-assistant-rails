module Layered
  module Assistant
    class Persona < ApplicationRecord
      include Ownable

      # UID
      has_secure_token :uid

      # Associations
      has_many :assistants, dependent: :restrict_with_error

      # Validations
      validates :name, presence: true
      validates :instructions, presence: true

      # Scopes
      scope :by_name, -> { order(name: :asc, created_at: :desc) }
      scope :by_created_at, -> { order(created_at: :desc) }
    end
  end
end
