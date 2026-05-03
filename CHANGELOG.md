# Changelog

All notable changes to this project will be documented in this file. This project follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- RuboCop linting via `rubocop-rails-omakase`, with a `lint` job in CI

## [0.5.0] - 2026-05-03

### Breaking

- Minimum Ruby version raised to 3.3.0 (follows the `layered-ui-rails` 0.10 bump; Ruby 3.2 is EOL). CI matrix now covers Ruby 3.3, 3.4, and 4.0.

### Added

- `layered:assistant:install_agent_skill` generator that copies a `layered-assistant-rails` Claude Code skill into host apps' `.claude/skills/`, covering installation, authorization, scoping, and panel mounting
- Six SVG navigation icons under `app/assets/images/layered_assistant/` (assistants, conversations, personas, providers, skills, spanner) and an asset path entry on the engine so host apps can resolve them

### Changed

- Bump `layered-ui-rails` to `~> 0.10`
- Adopt the new `l_ui_navigation_section` nested navigation helper in the host navigation partial, with icons applied to every nav item

## [0.4.1] - 2026-04-26

### Changed

- Bump `layered-ui-rails` to `~> 0.9`
- Adopt `l_ui_title_bar` helper across engine views (assistants, conversations, messages, models, personas, providers, skills, public assistants, setup) for consistent page headings

### Removed

- Empty CSS distribution from the install generator. The gem no longer ships an `app/assets/tailwind/layered/assistant/styles.css` file or injects a `@import "layered_assistant"` line into host `application.css` - all engine styles come from `layered-ui-rails`

## [0.4.0] - 2026-04-25

### Breaking

- Bump `layered-ui-rails` to `~> 0.8`. Host apps with a customised `layered_ui_overrides.css` must migrate values from HSL channels (e.g. `220 80% 55%`) to full CSS colors, preferably `oklch()`. See the layered-ui-rails 0.8 changelog for details.

### Added

- Anthropic: Claude Opus 4.7 (`claude-opus-4-7`) added to the model catalogue
- OpenAI: GPT-5.5 and GPT-5.5 Pro added; GPT-5.4 lineup expanded with Mini and Nano variants
- Gemini: Gemini 3 Flash Preview and Gemini 3.1 Flash-Lite Preview added
- `Models::CreateService` reads from the gem's local `data/models.json` in development, making catalogue edits visible without a publish step

### Changed

- Scroll-to-bottom button no longer renders an inner `<img>`; the chevron icon is now baked into `l-ui-scroll-to-bottom` via CSS in layered-ui-rails 0.8
- OpenRouter catalogue refreshed to current top-traffic third-party models; Grok 3 and the Llama 4 entries dropped
- Groq catalogue trimmed to current production models; preview-only entries (Llama 4 Maverick/Scout, Qwen 3 32B, Kimi K2) removed
- Mistral entries renamed to friendlier names (Mistral Large 3, Medium 3.1, Small 4)

## [0.3.2] - 2026-04-09

### Added

- Skill model with full CRUD, assistant binding, and system prompt composition - skills provide reusable passive instruction blocks that can be assigned to assistants and are included in the system prompt

### Changed

- Bump `layered-ui-rails` to 0.2.5

## [0.3.1] - 2026-04-09

### Added

- Persona model with full CRUD, assistant binding, and system prompt composition - personas provide reusable personality/behaviour instructions that can be assigned to assistants

### Changed

- Bump `layered-ui-rails` to 0.2.4

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
