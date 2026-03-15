module Layered
  module Assistant
    module StoppableResponse
      def stop
        @conversation.stop_response!
        head :ok
      end
    end
  end
end
