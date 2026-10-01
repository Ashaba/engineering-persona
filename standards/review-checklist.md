# Review gates

Each gate is a challenge to raise against a diff. Findings cite file:line.

- What is the second consumer of this abstraction? If none, inline it.
- Does the framework, platform, or language already do this? If yes, use it.
- Does this duplicate existing code or a type? If yes, reuse the original.
- Can this field ever actually be null? If not, make it required, and validate at
  the boundary rather than defensively downstream.
- Is any of this unrelated to the task? If yes, remove or defer it.
- Does this swallow an error, leak an internal detail, or drop an upstream status?
- Does this change behavior for other callers, or let a contract or generated
  artifact drift from its source?
- Is this the current idiom for the language and tech, or a dated pattern?
- Was any assumption taken from a doc, README, or ticket without confirming it
  against the code or schema?
- Does this function's error handling or return type exist to suit one
  particular caller? If yes, move that policy to the caller.
- In suspend code, can a catch-all or runCatching swallow CancellationException
  and turn it into a log line, metric, or domain error?
- Can the schema represent a combination that makes no sense, such as a value
  without its qualifier or two fields stating the same fact differently? If yes,
  pair them, or document the valid combinations and reject the rest.
- Does this add a value to an output enum? Clients that reject unknown values
  break, so flag it to consumers.
- Is any type or field here for data no source supplies yet? If yes, defer it.

## Inbox

<!-- Quick jots land here via capture.sh; curate into gates above when convenient. -->
