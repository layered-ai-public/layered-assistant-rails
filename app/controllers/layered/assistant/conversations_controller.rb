module Layered
  module Assistant
    # Conversations are a layered resource for listing, starting, renaming
    # and deleting them; only `show` - the conversation itself - and `stop`
    # are this engine's own.
    class ConversationsController < ResourcesController
      include StoppableResponse

      before_action :set_conversation, only: [ :stop ]
      before_action :drop_assistant_column, only: [ :index ], if: -> { params[:assistant_id] }
      before_action :scope_choice_fields, only: [ :new, :create, :edit, :update ]

      def show
        super
        @conversation = @record
        @messages = @conversation.messages.includes(:model).by_created_at
        @models = scoped_models
        @selected_model_id = @messages.last&.model_id || @conversation.assistant.default_model_id || @models.first&.id
      end

      private

      # `stop` is a custom member action, so the gem has loaded @record.
      def set_conversation
        @conversation = @record
      end

      # Listed under an assistant, every row would name the same one.
      def drop_assistant_column
        @columns = @columns.reject { |column| column[:attribute] == :assistant_id }
      end

      # The assistant is chosen once, when the conversation is started, and
      # only from the owner's own.
      def scope_choice_fields
        if action_name.in?(%w[new create])
          assistants = scoped(Assistant).by_name.map { |assistant| [ assistant.name, assistant.id ] }
          @fields = @fields.map { |field| field[:attribute] == :assistant_id ? field.merge(collection: assistants) : field }
        else
          @fields = @fields.reject { |field| field[:attribute] == :assistant_id }
        end
      end

      # An out-of-scope assistant 404s rather than being silently dropped,
      # matching how a record itself is looked up. A blank one leaves any
      # assistant the route already chose in place.
      def layered_resource_params
        attributes = super
        return attributes.except(:assistant_id) unless action_name == "create"

        if attributes[:assistant_id].present?
          attributes[:assistant_id] = scoped(Assistant).find(attributes[:assistant_id]).id
        else
          attributes.delete(:assistant_id)
        end
        attributes[:name] = Conversation.default_name if attributes[:name].blank?
        attributes
      end
    end
  end
end
