require "test_helper"
require "webmock/minitest"

module Layered
  module Assistant
    module Providers
      class KeyCheckServiceTest < ActiveSupport::TestCase
        def check(protocol: "openai", url: nil, secret: "sk-key")
          KeyCheckService.new(protocol: protocol, url: url, secret: secret).call
        end

        test "an Anthropic key is checked with Anthropic, whatever the URL" do
          stub_request(:get, "https://api.anthropic.com/v1/models")
            .with(headers: { "x-api-key" => "sk-key", "anthropic-version" => "2023-06-01" }).to_return(status: 200)

          assert_predicate check(protocol: "anthropic", url: "https://example.com"), :valid?
        end

        test "an OpenAI-compatible key is checked against the provider's URL" do
          stub_request(:get, "https://api.groq.com/openai/v1/models")
            .with(headers: { "Authorization" => "Bearer sk-key" }).to_return(status: 200)

          assert_predicate check(url: "https://api.groq.com/openai/v1/"), :valid?
        end

        test "an OpenAI-compatible key without a URL is checked with OpenAI" do
          stub_request(:get, "https://api.openai.com/v1/models").to_return(status: 200)

          assert_predicate check, :valid?
        end

        test "an OpenRouter key is checked by asking about the key itself" do
          stub_request(:get, "https://openrouter.ai/api/v1/key").to_return(status: 200)

          assert_predicate check(url: "https://openrouter.ai/api/v1/"), :valid?
        end

        test "a key the provider refuses is invalid" do
          stub_request(:get, "https://api.openai.com/v1/models").to_return(status: 401)
          assert_predicate check, :invalid?

          stub_request(:get, "https://api.openai.com/v1/models").to_return(status: 400)
          assert_predicate check, :invalid?
        end

        test "a key that couldn't be checked is neither valid nor invalid" do
          stub_request(:get, "https://api.openai.com/v1/models").to_return(status: 403)
          assert_equal :unknown, check.status

          stub_request(:get, "https://api.openai.com/v1/models").to_timeout
          assert_equal :unknown, check.status
        end

        test "a blank key is not checked" do
          assert_equal :unknown, check(secret: " ").status
        end
      end
    end
  end
end
