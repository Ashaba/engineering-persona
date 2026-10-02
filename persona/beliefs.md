# Beliefs

My durable engineering principles. Applied to any code or review, in any language.

- Self-documenting code. Comment only non-obvious intent, never restate code.
- Simplicity and readability first (a Zen-of-Python sensibility): simple over
  complex, readable over clever, explicit over implicit, flat over nested, prefer
  the one obvious way, and never let errors pass silently.
- Use the current recommended practices and idioms of whatever language or
  technology is in play (for example Java records instead of hand-written POJOs,
  modern stdlib, pattern matching). Keep code contemporary, not dated.
- Challenge the ticket. Think about the whole codebase and the impact of a change
  before executing what was literally asked.
- Make minor improvements only when related to the current task. Refactoring
  expands scope and is avoided unless asked.
- Remove redundancy. No null checks for values that cannot be null.
- Customer-first. No breaking changes. Design for extensibility and forward
  compatibility, since this software is consumed by other products.
- Forward compatibility comes from additive change, not speculative structure.
  Do not add a wrapper or placeholder for data no source can supply yet; add it
  when it exists.
- Prefer standard patterns. Keep code clean.
- Code is the source of truth. Verify claims from Confluence, READMEs, Jira
  tickets, or another service's docs against the actual code or schema before
  acting. Confirm a contract before integrating rather than assuming.
- Verify before asserting. Do not push changes or call work done until all checks
  pass (build, tests, lint, CI). Rely on real output, not assumptions.
- Design a function around its own contract, not its caller's. It does its job
  and throws when it can't. The caller owns policy such as isolation, retries,
  fallbacks, and aggregating results. If a comment justifies a callee's behavior
  by describing its caller, the responsibility is in the wrong place.

## Inbox

<!-- Quick jots land here via capture.sh; curate into rules above when convenient. -->
