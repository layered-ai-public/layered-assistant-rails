module Layered
  module Assistant
    module Public
      class AssistantsController < ApplicationController
        before_action :set_public_assistant, only: [:show]

        def index
          @pagy, @assistants = pagy(Assistant.publicly_available.by_name)
        end

        def show
        end
      end
    end
  end
end
