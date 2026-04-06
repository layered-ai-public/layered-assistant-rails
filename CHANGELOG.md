# Changelog

All notable changes to this project will be documented in this file. This project follows [Semantic Versioning](https://semver.org/).

## [0.3.0] - 2026-04-06

### Breaking

- Rename `assistant.system_prompt` column to `assistant.instructions` - existing data is not migrated as the gem is pre-release

### Changed

- Snapshot assistant instructions as a system message when a conversation is created, decoupling conversations from later prompt edits
- Bump dependency on `layered-ui-rails` to `~> 0.2.3`

## [0.2.2] - 2026-04-06

### Added

- Generator tests for install and migrations generators covering CSS/JS injection, idempotency, quote tolerance, initialiser creation, route mounting, migration copying, and sequential timestamps
- Regression tests for owner assignment on assistant and provider create
- Regression tests for out-of-scope `assistant_id` rejection on conversation create (both full-page and panel paths)

### Changed

- Narrow Rails compatibility claim to >= 8.0 across README, gemspec, and CLAUDE.md; pin engine migrations to `Migration[8.0]` for consistency
- Install generator uses regex matching for import detection and injection, tolerating single/double quotes, optional `./` prefix, and optional semicolons
- Migrations generator uses `destination_root` instead of absolute `Rails.root` paths, enabling proper test framework support
- Include `NOTICE` in packaged gem files for Apache-2.0 compliance

### Fixed

- CI badge image URL in README now points to layered-assistant-rails (was layered-ui-rails)
- Setup page now documents the `api_request_timeout` configuration option
- Post-install message correctly states JS import is placed after `layered_ui` (was `@hotwired/turbo-rails`)
- Panel header helper now forwards blocks, fixing the "Assistant" fallback text for public users and eliminating the "block may be ignored" runtime warning

## [0.2.1] - 2026-04-03

### Added

- Page title and conversation select update dynamically when a conversation is named after the first message

### Maintenance

- Update dummy app gems

### Changed

- Rewrite Claude Code review action prompt with severity-based output format and stricter diff scoping
- Streaming preview now renders markdown server-side with Kramdown, eliminating parser drift between preview and final output
- Removed client-side `marked` dependency - the server is the single markdown authority
- Throttle streaming broadcasts to once per 25ms to limit server-side Kramdown re-parses

### Fixed

- Composer now shows the stop button instead of a disabled send button when the page is refreshed during an in-flight response
- Public conversation page now sets the HTML page title
- Kramdown no longer drops tables that immediately follow headings (missing blank line)

## [0.2.0] - 2026-04-01

### Changed

- Bump dependency on `layered-ui-rails` to `~> 0.2.1`
- `layered-ui-rails 0.2.1` adds `tailwindcss-rails (~> 4.0)` as a transitive dependency

## [0.1.3] - 2026-03-26

### Added

- Conversation select dropdown on the full-screen public conversation page, allowing guest users to switch between or start new conversations
- Signed-out navigation includes a link to the public assistants listing

### Changed

- Pin navigation as a persistent sidebar on desktop in the backend layout, using the new `l-ui-body--always-show-navigation` modifier from `layered-ui-rails`
- Public assistant show page immediately starts a new conversation and opens it full-screen
- Public conversation show page renders full-screen (no header, no panel, no pinned navigation)

## [0.1.2] - 2026-03-24

### Added

- Response timing metrics (tok/s, TTFT) on assistant messages with tooltip display
- Model, tokens, tok/s, and TTFT columns on the admin messages table
- `api_request_timeout` configuration option - total timeout in seconds for API requests including the full streaming response (default: 210)
- Response timeout UI - replaces the typing indicator with an error notice if a response does not complete within the timeout

### Changed

- Refactor `ChunkService` into `ChunkParser` (single protocol-aware parser) and `ResponseTimer` for cleaner separation of concerns
- Move engine settings from ENV vars to the engine initializer
- Provider protocols use lowercase names with I18n labels
- Scope models to avoid name collisions
- Increase Anthropic max_tokens (mandatory param) limit to 8192 to support newer models
- Reduce client-side responding timeout from 60s to 30s
- Messages re-sorted by `created_at` on delivery to enforce correct display order

### Fixed

- Tok/s and TTFT now display for stopped responses
- Serialise `stop_response!` at conversation level to close race condition on concurrent stop requests
- Do not lose chunk if save fails during streaming
- Handle token estimations for stopped messages
- Fixed race condition where user message could display after assistant message due to out-of-order ActionCable broadcasts
- Fix unnecessary DB query in public message endpoints
- SessionConversations now use uid for lookups
- Remove additional top margin from forms

## [0.1.1] - 2026-03-15

### Added

- Stop button to cancel an in-progress assistant response

### Changed

- Send button is disabled when the composer input is empty

## [0.1.0] - 2026-03-14

Initial release.

### Added

- Multi-provider AI assistant engine for Rails 8+ with support for Anthropic, OpenAI, Mistral, and OpenAI-compatible local APIs (Ollama, LM Studio, etc.)
- Streaming responses via Turbo Streams with token fade-in animation and chunked markdown rendering
- Full conversation UI with composer, message history, and automatic conversation naming
- Configurable assistants with system prompts and default model selection
- Provider and model management with encrypted API secrets and provider templates
- Model sync service for fetching available models from providers
- Panel mode for embedding the assistant in the `layered-ui-rails` side panel via Turbo Frames
- Token usage tracking with estimates when provider totals are unavailable
- Guest conversation management
- Configurable authentication block with a `l_assistant_accessible?` view helper
- Install generator (`layered:assistant:install`) to copy CSS, register JS imports, and verify `layered-ui-rails` is present
- Migrations generator (`layered:assistant:migrations`) to copy engine migrations into the host app
- Polymorphic owner and subject associations for tying conversations to application records
- Kamal deployment support
- WCAG 2.2 Level AA accessibility
