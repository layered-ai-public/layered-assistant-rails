module Layered
  module Assistant
    class Tool < ApplicationRecord
      # UID
      has_secure_token :uid

      # Associations
      belongs_to :owner, polymorphic: true, optional: true
      has_many :assistant_tools, dependent: :restrict_with_error
      has_many :assistants, through: :assistant_tools

      # Validations
      validates :name, presence: true

      # Scopes
      scope :by_name, -> { order(name: :asc, created_at: :desc) }
      scope :by_created_at, -> { order(created_at: :desc) }

      def to_tool_definition
        definition = { name: name, description: description.to_s }
        definition[:input_schema] = parsed_input_schema if input_schema.present?
        definition
      end

      private

      def parsed_input_schema
        JSON.parse(input_schema).deep_symbolize_keys
      rescue JSON::ParserError
        { type: "object", properties: {} }
      end
    end
  end
end
