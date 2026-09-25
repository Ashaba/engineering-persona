# travel

Lens for travel and booking systems, where availability, consistency, and accurate
inventory and pricing drive customer trust.

## Criticality ordering

- Availability and graceful degradation. Prefer a degraded read over an outage.
- Data consistency across inventory, pricing, and bookings.
- Price and inventory accuracy at the moment of commit.
- Idempotency of bookings and payments; no double-charge, no double-book.
- Backward compatibility for downstream consumers of the API.

## Domain rules

- Never commit a booking or a charge against a cached or stale price; re-validate
  at commit time.
- Make booking and payment mutations idempotent with idempotency keys.
- Treat supplier and downstream failures as expected; map them without leaking
  internal names.
- Keep availability and pricing responses forward compatible; additive changes
  only.

## Inbox

<!-- Quick jots land here via capture.sh; curate above when convenient. -->
