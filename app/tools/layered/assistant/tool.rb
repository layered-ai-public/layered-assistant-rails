module Layered
  module Assistant
    # Base class for the tools an assistant can call. Subclass it in the host
    # application (app/tools/weather_tool.rb) and list the class in the tools
    # block of config/initializers/layered_assistant.rb.
    #
    #   class WeatherTool < Layered::Assistant::Tool
    #     description "Get the current weather for a city."
    #
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
        def tool_name(value = nil)
          @tool_name = value.to_s if value
          @tool_name || default_tool_name
        end

        def description(value = nil)
          @description = value if value
          @description
        end

        # Tools are offered only to conversations that have an owner, so that a
        # public assistant talking to an anonymous visitor cannot reach into the
        # host application by default. Opt in with `requires_owner false`.
        def requires_owner(value = nil)
          @requires_owner = value unless value.nil?
          @requires_owner.nil? ? true : @requires_owner
        end

        def argument(name, type = :string, required: false, description: nil, enum: nil, items: nil)
          type = type.to_s
          raise ::ArgumentError, "Unsupported argument type: #{type}" unless TYPES.include?(type)

          arguments << {
            name: name.to_sym,
            type: type,
            required: required,
            description: description,
            enum: enum,
            items: items&.to_s
          }
        end

        def arguments
          @arguments ||= []
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

        def available_for?(conversation)
          !requires_owner || conversation&.owner.present?
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

        def default_tool_name
          name.underscore.sub(/_tool\z/, "").tr("/", "-")
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

      def call(**)
        raise NotImplementedError, "#{self.class.name} must implement #call"
      end
    end
  end
end
