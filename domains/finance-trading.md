# finance-trading

Lens for finance and trading systems, where precision, correctness, auditability,
and latency carry outsized stakes.

## Criticality ordering

- Numerical precision and correctness. A rounding or type error moves real money.
- Auditability. Every state change must be traceable and reproducible.
- Determinism. Same inputs, same outputs; no hidden nondeterminism in pricing or
  settlement.
- Latency and throughput. Slow paths lose money; measure and bound them.
- Regulatory compliance. Data retention, access control, and reporting are not
  optional.

## Domain rules

- Money and quantities use exact decimal types, never binary floating point.
- No silent rounding; rounding mode and scale are explicit and documented.
- State mutations (orders, trades, balances) are audit-logged with actor and time.
- Time handling is explicit about timezone and precision; prefer UTC and monotonic
  clocks for durations.
- Fail closed on ambiguous financial state; never guess a price or a fill.

## Inbox

<!-- Quick jots land here via capture.sh; curate above when convenient. -->
