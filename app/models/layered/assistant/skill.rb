module Layered
  module Assistant
    class Skill < ApplicationRecord
      include Ownable

      # UID
      has_secure_token :uid

      # Associations
      has_many :assistant_skills, dependent: :restrict_with_error
      has_many :assistants, through: :assistant_skills

      # Validations
      validates :name, presence: true

      # Scopes
      scope :by_name, -> { order(name: :asc, created_at: :desc) }
      scope :by_created_at, -> { order(created_at: :desc) }
    end
  end
end
