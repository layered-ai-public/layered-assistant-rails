module Layered
  module Assistant
    module Public
      module SessionConversations
        extend ActiveSupport::Concern

        private

        def session_conversation_uids
          session[:layered_assistant_conversation_uids] ||= []
        end

        MAX_SESSION_CONVERSATIONS = 50

        def add_conversation_to_session(conversation)
          uids = session_conversation_uids
          uids << conversation.uid unless uids.include?(conversation.uid)
          uids.shift while uids.size > MAX_SESSION_CONVERSATIONS
        end

        def find_session_conversation(uid)
          unless session_conversation_uids.include?(uid)
            raise ActiveRecord::RecordNotFound, "Conversation not found in session"
          end

          Conversation.joins(:assistant).merge(Assistant.publicly_available).find_by!(uid: uid)
        rescue ActiveRecord::RecordNotFound
          remove_conversation_from_session(uid)
          raise
        end

        def remove_conversation_from_session(uid)
          session_conversation_uids.delete(uid)
        end

        def existing_session_conversation_for(assistant)
          return nil if session_conversation_uids.empty?

          Conversation
            .joins(:assistant)
            .merge(Assistant.publicly_available)
            .where(uid: session_conversation_uids, assistant: assistant)
            .order(created_at: :desc)
            .first
        end
      end
    end
  end
end
