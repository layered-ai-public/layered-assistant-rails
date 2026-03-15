module Layered
  module Assistant
    module Public
      module SessionConversations
        extend ActiveSupport::Concern

        private

        def session_conversation_ids
          session[:layered_assistant_conversation_ids] ||= []
        end

        MAX_SESSION_CONVERSATIONS = 50

        def add_conversation_to_session(conversation)
          ids = session_conversation_ids
          ids << conversation.id unless ids.include?(conversation.id)
          ids.shift while ids.size > MAX_SESSION_CONVERSATIONS
        end

        def find_session_conversation(id)
          id = id.to_i
          unless session_conversation_ids.include?(id)
            raise ActiveRecord::RecordNotFound, "Conversation not found in session"
          end

          Conversation.joins(:assistant).merge(Assistant.publicly_available).find(id)
        rescue ActiveRecord::RecordNotFound
          remove_conversation_from_session(id)
          raise
        end

        def remove_conversation_from_session(id)
          session_conversation_ids.delete(id.to_i)
        end

        def existing_session_conversation_for(assistant)
          return nil if session_conversation_ids.empty?

          Conversation
            .joins(:assistant)
            .merge(Assistant.publicly_available)
            .where(id: session_conversation_ids, assistant: assistant)
            .order(created_at: :desc)
            .first
        end
      end
    end
  end
end
