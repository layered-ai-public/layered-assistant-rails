module Layered
  module Assistant
    class ApplicationController < ActionController::Base
      include Pagy::Method
      include Layered::Assistant::Authorization

      helper Rails.application.routes.url_helpers
    end
  end
end
