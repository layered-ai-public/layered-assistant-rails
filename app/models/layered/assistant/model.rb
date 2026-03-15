module Layered
  module Assistant
    class Model < ApplicationRecord
      # Positioning
      positioned on: :provider

      # Associations
      belongs_to :provider, counter_cache: true
      has_many :messages, dependent: :restrict_with_error
      has_many :assistants, foreign_key: :default_model_id, dependent: :restrict_with_error, inverse_of: :default_model

      # Validations
      validates :name, :identifier, presence: true

      # Scopes
      scope :enabled, -> { where(enabled: true) }
      scope :available, -> { enabled.eager_load(:provider).merge(Provider.enabled).merge(Provider.sorted).sorted }
      scope :sorted, -> { order(position: :asc, name: :asc) }
    end
  end
end
