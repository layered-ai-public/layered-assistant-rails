require "test_helper"

module Layered
  module Assistant
    class ProviderTest < ActiveSupport::TestCase
      test "enabled scope excludes disabled providers" do
        enabled = Provider.enabled
        assert_includes enabled, layered_assistant_providers(:anthropic)
        assert_not_includes enabled, layered_assistant_providers(:disabled)
      end

      test "sorted scope orders by position then name" do
        sorted = Provider.sorted
        assert_equal sorted, sorted.sort_by { |p| [p.position, p.name] }
      end

      test "validates url format when present" do
        provider = Provider.new(name: "Test", protocol: :anthropic, url: "ftp://invalid.com")
        assert_not provider.valid?
        assert_includes provider.errors[:url], "must start with http:// or https://"
      end

      test "allows blank url" do
        provider = Provider.new(name: "Test", protocol: :anthropic, url: "")
        assert provider.valid?
      end

      test "allows valid http url" do
        provider = Provider.new(name: "Test", protocol: :anthropic, url: "https://api.example.com")
        assert provider.valid?
      end

      test "encrypts secret attribute" do
        provider = Provider.create!(name: "Encrypted Test", protocol: :anthropic, secret: "sk-my-secret")
        provider.reload
        assert_equal "sk-my-secret", provider.secret
        # Verify the raw database value is not the plaintext
        raw = Provider.connection.select_value(
          "SELECT secret FROM #{Provider.table_name} WHERE id = #{provider.id}"
        )
        assert_not_equal "sk-my-secret", raw
      end
    end
  end
end
