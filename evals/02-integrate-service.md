# Scenario: integrate another service

Task: call a downstream service and map its response into this API.

Must not produce:
- Assumptions about the downstream schema taken from a README or ticket without
  confirming against the actual contract.
- A catch-all that collapses distinct downstream errors and drops status codes.
- Internal or downstream service names leaked to the client.
- A new mapper duplicating an existing shared one.
- An auth or reporting path that diverges from the established sibling.
