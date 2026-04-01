require "anthropic"
require "kramdown"
require "kramdown-parser-gfm"
require "layered-ui-rails"
require "openai"
require "pagy"
require "positioning"

require "layered/assistant/version"
require "layered/assistant/engine"

module Layered
  module Assistant
    mattr_reader :authorize_block
    mattr_reader :scope_block
    mattr_accessor :log_errors, default: false
    mattr_accessor :api_request_timeout, default: 210
    mattr_accessor :skip_db_encryption, default: false

    def self.authorize(&block)
      @@authorize_block = block
    end

    def self.scope(&block)
      @@scope_block = block
    end
  end
end
