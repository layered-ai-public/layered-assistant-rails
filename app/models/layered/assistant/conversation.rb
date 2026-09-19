module Layered
  module Assistant
    class Conversation < ApplicationRecord
      include Ownable

      # UID
      has_secure_token :uid

      # Associations
      belongs_to :assistant, counter_cache: true
      # The person doing the talking, as distinct from `owner`, the record
      # this conversation is scoped to. They are the same when ownership is
      # left at its default, but an owner block scoping to an organisation
      # makes them differ - and a tool that needs to know who asked wants
      # this one, not the organisation it was asked from.
      belongs_to :user, polymorphic: true, optional: true
      belongs_to :subject, polymorphic: true, optional: true
      has_many :messages, dependent: :destroy

      # Callbacks
      after_create :create_system_message

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

      # The composer stays disabled while either is true: the assistant is
      # still writing, or a tool call has yet to reach an answer.
      def responding?
        generating? || unresolved_tool_call?
      end

      def generating?
        messages.where(role: :assistant, stopped: false, output_tokens: nil).exists?
      end

      # Whether the response was stopped where it stands. The latest assistant
      # message carries the mark, so a fresh turn clears it.
      def stopped?
        last_assistant_message&.stopped? || false
      end

      def awaiting_consent?
        pending_tool_calls.exists?
      end

      def pending_tool_calls
        messages.where(role: :tool, tool_status: :pending)
      end

      # A call that was put to the person talking and has yet to reach an
      # answer. The decision is recorded before the result is written, so a
      # call that has been answered is still unresolved until the job says
      # what came of it - a refusal included. Nothing may be sent to the model
      # until every one of them holds a result.
      def unresolved_tool_calls
        messages.where(role: :tool, content: nil).where.not(tool_status: nil)
      end

      def unresolved_tool_call?
        unresolved_tool_calls.exists?
      end

      def stop_response!
        with_lock do
          # Stopping while a tool call is unanswered is an answer: the calls
          # are abandoned and the response is not picked back up, which would
          # only ask the model to try again.
          return abandon_unresolved_tool_calls! if unresolved_tool_call?

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

      private

      def abandon_unresolved_tool_calls!
        last = nil

        unresolved_tool_calls.each do |message|
          next unless ToolRunnerService.abandon(message)

          message.broadcast_updated
          last = message
        end

        # The message that asked for the tools is already complete, with its
        # real token counts, so it is marked stopped without being estimated
        # over. That mark is what keeps an approved call still running, or a
        # job retried later, from picking the response back up.
        last_assistant_message&.update!(stopped: true)

        update_token_totals!
        last&.broadcast_response_complete
        true
      end

      def last_assistant_message
        messages.where(role: :assistant).order(created_at: :desc, id: :desc).first
      end

      def create_system_message
        prompt = SystemPromptService.new.call(assistant: assistant)
        return if prompt.blank?

        messages.create!(role: :system, content: prompt)
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
