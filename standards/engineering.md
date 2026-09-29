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
