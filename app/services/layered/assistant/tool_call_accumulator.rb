module Layered
  module Assistant
    # Collects the tool calls a streaming response asks for. Both protocols
    # send them piecemeal - an opening fragment naming the tool, then the
    # arguments as JSON string fragments - so fragments are merged by key and
    # kept in arrival order.
    #
    # Calls are stored in the OpenAI wire shape, which carries everything both
    # protocols need and keeps one representation in the database.
    class ToolCallAccumulator
      def initialize
        @calls = {}
      end

      def add(key:, id: nil, name: nil, arguments: nil)
        call = @calls[key] ||= { "id" => nil, "type" => "function", "function" => { "name" => nil, "arguments" => +"" } }

        call["id"] ||= id
        call["function"]["name"] ||= name
        call["function"]["arguments"] << arguments.to_s if arguments

        call
      end

      def any?
        @calls.any?
      end

      def to_a
        @calls.values.map do |call|
          arguments = call["function"]["arguments"]
          call.merge("function" => call["function"].merge("arguments" => arguments.presence || "{}"))
        end
      end
    end
  end
end
