# Changelog

All notable changes to this project will be documented in this file. This project follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

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
