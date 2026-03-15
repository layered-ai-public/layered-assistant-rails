require "test_helper"

module Layered
  module Assistant
    class AccessHelperTest < ActionView::TestCase
      include Layered::Assistant::AccessHelper

      teardown do
        Layered::Assistant.authorize do
          # No-op
        end
      end

      test "returns false when no authorize block is configured" do
        Layered::Assistant.class_variable_set(:@@authorize_block, nil)

        assert_not l_assistant_accessible?
      end

      test "returns true when authorize block is a no-op" do
        Layered::Assistant.authorize do
          # No-op
        end

        assert l_assistant_accessible?
      end

      test "returns false when authorize block calls head" do
        Layered::Assistant.authorize do
          head :forbidden
        end

        assert_not l_assistant_accessible?
      end

      test "returns false when authorize block calls redirect_to" do
        Layered::Assistant.authorize do
          redirect_to "/login"
        end

        assert_not l_assistant_accessible?
      end
    end
  end
end
