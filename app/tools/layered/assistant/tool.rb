module Layered
  module Assistant
    # Base class for the tools an assistant can call. Subclass it in the host
    # application (app/tools/weather_tool.rb) and list the class in the tools
    # block of config/initializers/layered_assistant.rb.
    #
    #   class WeatherTool < Layered::Assistant::Tool
    #     description "Get the current weather for a city."
    #     argument :city, :string, required: true, description: "The city to look up."
    #
    #     def call(city:)
    #       { city: city, temperature_c: Weather.for(city).temperature }
    #     end
    #   end
    #
    # #call receives the tool's arguments as keywords and may return a string
    # or anything that responds to #to_json. Raising is safe: the error is
    # reported back to the model rather than failing the response.
    class Tool
      class InvalidArguments < StandardError; end

      TYPES = %w[string integer number boolean array object].freeze

      class << self
        # The name the model calls the tool by. Defaults to the class name
        # without its Tool suffix, namespaces separated by hyphens:
        # "Weather::ForecastTool" becomes "weather-forecast".
        #
        # Alone among the declarations here this is not inherited: two tools
        # answering to one name would collide in the registry, so a subclass
        # derives its own from its class name unless it says otherwise.
        def tool_name(value = nil)
          @tool_name = value.to_s if value
          @tool_name || default_tool_name
        end

        def description(value = nil)
          @description = value if value
          @description || from_superclass(:description)
        end

        # Whether the tool may be offered to a public assistant, matching
        # `public` on Assistant. Tools are private by default: a public
        # assistant is talking to an anonymous visitor, and its conversations
        # have no owner to scope a tool's reads to. Opt in with
        # `self.public = true`.
        #
        # Written as an attribute rather than a `public true` DSL on purpose.
        # `public` is Ruby's own method-visibility keyword, so a class method
        # of that name would shadow it - and a tool whose body used a bare
        # `public` to reopen visibility would silently mark itself callable by
        # anonymous visitors. Too sharp an edge for a security flag.
        attr_writer :public

        def public?
          return @public unless @public.nil?

          from_superclass(:public?) || false
        end

        # Who may call the tool, as a block returning truthy to allow it:
        #
        #   permit { |conversation| conversation.user&.admin? }
        #
        # This narrows what an assistant has been given rather than replacing
        # it: a tool still has to be selected on the assistant before anyone
        # can call it. An unpermitted tool is left out of the definitions sent
        # to the provider, and refused if the model asks for it anyway from an
        # earlier turn's history.
        #
        # Inherited like the other declarations, so a tool subclassed to share
        # logic keeps its parent's policy unless it declares its own.
        def permit(&block)
          @permit = block if block
          @permit || from_superclass(:permit)
        end

        # Whether a call has to be approved by the person talking before it
        # runs. Reads are usually fine unattended; anything that writes, spends
        # or sends is worth asking about first.
        #
        #   consent :always
        #
        # A tool that asks for consent is withheld from a conversation with no
        # user, an anonymous visitor having nobody to ask. Inherited like the
        # other declarations.
        CONSENT = %i[never always].freeze

        def consent(value = nil)
          if value
            raise ::ArgumentError, "Unsupported consent: #{value}" unless CONSENT.include?(value.to_sym)

            @consent = value.to_sym
          end

          @consent || from_superclass(:consent) || :never
        end

        def consent_required?
          consent == :always
        end

        def argument(name, type = :string, required: false, description: nil, enum: nil, items: nil)
          type = type.to_s
          raise ::ArgumentError, "Unsupported argument type: #{type}" unless TYPES.include?(type)

          own_arguments << {
            name: name.to_sym,
            type: type,
            required: required,
            description: description,
            enum: enum,
            items: items&.to_s
          }
        end

        # A subclass adds to the arguments it inherits rather than replacing
        # them. Redeclaring one by name overrides it where it already sits,
        # so a subclass can narrow a parent's argument without moving it.
        def arguments
          (from_superclass(:arguments).to_a + own_arguments).index_by { |argument| argument[:name] }.values
        end

        # The JSON Schema for the arguments, as sent to the provider.
        def schema
          properties = arguments.each_with_object({}) do |argument, hash|
            property = { type: argument[:type] }
            property[:description] = argument[:description] if argument[:description]
            property[:enum] = argument[:enum] if argument[:enum]
            property[:items] = { type: argument[:items] } if argument[:items]
            hash[argument[:name].to_s] = property
          end

          {
            type: "object",
            properties: properties,
            required: arguments.select { |argument| argument[:required] }.map { |argument| argument[:name].to_s },
            additionalProperties: false
          }
        end

        # Whether a conversation may be offered the tool at all. Cheapest
        # gate first: a private tool needs an owner to scope its reads to, a
        # tool that asks for consent needs somebody to ask, the host's
        # authorize_tool block may narrow every tool at once, and the tool's
        # own permit block has the last word.
        def available_for?(conversation)
          return false unless public? || conversation&.owner.present?
          return false if consent_required? && conversation&.user.blank?
          return false unless host_permits?(conversation)

          permits?(conversation)
        end

        # Checks what the model supplied against the schema and returns it as
        # keyword arguments. Unknown keys are dropped rather than rejected -
        # models invent them occasionally, and the call is still answerable.
        def cast_arguments(raw)
          supplied = raw.is_a?(Hash) ? raw.symbolize_keys : {}

          missing = arguments.select { |argument| argument[:required] }.map { |argument| argument[:name] } - supplied.keys
          if missing.any?
            raise InvalidArguments, "missing required argument(s): #{missing.join(', ')}"
          end

          supplied.slice(*arguments.map { |argument| argument[:name] })
        end

        private

        def own_arguments
          @arguments ||= []
        end

        # Declarations are held in class instance variables, which subclasses
        # do not inherit, so each reader asks its parent for what it was not
        # given itself. Without this a tool subclassed to share logic would
        # lose its parent's description and arguments and still be callable -
        # offered to the model with an empty schema.
        #
        # Not named `inherited`: that is Ruby's own hook for being subclassed,
        # and overriding it breaks every subclass of Tool.
        def from_superclass(reader)
          superclass.public_send(reader) if superclass.respond_to?(reader)
        end

        def default_tool_name
          name.underscore.sub(/_tool\z/, "").tr("/", "-")
        end

        def permits?(conversation)
          block = permit
          return true unless block

          allowed?("The permit block for '#{tool_name}'") do
            block.arity.zero? ? block.call : block.call(conversation)
          end
        end

        def host_permits?(conversation)
          block = Layered::Assistant.authorize_tool_block
          return true unless block

          allowed?("The authorize_tool block") { block.call(self, conversation) }
        end

        # A policy that raises denies the tool rather than failing the whole
        # response: a broken block should not hand the tool over, and should
        # not take the conversation down with it either.
        def allowed?(subject)
          !!yield
        rescue => e
          Rails.logger.error("#{subject} raised #{e.class}: #{e.message} - denying the tool")
          false
        end
      end

      attr_reader :message

      def initialize(message: nil)
        @message = message
      end

      def conversation
        message&.conversation
      end

      # The record the conversation is scoped to - use it to keep a tool's
      # reads and writes inside the caller's boundary. Nil for a conversation
      # with a public assistant.
      def owner
        conversation&.owner
      end

      # The person doing the talking. The same as `owner` until an owner
      # block scopes records to something else, such as an organisation, at
      # which point `owner` is the organisation and this is the member of it
      # who asked. Nil for an anonymous visitor on a public assistant.
      #
      # Scope reads and writes to `owner`; use this to answer questions about
      # the person, or to narrow further within the owner's boundary.
      def user
        conversation&.user
      end

      def call(**)
        raise NotImplementedError, "#{self.class.name} must implement #call"
      end
    end
  end
end
