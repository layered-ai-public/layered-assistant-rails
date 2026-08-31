require "anthropic"
require "layered-resource-rails"
require "layered-ui-rails"
require "openai"
require "pagy"
require "positioning"

require "layered/assistant/version"
require "layered/assistant/engine"

module Layered
  module Assistant
    class MissingOwnerError < StandardError; end

    mattr_reader :authorize_block
    mattr_reader :owner_block
    mattr_reader :tools_block
    mattr_accessor :log_errors, default: false
    mattr_accessor :api_request_timeout, default: 210
    mattr_accessor :skip_db_encryption, default: false
    mattr_accessor :max_tool_cycles, default: 10

    def self.authorize(&block)
      @@authorize_block = block
    end

    def self.owner(&block)
      @@owner_block = block
    end

    # The tool classes an assistant may call. The block is called per request
    # rather than at boot so that tool classes reload in development.
    def self.tools(&block)
      @@tools_block = block
    end
  end
end
