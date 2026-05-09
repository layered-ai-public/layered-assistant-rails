module Layered
  module Assistant
    class Skill < ApplicationRecord
      # UID
      has_secure_token :uid

      # Associations
      belongs_to :owner, polymorphic: true, optional: true
      has_many :assistant_skills, dependent: :restrict_with_error
      has_many :assistants, through: :assistant_skills

      # Validations
      validates :name, presence: true

      # Scopes
      scope :owned_by, ->(user) { where(owner: user) }
      scope :by_name, -> { order(name: :asc, created_at: :desc) }
      scope :by_created_at, -> { order(created_at: :desc) }
    end
  end
end
