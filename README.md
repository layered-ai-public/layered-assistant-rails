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

Engine records are owned. Assistants, conversations, personas, providers and skills are stamped with an owner on create and filtered by it on read, so users only see their own records. The owner defaults to the signed-in user, so multi-tenant apps need no configuration.

### Changing the ownership boundary

To scope records to something other than the signed-in user - their organisation, say - configure an `owner` block in the initialiser:

```ruby
Layered::Assistant.owner do
  current_user.organisation
end
```

The block runs in controller context. Whatever it returns is used as the owner for both reads and creates.

### When there is no owner

Reads return no records, and create actions raise `Layered::Assistant::MissingOwnerError` rather than persisting a record that every scoped read would then hide. Make sure your authorize block only admits authenticated users.

If you configure an owner block, it must return a record for every request your authorize block admits - not just for signed-in users. `current_user.organisation` returns nil for someone who has not created an organisation yet, and that user will hit `MissingOwnerError` on their first create. Either give the block a fallback, or have your authorize block send those users somewhere to set one up first.

Ownership is enforced at the controller layer, not by model validations. Out-of-scope IDs return 404.

### The conversation user

Ownership answers "which records may this request see". It does not answer
"who is doing the talking" - and once an owner block scopes records to an
organisation, the owner cannot: every member of that organisation shares it.

So a conversation separately records the signed-in user who started it:

```ruby
conversation.owner # => #<Organisation id: 3>   the boundary records are scoped to
conversation.user  # => #<User id: 91>          the person who asked
```

The two are the same record until you configure an owner block. `user` is
always whoever was signed in and is never redirected by a block, and it is nil
for an anonymous visitor on a public assistant. Tools read both - see
[Tools](#tools).

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

## Tools

An assistant can call into the host application to fetch or change something
before it answers. Define a tool as a class in `app/tools`:

```ruby
# app/tools/weather_tool.rb
class WeatherTool < Layered::Assistant::Tool
  description "Get the current weather for a city."

  argument :city, :string, required: true, description: "The city to look up."
  argument :units, :string, description: "celsius or fahrenheit", enum: %w[celsius fahrenheit]

  def call(city:, units: "celsius")
    forecast = Weather.for(city)

    { city: city, temperature: forecast.temperature(units), summary: forecast.summary }
  end
end
```

Then list the tool classes in your initialiser:

```ruby
Layered::Assistant.tools do
  [ WeatherTool ]
end
```

The block is called per request rather than read once at boot, so tool classes
reload in development like any other application class.

### Giving tools to an assistant

Registering a tool makes it available to pick, not available to call. Each
assistant is given its own set on its edit screen, and an assistant with no
tools calls nothing - so adding a tool to the application does not hand it to
every assistant at once. Two assistants can share a registered tool and still
be given different sets:

| Assistant | Tools |
|---|---|
| Sales assistant | `weather` |
| Support assistant | `weather`, `order-lookup` |

The set is held by tool name rather than a foreign key, because tools are
classes rather than records. A name whose class is no longer registered is
ignored, so removing a tool from the initialiser does not break the assistants
that listed it.

Outside the UI, assign the set with `tool_names`:

```ruby
assistant.update!(tool_names: [ "weather", "order-lookup" ])
```

### Defining a tool

| Method | Description |
|---|---|
| `description` | What the tool does, in the model's words. This is the only thing the model has to go on, so be specific |
| `argument` | An argument the model may supply: `argument :name, :type, required:, description:, enum:, items:` |
| `tool_name` | The name the model calls the tool by. Defaults to the class name without its `Tool` suffix, namespaces hyphenated: `Weather::ForecastTool` becomes `weather-forecast` |
| `self.public =` | Whether the tool may be offered to a public assistant. `false` by default - see below |

Argument types are `:string`, `:integer`, `:number`, `:boolean`, `:array` and
`:object`. An `:array` takes `items:` to name its element type.

Subclass a tool to share logic and the declarations come with it: the child
inherits its parent's `description`, `public` flag and arguments, adds any
arguments of its own, and may redeclare one by name to narrow it. The name is
the exception - the child derives its own from its class name, since two tools
answering to one name would collide in the registry.

`#call` receives the arguments as keywords and may return a string or anything
that responds to `#to_json`. Raising is safe: the error is reported back to the
model as the tool's result, so it can correct itself or explain, rather than
the response failing.

Inside `#call`, four methods give the calling context:

| Method | Description |
|---|---|
| `owner` | The record the conversation is scoped to. Scope the tool's reads and writes to this - it is the caller's boundary |
| `user` | The person doing the talking. The same record as `owner` until an owner block scopes ownership elsewhere, at which point `owner` is (say) the organisation and `user` is the member of it who asked |
| `conversation` | The conversation the call came from |
| `message` | The assistant message that asked for the call |

Registering a tool does not scope it. `owner` is handed to you, but nothing
enforces that you use it - a tool that queries across every tenant will do
exactly that. Scoping is the tool's own job:

```ruby
def call(reference:)
  owner.orders.find_by(reference: reference)
end
```

### Tools and public assistants

A conversation with a public assistant has no owner - it belongs to an
anonymous visitor, so there is no boundary to scope a tool's reads to. Tools
are private by default and withheld from those conversations even when the
assistant has been given them. A tool that is safe to expose opts in, using
the same word an assistant does:

```ruby
class CurrentTimeTool < Layered::Assistant::Tool
  description "Get the current date and time on the server."
  self.public = true

  def call
    { time: Time.current.iso8601 }
  end
end
```

This is written as an attribute rather than a `public true` DSL because
`public` is Ruby's own method-visibility keyword. A class method of that name
would shadow it, and a tool whose body used a bare `public` to reopen
visibility would silently mark itself callable by anonymous visitors - too
sharp an edge for a flag that governs exposure.

### The tool call loop

A response that asks for tools is not the end of the turn. The engine runs the
tools, records a message per result, then queues a fresh assistant message so
the model can answer with what came back - which may ask for tools again. The
composer stays disabled until a response completes without asking for
anything, and `max_tool_cycles` (default 10) bounds the loop.

Results are shown in the conversation as a collapsible panel naming the tool,
with its input and output.

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

# How many rounds of tool calls one prompt may trigger before the engine gives
# up and says so (default: 10).
Layered::Assistant.max_tool_cycles = 10
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
