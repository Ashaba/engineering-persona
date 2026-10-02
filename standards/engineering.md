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
- Match the established sibling implementation for tagging, reporting, and auth.
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
