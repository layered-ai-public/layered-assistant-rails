require_relative "lib/layered/assistant/version"

Gem::Specification.new do |spec|
  spec.name        = "layered-assistant-rails"
  spec.version     = Layered::Assistant::VERSION
  spec.authors     = ["layered.ai"]
  spec.email       = ["support@layered.ai"]
  spec.homepage    = "https://www.layered.ai"
  spec.description = "An open source Rails 8+ engine built on `layered-ui-rails` that provides a multi-provider AI assistant with streaming responses and a full conversation UI."
  spec.summary     = "Open source, multi-provider, streaming AI assistant engine for Rails 8+ built on `layered-ui-rails`."
  spec.license     = "Apache-2.0"

  spec.required_ruby_version = ">= 3.3.0"

  # Metadata
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/layered-ai-public/layered-assistant-rails"
  spec.metadata["bug_tracker_uri"]  = "https://github.com/layered-ai-public/layered-assistant-rails/issues"
  spec.metadata["changelog_uri"]    = "https://github.com/layered-ai-public/layered-assistant-rails/blob/main/CHANGELOG.md"
  spec.metadata["documentation_uri"] = "https://layered-assistant-rails.layered.ai/"
  spec.metadata["discord_uri"] = "https://discord.gg/aCGqz9Bx"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Files
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,data,db,lib,.claude/skills}/**/*", "LICENSE", "NOTICE", "Rakefile", "README.md", "AGENTS.md"]
      .reject { |f| File.basename(f) == ".DS_Store" }
  end
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "rails", "~> 8.0"
  spec.add_dependency "positioning", "~> 0.4"
  spec.add_dependency "pagy", "~> 43.2"
  spec.add_dependency "ruby-anthropic", "~> 0.4"
  spec.add_dependency "ruby-openai", "~> 7.0"
  spec.add_dependency "kramdown", "~> 2.4"
  spec.add_dependency "kramdown-parser-gfm", "~> 1.1"
  spec.add_dependency "layered-ui-rails", "~> 0.10"
  spec.add_development_dependency "propshaft", "~> 1.0"
  spec.add_development_dependency "tailwindcss-rails", "~> 4.0"
  spec.add_development_dependency "importmap-rails", "~> 2.0"
  spec.add_development_dependency "stimulus-rails", "~> 1.0"
  spec.add_development_dependency "turbo-rails", "~> 2.0"
  spec.add_development_dependency "sqlite3", "~> 2.0"
  spec.add_development_dependency "puma", "~> 7.0"
  spec.add_development_dependency "devise", "~> 5.0"
  spec.add_development_dependency "solid_cable", "~> 3.0"
  spec.add_development_dependency "dotenv-rails", "~> 3.0"
  spec.add_development_dependency "honeybadger", "~> 6.5"
  spec.add_development_dependency "webmock", "~> 3.0"

  # Post-install message
  spec.post_install_message = <<~MSG
    To complete installation, run:

      bin/rails generate layered:assistant:install

    This command will:
      • Add `import "layered_assistant"` to your app/javascript/application.js (just after `import "layered_ui"`, which must already be present)
      • Mount the engine at /layered/assistant in your config/routes.rb
      • Create a starter initialiser at config/initializers/layered_assistant.rb
      • Copy engine migrations to your app's db/migrate/

    If these imports already exist, they will not be duplicated.
    Migrations that already exist will be skipped.

    To copy migrations separately:

      bin/rails generate layered:assistant:migrations
  MSG
end
