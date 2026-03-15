require "test_helper"
require "webmock/minitest"

module Layered
  module Assistant
    class ProvidersControllerTest < ActionDispatch::IntegrationTest
      setup do
        models_json = File.read(File.expand_path("../../../../data/models.json", __dir__))
        stub_request(:get, Models::CreateService::MODELS_URL).to_return(status: 200, body: models_json)
      end

      test "should get index" do
        get "/layered/assistant/providers"
        assert_response :success
        assert_select "table.l-ui-table"
      end

      test "should get new" do
        get "/layered/assistant/providers/new"
        assert_response :success
        assert_select "form.l-ui-form"
      end

      test "should create provider with valid params" do
        assert_difference("Provider.count", 1) do
          post "/layered/assistant/providers", params: { provider: { name: "New Provider", protocol: "anthropic", url: "https://api.anthropic.com", secret: "sk-secret-key", enabled: true, position: 1 } }
        end

        assert_redirected_to "/layered/assistant/providers"
        assert_equal "Provider was successfully created.", flash[:notice]

        provider = Provider.last
        assert_equal "sk-secret-key", provider.secret
      end

      test "should not create provider with invalid params" do
        assert_no_difference("Provider.count") do
          post "/layered/assistant/providers", params: { provider: { name: "", protocol: "" } }
        end

        assert_response :unprocessable_entity
        assert_select ".l-ui-form__errors"
      end

      test "should not create provider with invalid url" do
        assert_no_difference("Provider.count") do
          post "/layered/assistant/providers", params: { provider: { name: "Bad URL", protocol: "anthropic", url: "ftp://bad.com" } }
        end

        assert_response :unprocessable_entity
      end

      test "should get edit" do
        provider = layered_assistant_providers(:anthropic)

        get "/layered/assistant/providers/#{provider.id}/edit"
        assert_response :success
        assert_select "input[value=?]", provider.name
      end

      test "should update provider with valid params" do
        provider = layered_assistant_providers(:anthropic)

        patch "/layered/assistant/providers/#{provider.id}", params: { provider: { name: "Updated Name", protocol: "openai", secret: "sk-updated-secret" } }
        assert_redirected_to "/layered/assistant/providers"
        assert_equal "Provider was successfully updated.", flash[:notice]

        provider.reload
        assert_equal "Updated Name", provider.name
        assert_equal "openai", provider.protocol
        assert_equal "sk-updated-secret", provider.secret
      end

      test "should not update provider with invalid params" do
        provider = layered_assistant_providers(:anthropic)

        patch "/layered/assistant/providers/#{provider.id}", params: { provider: { name: "", protocol: "" } }
        assert_response :unprocessable_entity
        assert_select ".l-ui-form__errors"
      end

      test "should destroy provider" do
        provider = layered_assistant_providers(:disabled)

        assert_difference("Provider.count", -1) do
          delete "/layered/assistant/providers/#{provider.id}"
        end

        assert_redirected_to "/layered/assistant/providers"
        assert_equal "Provider was successfully deleted.", flash[:notice]
      end
    end
  end
end
