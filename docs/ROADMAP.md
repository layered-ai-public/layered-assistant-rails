# Roadmap

Last updated: 2026-03-01

## Execution order

| # | Feature | Type | Rationale |
|---|---------|------|-----------|
| 1 | AMI deployment (private) | Infra | Enables paid supported versions. Cashflow first. Unlocks demo and real-user testing for everything that follows. |
| 2 | Personalities | AI feature | Quick win. Extends existing `system_prompt` on Assistant with pre-configured prompt templates/tone. Low complexity, high perceived value. |
| 3 | Embedded version (iframe + CSP) | Distribution | Gets the engine into other people's apps early. Value multiplies with each capability added after it. |
| 4 | Reasoning (COT display) | AI feature | Already supports reasoning models - this is exposing thinking tokens in the UI. Moderate effort, nice differentiation. |
| 5 | Skills | AI feature | The big capability unlock. Tool use / function calling turns chat into something that can act. Foundation for RAG (retrieval becomes a skill). |
| 6 | RAG + Memory | AI feature | Builds on top of Skills. See memory strategy below. |

## Memory strategy

### The problem

Every major provider has struggled with memory:

- **ChatGPT** auto-extracts facts silently. 300+ complaint threads since mid-2025. Two-thirds of "Memory updated" confirmations later found missing or corrupted. ~100 memory slot cap means constant pruning.
- **Gemini** categorises memories into a structured `user_context` document (demographics, interests, relationships, dated events). Better architecture, but Google renamed "Saved Info" to "Instructions", so the model treats personal facts as directives and injects them into every response regardless of relevance. Users call it "unhinged".
- **Claude** uses explicit tool-based retrieval. Transparent and predictable but lower discoverability for non-technical users.

The core tension: **categorising memories is the easy part. Knowing when to surface them is the hard part.**

### Proposed approach: interview + RAG

Two complementary layers that avoid the pitfalls:

#### 1. Persistent facts (via interview skill)

- A one-time structured conversation between the user and the assistant, triggered as a Skill
- The assistant asks questions relevant to its purpose (a cooking assistant asks about dietary needs, a coding assistant asks about tech stack)
- Output is stored as structured facts appended to the assistant's system prompt
- User can review and edit the extracted facts afterwards (profile page)
- Updated by re-running the interview when things change

**Why this works:**
- No silent inference - facts come from an explicit, user-initiated conversation
- No relevance scoring problem - facts are curated by the user so always appropriate
- Sets clear expectations (it's a profile, not surveillance)
- Interview skill can be customised per assistant by the host app

#### 2. Conversation summaries (via RAG)

- Auto-generated when a conversation closes
- Stored externally with embeddings
- Retrieved by semantic similarity only when relevant to the current query
- Never auto-injected into every conversation

**Why this works:**
- Keeps the context window clean by default
- If retrieval misses, you just get a slightly less informed response (not a confused one)
- Summaries are timestamped and naturally decay in relevance
- No stale data accumulating in every prompt

#### How the layers interact

| Layer | Source | Update frequency | Injection method |
|-------|--------|-----------------|------------------|
| Persistent facts | Interview skill | Rarely (user re-runs) | Always in system prompt |
| Conversation summaries | Auto on close | Every conversation | RAG retrieval, only when relevant |

### Key lessons from the market

- **Don't auto-extract facts from conversations.** ChatGPT and Gemini both prove this leads to noisy, wrong, or stale memories that erode trust.
- **Don't treat personal facts as instructions.** Gemini's mistake. A fact ("user is vegetarian") is not a directive ("always mention vegetarianism").
- **Don't auto-inject everything.** Context pollution degrades response quality. Studies show superfluous context actively confuses models. GPT-4 accuracy drops from 99% to 70% with 32k tokens.
- **Let the host app control policy.** As an engine, layered-ui-assistant should provide the memory infrastructure but let host apps decide what to collect and when to surface it.
- **Let users see what's stored.** A reviewable/editable profile page closes the trust loop.

## Notes

- Conversation context/memory (cross-conversation awareness) was considered as a standalone feature but is better addressed as part of the RAG + memory work.
- The interview skill depends on Skills being implemented first (execution order matters).
- Embedded version should ship after Personalities so it launches with more than bare chat.
- Reasoning is self-contained and could be swapped with Embedded in priority if needed.

## References

- [Simon Willison - Comparing Claude and ChatGPT memory](https://simonwillison.net/2025/Sep/12/claude-memory/)
- [ChatGPT's silent memory crisis](https://www.allaboutai.com/ai-news/why-openai-wont-talk-about-chatgpt-silent-memory-crisis/)
- [Gemini personal context is "unhinged"](https://vertu.com/lifestyle/google-geminis-personal-context-is-unhinged/)
- [Google has your data, Gemini barely uses it](https://www.shloked.com/writing/gemini-memory)
- [MemGPT: adaptive retention and summarisation](https://informationmatters.org/2025/10/memgpt-engineering-semantic-memory-through-adaptive-retention-and-context-summarization/)
- [JetBrains - efficient context management](https://blog.jetbrains.com/research/2025/12/efficient-context-management/)
- [How long contexts fail](https://www.dbreunig.com/2025/06/22/how-contexts-fail-and-how-to-fix-them.html)
- [Letta - agent memory](https://www.letta.com/blog/agent-memory)
