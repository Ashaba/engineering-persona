# Engineering standards

Team and industry standards. Kept generic so they age well; tailor specifics per repo.

- Reuse platform and framework features before building new (platform APM over
  custom metrics; framework exception handling; standard pagination types; existing
  error mappers and enums).
- DTOs are required-by-default. Validate at the controller/bean-validation
  boundary, not defensively in services.
- Prefer domain/application error codes over raw HTTP. Never leak internal or
  downstream names to clients. Preserve upstream status codes via shared mappers.
- Keep generated types (for example GraphQL) committed and in sync with the schema.
- Match the established sibling implementation for tagging, reporting, and auth,
  where it meets these standards.
- Do not touch shared handlers or config unrelated to the change. Keep PRs single
  purpose.
- Coverage must not regress.
- Follow the repo PR template and the branch/commit conventions.
- In Kotlin suspend code, cancellation is control flow, not an error. A
  catch (e: Exception) or runCatching also catches CancellationException, so
  rethrow it before any catch-all. Only the component that owns the concurrency
  (the one that launched the siblings) catches broadly, to isolate one failure
  from the rest, and it logs and counts what it catches. Narrow catches are fine
  in sequential code, but check the list against what the client and its filters
  really throw.
- Create clients in one place. Client classes are plain classes with no
  framework annotations. Build them in a configuration class and pass them to
  the code that needs them. All connection setup then lives in one place, and
  the classes are easy to test.
- Check config when the app starts, and stop if it is wrong. For example, if
  config names an alert channel that does not exist, the app should fail to
  start, not quietly skip that channel later.
- Assume failure until success is proven. Start a result as "failed" and change
  it to "succeeded" only after the work finishes. If something unexpected goes
  wrong, it is reported as a failure, never as a success.
- Limit how many calls run at the same time. When one request turns into many
  calls (for example, notify every subscriber), cap how many run at once with a
  setting. Without a cap, one big request can overload the service you call.
- Background work brings its own context. Work that keeps running after the
  request ends carries its own request ID for logs. It does not rely on what was
  set on the thread that started it.
- For an endpoint that accepts work and finishes it later, the docs say what
  "accepted" means: the work is now this service's job, the caller should not
  retry, and which input fields are used.
- In tests, build test data with helper functions where every field has a
  default. Each test then sets only the fields it cares about.
- A deploy is done only when the evidence points at the version you shipped,
  by commit or start time. A successful trigger proves nothing, and healthy
  signals can come from the old version still running.
- Bulk writes that replace existing data, such as backfills and migrations,
  show a dry-run diff first, take a backup, and read the result back after.
  They are safe to re-run. If the diff deletes more than you expected, stop
  and ask.
- A hook or helper script that fails on its own error reports the error and
  lets the main flow go on. It blocks only when blocking is its job.
- In hooks and helper scripts, every outside call has a timeout. Run commands
  with an argument list, not a shell string, and pass untrusted text through
  environment variables.
- In a GraphQL schema, lists default to a non-null list of non-null items, and
  return an empty list rather than null when there is nothing to return. A list
  filled by a call that can fail is nullable, so a failure reads as null, not
  as empty. A mutation takes one input object and returns its own result type,
  so both can gain fields later without a breaking change. Value types such as
  money, address, or phone number have one definition across a shared graph.
- Rate a schema problem by whether it has shipped. In an unreleased element,
  fix it before merge, since that is the cheap moment. A released element is
  fixed additively: add the corrected element and deprecate the old one.
- In CI, pin third-party actions to a commit, give each job only the
  permissions it needs, and cancel PR runs that a newer push replaced.
