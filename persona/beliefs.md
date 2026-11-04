---
trigger: always_on
---

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
  For a value another service sends, read where it is set, not only the comment
  on it in the contract. The comment can describe less than the code does.
- Verify before asserting. Do not push changes or call work done until all checks
  pass (build, tests, lint, CI). Rely on real output, not assumptions.
- Design a function around its own contract, not its caller's. It does its job
  and throws when it can't. The caller owns policy such as isolation, retries,
  fallbacks, and aggregating results. If a comment justifies a callee's behavior
  by describing its caller, the responsibility is in the wrong place.
- Add new behavior by adding a new piece, not a new if statement. For example, to
  support a new way to send alerts, write a new sender and add it to the list in
  config. Do not add another branch inside the code that already sends alerts.
- There should be one way to get each thing. If code picks between two versions
  of a client, every caller asks the same picker, even callers that always want
  the normal version. For example, do not hand out the normal client directly
  while the test client goes through the picker.
- Put a setting where the call is defined, not on every caller. If one call
  needs a longer timeout or a special header, the client applies it. A setting
  each caller must remember to pass fails quietly when one forgets.
- Turn raw flags and strings into named types as soon as they arrive. For
  example, turn a true or false "is test" flag into a type with the values Live
  and Test. Then handle the values in a switch with no default branch, so adding
  a new value will not compile until every switch handles it.
- The no-default switch is for your own types. A value from another service can
  be one your copy of its contract does not know yet. Type the raw field to allow
  that, map an unknown value to an explicit fallback, and log a warning that
  names it. Both a crash and a silent fallback are wrong.
- Key a lookup table by its named type, not a plain string. A map from one enum
  to another is typed over both, so a missing or mistyped key will not compile.
- Name things for exactly what they are. A field called "variant" or "type"
  makes the reader guess. "trafficVariant" or "paymentType" does not.
- An approval step is not a safety boundary. Do not start something that can
  reach production and count on a manual approval to stop it. If the safe path
  is broken, fix it or ask a person. Never fall back to the path that can do
  harm.
- "Could not check" is not "found nothing". When a lookup fails, record the
  result as unknown and say the run is incomplete. Never store a failure as a
  negative answer, and never fill the gap with a guess.

## Inbox

<!-- Quick jots land here via capture.sh; curate into rules above when convenient. -->
