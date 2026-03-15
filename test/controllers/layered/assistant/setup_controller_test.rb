require "test_helper"

module Layered
  module Assistant
    class SetupControllerTest < ActionDispatch::IntegrationTest
      test "should get index" do
        get "/layered/assistant"
        assert_response :success
        assert_select "h1", text: "Setup"
        assert_select "h2", text: "Getting started"
        assert_select "h2", text: "Authorization"
      end
    end
  end
end
