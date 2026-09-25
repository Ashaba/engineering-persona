# agriculture

Lens for agriculture and agri-tech systems. This is a thin starter; enrich it via
the Inbox as real needs appear rather than treating it as authoritative.

## Criticality ordering

- Units and measurement correctness (area, weight, volume, temperature); a unit
  mistake ruins downstream calculations.
- Time and season correctness; many operations are tied to narrow windows.
- Data provenance from sensors and field inputs, which are often noisy or missing.

## Domain rules

- Make units explicit in types and at boundaries; never assume a default unit.
- Handle missing or delayed sensor data explicitly; do not treat absence as zero.

## Inbox

<!-- Quick jots land here via capture.sh; curate above when convenient. -->
