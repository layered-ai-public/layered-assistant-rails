require "test_helper"
require "webmock/minitest"

module Layered
  module Assistant
    module Models
      class CreateServiceTest < ActiveSupport::TestCase
        setup do
          @provider = layered_assistant_providers(:anthropic)
          @models_json = File.read(File.expand_path("../../../../../data/models.json", __dir__))
        end

        test "creates models for a matching provider" do
          stub_request(:get, CreateService::MODELS_URL).to_return(status: 200, body: @models_json)

          assert_difference("@provider.models.count", 3) do
            CreateService.new(@provider).call
          end

          assert @provider.models.exists?(identifier: "claude-opus-4-7")
          assert @provider.models.exists?(identifier: "claude-sonnet-4-6")
          assert @provider.models.exists?(identifier: "claude-haiku-4-5")
        end

        test "does not duplicate existing models" do
          stub_request(:get, CreateService::MODELS_URL).to_return(status: 200, body: @models_json)

          CreateService.new(@provider).call

          assert_no_difference("@provider.models.count") do
            CreateService.new(@provider).call
          end
        end

        test "skips gracefully when provider has no catalogue entry" do
          stub_request(:get, CreateService::MODELS_URL).to_return(status: 200, body: @models_json)

          provider = layered_assistant_providers(:disabled)

          assert_no_difference("provider.models.count") do
            CreateService.new(provider).call
          end
        end

        test "skips gracefully on HTTP error" do
          stub_request(:get, CreateService::MODELS_URL).to_return(status: 500)

          assert_no_difference("@provider.models.count") do
            CreateService.new(@provider).call
          end
        end

        test "skips gracefully when offline" do
          stub_request(:get, CreateService::MODELS_URL).to_raise(SocketError)

          assert_no_difference("@provider.models.count") do
            CreateService.new(@provider).call
          end
        end

        test "skips gracefully on timeout" do
          stub_request(:get, CreateService::MODELS_URL).to_raise(Net::OpenTimeout)

          assert_no_difference("@provider.models.count") do
            CreateService.new(@provider).call
          end
        end
      end
    end
  end
end
