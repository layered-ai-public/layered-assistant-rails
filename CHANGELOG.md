# Changelog

All notable changes to this project will be documented in this file. This project follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.1.1] - 2026-03-15

- Stop button to cancel an in-progress assistant response
- Send button is disabled when the composer input is empty

## [0.1.0] - 2026-03-14

Initial release.

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
