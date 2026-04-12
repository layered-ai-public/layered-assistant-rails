module Layered
  module Assistant
    class Persona < ApplicationRecord
      include Layered::ManagedResource::Resource

      def self.l_managed_resource_columns
        [
          { attribute: :name, primary: true },
          { attribute: :instructions, label: "Instructions" },
          { attribute: :created_at, label: "Created" }
        ]
      end

      def self.l_managed_resource_fields
        [
          { attribute: :name, required: true },
          { attribute: :instructions, required: true, as: :text }
        ]
      end

      def self.l_managed_resource_search_fields
        [:name, :instructions]
      end

      # UID
      has_secure_token :uid

      # Associations
      belongs_to :owner, polymorphic: true, optional: true
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
