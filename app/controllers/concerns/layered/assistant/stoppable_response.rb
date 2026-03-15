module Layered
  module Assistant
    module StoppableResponse
      def stop
        if @conversation.stop_response!
          head :ok
        else
          head :no_content
        end
      end
    end
  end
end
