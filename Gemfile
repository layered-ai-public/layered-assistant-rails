source "https://rubygems.org"

gemspec development_group: [ :development, :test ]

gem "layered-resource-rails", github: "layered-ai-public/layered-resource-rails"

# Workaround for macOS OpenSSL v4 — not needed in Docker/Linux
group :local do
  gem "openssl", "~> 4.0"
end
