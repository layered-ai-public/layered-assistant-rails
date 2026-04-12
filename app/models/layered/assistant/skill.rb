module Layered
  module Assistant
    class Skill < ApplicationRecord
      include Layered::ManagedResource::Resource

      def self.l_managed_resource_columns
        [
          { attribute: :name, primary: true },
          { attribute: :description, label: "Description" },
          { attribute: :assistants_count, label: "Assistants" },
          { attribute: :created_at, label: "Created" }
        ]
      end

      def self.l_managed_resource_fields
        [
          { attribute: :name, required: true },
          { attribute: :description, as: :text },
          { attribute: :instructions, as: :text }
        ]
      end

      def self.l_managed_resource_search_fields
        [:name, :description, :instructions]
      end

      # UID
      has_secure_token :uid

      # Associations
      belongs_to :owner, polymorphic: true, optional: true
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
