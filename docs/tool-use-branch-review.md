# Branch review: `tool-use`

## What it does

Adds tool use (function calling) support to the assistant response loop. The LLM can now request tool calls during streaming, the engine executes them via host-app-configured callbacks, records results as `tool`-role messages, and loops until the model stops requesting tools or hits a safety cap of 10 iterations.

## Architecture assessment

The solution is cleanly layered:

1. **Configuration API** (`Layered::Assistant.tools` / `.execute_tool`) - two block-based callbacks following the existing pattern (`authorize`, `scope`). Simple, idiomatic.
2. **ResponseService** - new service extracted from the job, owns the tool loop. The job is now a thin wrapper. Good separation.
3. **ChunkParser** - accumulates streamed tool call JSON fragments. Clean state machine.
4. **ChunkService** - exposes `accumulated_tool_calls` after streaming completes.
5. **MessagesService** - formats tool messages for both Anthropic and OpenAI APIs.
6. **Message model** - new `tool` role, `visible` scope to hide internal messages, `tool_calls`/`tool_call_id` columns.

This is the right decomposition. The tool loop lives in one place, the streaming parser is separate, and the host app controls tool definitions and execution.

## Issues and concerns

### 1. OpenAI tool use is half-wired (significant gap)

`ChunkParser#tool_event` returns `nil` for OpenAI (`return nil if @openai`). The OpenAI client passes tools to the API, but streamed tool call chunks are never parsed. This means:

- OpenAI will return tool call responses
- They'll be silently ignored
- The loop will break on `pending.empty?` and the response will appear to complete normally, but the tool call content won't be in the message

The OpenAI client also formats `tool_calls` in `MessagesService#format_openai` correctly, so the _replay_ path is ready, but the _streaming parse_ path is missing. This is the biggest gap - it will silently fail for OpenAI providers.

**Recommendation**: Either implement OpenAI tool call chunk parsing, or don't pass tools to the OpenAI client at all (so the API never returns tool calls). Silent failure is the worst option.

### 2. `tool_calls` stored as JSON text, parsed repeatedly

`message.tool_calls` is a `text` column storing JSON. It's parsed in `format_anthropic_assistant` and `format_openai` with a `is_a?(String) ? JSON.parse(...)` guard. This works but is fragile - consider using `serialize :tool_calls, coder: JSON` or a `json`/`jsonb` column type (if on Postgres). The current approach works fine for SQLite/dev but the repeated parse-guard is a code smell.

### 3. `content_block_stop` fires for text blocks too

In `ChunkService#handle_tool_event`, `:block_stop` only finalises if `@current_tool_call` is set. This is correct - a text block's `content_block_stop` won't have `@current_tool_call` set. Good.

### 4. Tool message validation could be tighter

`validates :content, presence: true, unless: -> { assistant? || tool? }` - tool messages skip content validation. But tool messages should always have content (the tool result). The `unless: tool?` exemption was likely added because tool messages are created internally, but it removes a safety net.

### 5. `docs/managed_table_helper.md` is unrelated

This file documents a `l_ui_managed_table` helper from `layered-ui-rails`. It's not related to tool use and shouldn't be in this branch.

### 6. Gemfile/Gemfile.lock point to local path

The Gemfile has `gem "layered-ui-rails", path: "../layered-ui-rails"` uncommented and `layered-ui-rails` bumped to `~> 0.3.0`. This is fine for development but needs to be reverted before merge (the gemspec change to `~> 0.3.0` is the real dependency declaration).

### 7. `tool_call_id` on tool messages isn't indexed

The migration adds `tool_call_id` as a plain string column. If you ever need to look up tool results by their call ID, an index would help. Low priority for now.

### 8. The `visible` scope uses an allowlist, which is good

`scope :visible, -> { where(role: [:user, :assistant]) }` - correctly excludes `tool` and `system` messages. If new roles are added later, they'll be hidden by default. This is the right default.

## Trade-offs assessment

| Trade-off | Justified? |
|---|---|
| Tool execution is synchronous in the job | Yes - keeps it simple. Parallel tool execution can come later if needed. |
| 10-iteration cap | Reasonable safety valve. The warn log + appended message is good UX. |
| Tool definitions resolved per-request | Fine - allows dynamic tool sets per assistant. No caching needed yet. |
| No retry on tool execution failure | Correct - the error string goes back to the LLM which can decide what to do. |

## Improvements in order of priority

1. **Fix OpenAI tool parsing or disable tool passthrough for OpenAI** - this is the only blocking issue
2. **Remove `docs/managed_table_helper.md`** from this branch
3. **Revert Gemfile local path** before merge
4. Consider `serialize :tool_calls, coder: JSON` to eliminate parse guards
5. Add an index on `tool_call_id` if lookup patterns emerge

## Tests

The test suite (331 tests, all passing) includes good coverage of the ResponseService:

- No provider configured
- Simple streaming (no tools)
- Tool call loop with follow-up
- Max iterations guard
- Error handling (with and without partial content)
- Missing execute_tool_block
- Stopped message

The tests use a clean fake client pattern and properly save/restore global state. Well written.

## Verdict

This is a solid, well-structured implementation with one significant gap (OpenAI tool streaming) and a couple of housekeeping items. The core Anthropic path is correct and well-tested. The architecture decisions are sound - the extraction of `ResponseService`, the callback-based host integration, and the streaming accumulator are all the right abstractions at the right level.
