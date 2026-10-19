# Review gates

Each gate is a challenge to raise against a diff. Findings cite file:line.

- What is the second consumer of this abstraction? If none, inline it.
- Does the framework, platform, or language already do this? If yes, use it.
- Does this duplicate existing code or a type? If yes, reuse the original.
- Can this field ever actually be null? If not, make it required, and validate at
  the boundary rather than defensively downstream. If it can, because the data
  is filled in later, is missing from old records, or the code that fills it
  can return nothing, make it optional. In a schema that returns partial
  results, that includes a field filled by a remote call that can fail.
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
- Does this read a list page by page while the list can change? Items can then
  show up twice or be missed. Remove duplicates, or use a cursor instead of page
  numbers.
- Does this code skip the shared way of getting something that the rest of the
  code uses? For example, other callers get a client by asking a picker, but
  this code builds or injects the client directly. If yes, make it use the
  picker too.
- Does this add a new null or failure mode? Follow it to its last consumer.
  What happens there?
- Which way did a nullability change go? An input that becomes required breaks
  callers. An output that becomes nullable breaks clients. A new field on an
  existing input must be optional or have a default, even where fields are
  required by default.
- Does this follow an existing pattern that breaks a standard? Matching old
  code is still a violation. Fix the new code and record the old cases for
  follow-up.
- Do operations that work as a pair, such as preview and execute, agree on
  input fields, return shapes, and nullability?
- Does a name repeat what its parent already says, such as a name field on a
  Property type called propertyName? Keep only the part that tells it apart
  from its siblings, unless what is left is a vague word like type or id.
- Is invalid output patched after the fact? Fix it where it is produced, and
  have the producer run the same validator so it cannot write a bad result.

## Inbox

<!-- Quick jots land here via capture.sh; curate into gates above when convenient. -->
