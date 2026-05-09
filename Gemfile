source "https://rubygems.org"

gemspec development_group: [ :development, :test ]

# Use a github repo for layered-resource-rails during development
gem "layered-resource-rails", github: "layered-ai-public/layered-resource-rails"

# Workaround for macOS OpenSSL v4 — not needed in Docker/Linux
group :local do
  gem "openssl", "~> 4.0"
end
