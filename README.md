# layered-assistant-rails

[![CI](https://github.com/layered-ai-public/layered-assistant-rails/actions/workflows/ci.yml/badge.svg)](https://github.com/layered-ai-public/layered-assistant-rails/actions/workflows/ci.yml)
[![WCAG 2.2 AA](https://img.shields.io/badge/WCAG_2.2-AA-green)](https://www.w3.org/WAI/WCAG22/quickref/)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Website](https://img.shields.io/badge/Website-layered.ai-purple)](https://www.layered.ai/)
[![GitHub](https://img.shields.io/badge/GitHub-layered--assistant--rails-black)](https://github.com/layered-ai-public/layered-assistant-rails)
[![Discord](https://img.shields.io/badge/Discord-join-5865F2)](https://discord.gg/aCGqz9Bx)

An open source Rails 8+ engine built on [layered-ui-rails](https://github.com/layered-ai-public/layered-ui-rails) that provides a multi-provider AI assistant with streaming responses and a full conversation UI.

## Requirements

- Ruby >= 3.2.0
- Ruby on Rails >= 8.0
- [layered-ui-rails](https://github.com/layered-ai-public/layered-ui-rails) installed in the host app

## Agent skill

An [agent skill](https://agentskills.io) is included so AI coding agents can work with `layered-assistant-rails` in your project. Once installed, the agent can handle the full setup - just ask it to add `layered-assistant-rails` to your app and it will install the gem, run the generator, and configure your layout.

**Project install** - scoped to a single repo, available to all contributors:

```bash
bin/rails generate layered:assistant:install_agent_skill
```

**Global install** - available across all your projects:

```bash
./install-skill.sh
# or install remotely without cloning the repo:
curl -fsSL https://raw.githubusercontent.com/layered-ai-public/layered-assistant-rails/main/install-skill.sh | sh
```

## Installation

Add to your Gemfile:

```ruby
gem "layered-assistant-rails"
```

Then run:

```bash
bundle install
```

## Setup

### Install generator

Run the install generator to register imports and mount the engine:

```bash
bin/rails generate layered:assistant:install
```

This will:
- Copy `layered_ui.css` to `app/assets/tailwind/`
- Add `@import "./layered_ui";` to your `application.css`
- Add `import "layered_ui"` to your `application.js`
- Add `import "layered_assistant"` to your `app/javascript/application.js` (after the layered-ui import)
- Mount the engine at `/layered/assistant` in your `config/routes.rb`
- Copy engine migrations into your application

All steps are idempotent - re-running the generator will not duplicate imports, routes, or migrations.

### Upgrading

After updating the gem, copy any new migrations and run them:

```bash
bin/rails generate layered:assistant:migrations
bin/rails db:migrate
```

## Authorization

All non-public engine routes are **blocked by default** (403 Forbidden) until you configure an `authorize` block. The install generator creates a starter initialiser at `config/initializers/layered_assistant.rb` - uncomment one of the examples to get started.

Once configured, visit `/layered/assistant` (or wherever you mounted the engine) to verify access.

### Allow all requests

```ruby
Layered::Assistant.authorize do
  # No-op: all requests permitted
end
```

### Require sign-in (Devise)

```ruby
Layered::Assistant.authorize do
  redirect_to main_app.new_user_session_path unless user_signed_in?
end
```

### Restrict to admins

```ruby
Layered::Assistant.authorize do
  head :forbidden unless current_user&.admin?
end
```

The block runs in controller context, so you have access to `request`, `current_user`, `redirect_to`, `head`, `main_app`, and all other controller methods.

### Checking access in views

The `l_assistant_accessible?` helper evaluates the authorize block without side effects. Use it to conditionally show navigation or links to the engine:

```erb
<% if l_assistant_accessible? %>
  <%= link_to "Assistant", layered_assistant.root_path %>
<% end %>
```

## Record scoping

By default, all records are visible to any authorised user. If your application is multi-tenant or you need to restrict which records a user can see, configure a `scope` block in the initialiser.

The block receives the model class, runs in controller context, and must return an `ActiveRecord::Relation`. All engine models with a polymorphic `owner` association are passed through the scope block.

### Scope all owned resources to the current user

```ruby
Layered::Assistant.scope do |model_class|
  model_class.where(owner: current_user)
end
```

### Scope conversations only

```ruby
Layered::Assistant.scope do |model_class|
  if model_class == Layered::Assistant::Conversation
    model_class.where(owner: current_user)
  else
    model_class.all
  end
end
```

When no scope block is configured, queries are unscoped. Record-level access control is the host application's responsibility; the scope block is the integration point for it.

## Panel helpers

The engine provides two convenience helpers for wiring the layered-ui panel to the assistant. Use them inside `content_for` blocks in your application layout:

```erb
<% content_for :l_ui_panel_heading do %>
  <%= layered_assistant_panel_header %>
<% end %>

<% content_for :l_ui_panel_body do %>
  <%= layered_assistant_panel_body %>
<% end %>

<%= render template: "layouts/layered_ui/application" %>
```

Both helpers accept keyword arguments that are forwarded as HTML attributes to the underlying `turbo_frame_tag`:

```erb
<%= layered_assistant_panel_body data: { controller: "panel" } %>
```

| Helper | Description |
|---|---|
| `layered_assistant_panel_header` | Empty Turbo Frame (`assistant_panel_header`) populated by the engine's panel views |
| `layered_assistant_panel_body` | Turbo Frame (`assistant_panel`) that loads the conversation list from the engine's panel routes |

## Configuration

Optional settings can be added to your initialiser (`config/initializers/layered_assistant.rb`):

```ruby
# Log API errors to stdout (default: false)
Layered::Assistant.log_errors = true

# Total timeout in seconds for API requests, including the full streaming response (default: 210).
# Increase for models with high max_tokens limits or slow providers.
Layered::Assistant.api_request_timeout = 210

# Disable Active Record Encryption on Provider#secret.
# Only use this in development/test environments without encryption keys configured.
Layered::Assistant.skip_db_encryption = true
```

Note: `skip_db_encryption` is read at class load time, so it must be set before `Layered::Assistant::Provider` is first loaded. A standard Rails initialiser satisfies this requirement.

## Demo

A dummy Rails app is included for development and testing:

```bash
cd test/dummy
bin/setup
bin/dev
```

Then visit `http://localhost:3000`.

### Deploying the dummy app

The dummy app can be deployed with [Kamal](https://kamal-deploy.org). Set the required environment variables and deploy from `test/dummy`:

```bash
cd test/dummy
export KAMAL_DEPLOY_IP=<server-ip>
export KAMAL_DEPLOY_DOMAIN=<domain>
export KAMAL_SSH_KEY=<path-to-ssh-key>
kamal deploy
```

## Testing

Run the gem tests from the root directory:

```bash
bundle exec rake test
```

## Contributing

This project is still in its early days. We welcome issues, feedback, and ideas - they genuinely help shape the direction of the project. That said, we're holding off on accepting pull requests for now to stay focused on getting the foundations right. Thank you for your patience and interest. See [CLA.md](CLA.md) for the full policy.

## License

Released under the [Apache 2.0 License](LICENSE).

Copyright 2026 LAYERED AI LIMITED (UK company number: 17056830). See [NOTICE](NOTICE) for attribution details.

## Trademarks

The source code is fully open, but the layered.ai name, logo, and brand assets are trademarks of LAYERED AI LIMITED. The Apache 2.0 license does not grant rights to use the layered.ai branding. Forks and redistributions must use a distinct name. See [TRADEMARK.md](TRADEMARK.md) for the full policy.
