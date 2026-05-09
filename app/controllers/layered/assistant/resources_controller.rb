module Layered
  module Assistant
    class ResourcesController < ApplicationController
      include Layered::Resource::Controller
    end
  end
end
