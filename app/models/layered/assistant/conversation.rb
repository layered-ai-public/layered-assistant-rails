module Layered
  module Assistant
    class Conversation < ApplicationRecord
      # UID
      has_secure_token :uid

      # Associations
      belongs_to :assistant, counter_cache: true
      belongs_to :owner, polymorphic: true, optional: true
      belongs_to :subject, polymorphic: true, optional: true
      has_many :messages, dependent: :destroy

      # Validations
      validates :name, presence: true

      # Scopes
      scope :by_name, -> { order(name: :asc, created_at: :desc) }
      scope :by_created_at, -> { order(created_at: :desc) }

      # Name
      def update_token_totals!
        input = messages.sum(:input_tokens)
        output = messages.sum(:output_tokens)
        update!(input_tokens: input, output_tokens: output, token_estimate: input + output)
      end

      def self.default_name
        "New conversation"
      end

      def stop_response!
        message = messages.where(role: :assistant, stopped: false).order(created_at: :desc).first
        return unless message

        message.with_lock do
          return if message.stopped?

          estimated = TokenEstimator.estimate(message.content)
          message.update!(stopped: true, output_tokens: estimated, tokens_estimated: true)
          update_token_totals!
          message.broadcast_updated
          message.broadcast_response_complete
        end
      end

      def update_name_from_content!(content)
        return unless name == self.class.default_name
        return if content.blank?

        update!(name: content.truncate(60))
      end
    end
  end
end
