module Layered
  module Assistant
    # Routes declared with `layered_resources` dispatch here rather than to
    # the gem's own controller, so the engine's authorize block and owner
    # scoping still run ahead of every CRUD action.
    class ResourcesController < ApplicationController
      include Layered::Resource::Controller
    end
  end
end
