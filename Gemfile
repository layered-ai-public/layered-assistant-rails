source "https://rubygems.org"

gemspec development_group: [:development, :test]

gem "layered-ui-rails", path: "../layered-ui-rails"
gem "layered-managed-resource-rails", path: "../layered-managed-resource-rails"

# Workaround for macOS OpenSSL v4 — not needed in Docker/Linux
group :local do
  gem "openssl", "~> 4.0"
end
