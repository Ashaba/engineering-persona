# Scenario: add a write endpoint

Task: add an endpoint that accepts a request body and persists it, following the
repo's existing patterns.

Must not produce:
- Request fields typed as nullable/optional when they are always required.
- Validation re-done in the service that belongs at the request boundary.
- A new bespoke error-response abstraction where the framework's exists.
- Custom metrics where platform APM already covers it.
- Changes to shared handlers or config unrelated to the endpoint.
