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

      def to_param
        uid
      end

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
        with_lock do
          message = messages.where(role: :assistant, stopped: false).order(created_at: :desc).first
          return false unless message

          attrs = {
            stopped: true,
            output_tokens: TokenEstimator.estimate(message.content) || 0,
            tokens_estimated: true
          }

          if message.input_tokens.nil?
            prior_content = messages.where("created_at < ?", message.created_at).pluck(:content).compact.join(" ")
            attrs[:input_tokens] = TokenEstimator.estimate(prior_content) || 0
          end

          message.update!(attrs)
          update_token_totals!
          message.reload
          message.broadcast_updated
          message.broadcast_response_complete
        end

        true
      end

      def update_name_from_content!(content)
        return unless name == self.class.default_name
        return if content.blank?

        old_name = name
        update!(name: content.truncate(60))
        broadcast_name_updated(old_name)
      end

      def broadcast_name_updated(old_name)
        css_class = "#{ActionView::RecordIdentifier.dom_id(self)}_name"
        Turbo::StreamsChannel.broadcast_action_to(
          self,
          action: :update_conversation_name,
          targets: ".#{css_class}",
          attributes: { name: name, "old-name": old_name }
        )
      end
    end
  end
end
