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
    mattr_reader :tools_block
    mattr_reader :execute_tool_block
    mattr_accessor :log_errors, default: false
    mattr_accessor :api_request_timeout, default: 210
    mattr_accessor :skip_db_encryption, default: false
    mattr_accessor :tool_execution_timeout, default: 30

    def self.authorize(&block)
      @@authorize_block = block
    end

    def self.scope(&block)
      @@scope_block = block
    end

    # Return an array of tool definitions for the given assistant.
    # Each tool: { name: "tool_name", description: "...", input_schema: { type: "object", properties: {...}, required: [...] } }
    def self.tools(&block)
      @@tools_block = block
    end

    # Execute a tool call. Receives tool name (String), input (Hash), and a context hash
    # with keys :assistant, :conversation, and :message. Must return a String result.
    # Each call is wrapped in a Timeout (default 30s, configure via tool_execution_timeout).
    def self.execute_tool(&block)
      @@execute_tool_block = block
    end
  end
end
