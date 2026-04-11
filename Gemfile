source "https://rubygems.org"

gemspec development_group: [:development, :test]

gem "layered-ui-rails", path: "../layered-ui-rails"
# gem "layered-ui-rails", github: "layered-ai-public/layered-ui-rails", branch: "main"

# Workaround for macOS OpenSSL v4 — not needed in Docker/Linux
group :local do
  gem "openssl", "~> 4.0"
end
