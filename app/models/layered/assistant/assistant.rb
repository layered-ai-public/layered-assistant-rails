module Layered
  module Assistant
    class Assistant < ApplicationRecord
      # UID
      has_secure_token :uid

      # Associations
      belongs_to :owner, polymorphic: true, optional: true
      belongs_to :default_model, class_name: "Layered::Assistant::Model", optional: true, counter_cache: :assistants_count
      belongs_to :persona, optional: true, counter_cache: :assistants_count
      has_many :conversations, dependent: :destroy

      # Validations
      validates :name, presence: true
      validates :default_model, presence: true, if: :public?
      validate :persona_belongs_to_owner

      # Scopes
      scope :by_name, -> { order(name: :asc, created_at: :desc) }
      scope :by_created_at, -> { order(created_at: :desc) }
      scope :publicly_available, -> { where(public: true) }

      private

      def persona_belongs_to_owner
        return if persona.blank? || owner.blank?
        return if persona.owner_type == owner_type && persona.owner_id == owner_id

        errors.add(:persona, "must belong to the same owner")
      end
    end
  end
end
