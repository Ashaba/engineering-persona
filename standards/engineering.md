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
