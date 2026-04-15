source "https://rubygems.org"

gemspec development_group: [:development, :test]

# Use a local path for layered-ui-rails during development
if Dir.exist?(File.expand_path("../layered-ui-rails", __dir__))
  gem "layered-ui-rails", path: "../layered-ui-rails"
end

# Use a local path for layered-managed-resource-rails during development
if Dir.exist?(File.expand_path("../layered-managed-resource-rails", __dir__))
  gem "layered-managed-resource-rails", path: "../layered-managed-resource-rails"
end

# Workaround for macOS OpenSSL v4 — not needed in Docker/Linux
group :local do
  gem "openssl", "~> 4.0"
end
