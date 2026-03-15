require "test_helper"

module Layered
  module Assistant
    class AuthenticationTest < ActionDispatch::IntegrationTest
      teardown do
        # Restore the Devise authorize block so other tests are not affected
        Layered::Assistant.authorize do
          redirect_to main_app.new_user_session_path unless user_signed_in?
        end
      end

      test "returns 403 when no authorize block is configured" do
        sign_out :user
        Layered::Assistant.class_variable_set(:@@authorize_block, nil)

        get "/layered/assistant/conversations"
        assert_response :forbidden
      end

      test "allows request when authorize block is a no-op" do
        Layered::Assistant.authorize do
          # No-op: allow all
        end

        get "/layered/assistant/conversations"
        assert_response :success
      end

      test "blocks request when authorize block renders forbidden" do
        Layered::Assistant.authorize do
          head :forbidden
        end

        get "/layered/assistant/conversations"
        assert_response :forbidden
      end

      test "redirects when authorize block calls redirect_to" do
        Layered::Assistant.authorize do
          redirect_to "http://example.com/login", allow_other_host: true
        end

        get "/layered/assistant/conversations"
        assert_response :redirect
        assert_redirected_to "http://example.com/login"
      end

      test "authorize block has access to controller context" do
        Layered::Assistant.authorize do
          head :forbidden unless request.path.include?("conversations")
        end

        get "/layered/assistant/conversations"
        assert_response :success
      end
    end
  end
end
