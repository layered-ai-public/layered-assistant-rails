require "positioning"
require "pagy"
require "anthropic"
require "openai"
require "kramdown"
require "kramdown-parser-gfm"
require "layered-ui-rails"
require "layered/assistant/version"
require "layered/assistant/engine"

module Layered
  module Assistant
    mattr_reader :authorize_block
    mattr_reader :scope_block

    def self.authorize(&block)
      @@authorize_block = block
    end

    def self.scope(&block)
      @@scope_block = block
    end
  end
end
