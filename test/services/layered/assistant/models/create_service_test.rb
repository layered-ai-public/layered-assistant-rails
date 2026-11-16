require "test_helper"
require "webmock/minitest"

module Layered
  module Assistant
    module Models
      class CreateServiceTest < ActiveSupport::TestCase
        setup do
          @anthropic = layered_assistant_providers(:anthropic)
          @openai = layered_assistant_providers(:openai)
          @openai.models.destroy_all
        end

        test "creates Anthropic models using the provider's key" do
          stub_request(:get, "https://api.anthropic.com/v1/models?limit=1000")
            .with(headers: { "x-api-key" => "sk-ant-test", "anthropic-version" => "2023-06-01" })
            .to_return(status: 200, body: {
              data: [
                { id: "claude-opus-5-5", display_name: "Claude Opus 5.5" },
                { id: "claude-sonnet-5-5", display_name: "Claude Sonnet 5.5" }
              ],
              has_more: false
            }.to_json)

          assert_difference("@anthropic.models.count", 2) do
            CreateService.new(@anthropic).call
          end

          assert_equal "Claude Opus 5.5", @anthropic.models.find_by(identifier: "claude-opus-5-5").name
        end

        test "follows Anthropic pagination" do
          stub_request(:get, "https://api.anthropic.com/v1/models?limit=1000")
            .to_return(status: 200, body: { data: [ { id: "a", display_name: "A" } ], has_more: true, last_id: "a" }.to_json)
          stub_request(:get, "https://api.anthropic.com/v1/models?limit=1000&after_id=a")
            .to_return(status: 200, body: { data: [ { id: "b", display_name: "B" } ], has_more: false }.to_json)

          assert_difference("@anthropic.models.count", 2) do
            CreateService.new(@anthropic).call
          end
        end

        test "creates OpenAI-compatible models, newest first, leaving out other uses" do
          stub_request(:get, "https://api.openai.com/v1/models")
            .with(headers: { "Authorization" => "Bearer sk-oai-test" })
            .to_return(status: 200, body: {
              data: [
                { id: "gpt-old", created: 1 },
                { id: "text-embedding-3-large", created: 3 },
                { id: "gpt-live-1", created: 4 },
                { id: "gpt-new", created: 2 }
              ]
            }.to_json)

          CreateService.new(@openai).call

          assert_equal %w[gpt-new gpt-old], @openai.models.order(:id).pluck(:identifier)
        end

        test "uses the provider's url and strips Gemini's models/ prefix" do
          @openai.update!(url: "https://generativelanguage.googleapis.com/v1beta/openai/")
          stub_request(:get, "https://generativelanguage.googleapis.com/v1beta/openai/models")
            .to_return(status: 200, body: { data: [ { id: "models/gemini-3.8-flash" } ] }.to_json)

          CreateService.new(@openai).call

          assert @openai.models.exists?(identifier: "gemini-3.8-flash")
        end

        test "uses Mistral's capabilities over its type and skips its aliases" do
          @openai.update!(url: "https://api.mistral.ai/v1")
          chat = { completion_chat: true }
          stub_request(:get, "https://api.mistral.ai/v1/models")
            .to_return(status: 200, body: { data: [
              { id: "codestral-2508", name: "codestral-2508", type: "base", capabilities: chat },
              { id: "codestral-latest", name: "codestral-2508", type: "base", capabilities: chat },
              { id: "mistral-ocr-2512", name: "mistral-ocr-2512", type: "base", capabilities: { completion_chat: false } }
            ] }.to_json)

          CreateService.new(@openai).call

          assert_equal [ "codestral-2508" ], @openai.models.pluck(:identifier)
        end

        test "reads a bare array and skips non-chat types" do
          @openai.update!(url: "https://api.together.ai/v1")
          stub_request(:get, "https://api.together.ai/v1/models")
            .to_return(status: 200, body: [
              { id: "moonshotai/Kimi-K3", display_name: "Kimi K3", type: "chat" },
              { id: "black-forest-labs/FLUX", type: "image" }
            ].to_json)

          CreateService.new(@openai).call

          assert_equal [ "Kimi K3" ], @openai.models.pluck(:name)
        end

        test "keeps only the newest models" do
          data = (1..(CreateService::LIMIT + 5)).map { |i| { id: "model-#{i}", created: i } }
          stub_request(:get, "https://api.openai.com/v1/models").to_return(status: 200, body: { data: data }.to_json)

          CreateService.new(@openai).call

          assert_equal CreateService::LIMIT, @openai.models.count
          assert @openai.models.exists?(identifier: "model-#{CreateService::LIMIT + 5}")
          assert_not @openai.models.exists?(identifier: "model-1")
        end

        test "keeps the provider's order among models created at the same time" do
          data = (1..(CreateService::LIMIT + 5)).map { |i| { id: "model-#{i}", created: 1 } }
          stub_request(:get, "https://api.openai.com/v1/models").to_return(status: 200, body: { data: data }.to_json)

          CreateService.new(@openai).call

          assert_equal (1..CreateService::LIMIT).map { |i| "model-#{i}" }, @openai.models.order(:id).pluck(:identifier)
        end

        test "keeps every model, in the provider's order, when none has a created date" do
          data = (1..(CreateService::LIMIT + 5)).map { |i| { id: "model-#{i}" } }
          stub_request(:get, "https://api.openai.com/v1/models").to_return(status: 200, body: { data: data }.to_json)

          CreateService.new(@openai).call

          assert_equal (1..(CreateService::LIMIT + 5)).map { |i| "model-#{i}" }, @openai.models.order(:id).pluck(:identifier)
        end

        test "does not duplicate existing models" do
          stub_request(:get, "https://api.openai.com/v1/models").to_return(status: 200, body: { data: [ { id: "gpt-new" } ] }.to_json)

          CreateService.new(@openai).call

          assert_no_difference("@openai.models.count") do
            CreateService.new(@openai).call
          end
        end

        test "skips gracefully when the key is refused" do
          stub_request(:get, "https://api.anthropic.com/v1/models?limit=1000").to_return(status: 401)

          assert_no_difference("@anthropic.models.count") do
            CreateService.new(@anthropic).call
          end
        end

        test "skips gracefully when offline" do
          stub_request(:get, "https://api.openai.com/v1/models").to_raise(SocketError)

          assert_no_difference("@openai.models.count") do
            CreateService.new(@openai).call
          end
        end

        test "skips gracefully on timeout" do
          stub_request(:get, "https://api.openai.com/v1/models").to_raise(Net::OpenTimeout)

          assert_no_difference("@openai.models.count") do
            CreateService.new(@openai).call
          end
        end

        test "skips gracefully on a response that is not JSON" do
          stub_request(:get, "https://api.openai.com/v1/models").to_return(status: 200, body: "<html>")

          assert_no_difference("@openai.models.count") do
            CreateService.new(@openai).call
          end
        end
      end
    end
  end
end
