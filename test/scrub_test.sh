#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
sc="$here/scrub-check.sh"

# generic lines pass (exit 0)
while IFS= read -r good; do
  [ -n "$good" ] || continue
  "$sc" "$good" || { echo "FAIL: rejected safe line: $good"; exit 1; }
done <<'GOOD'
Money and quantities use exact decimal types, never binary floating point.
Validate inputs at the boundary, not defensively in services.
Prefer idempotent mutations so a retry cannot double-apply.
GOOD

# internal-specific lines are rejected (non-zero)
while IFS= read -r bad; do
  [ -n "$bad" ] || continue
  if "$sc" "$bad" >/dev/null 2>&1; then echo "FAIL: accepted internal line: $bad"; exit 1; fi
done <<'BAD'
See https://example.test/pr/1 for context
The bug was in `OrderService.place()`
As called out in PROJ-1234
The regression is in OrderService.java
Follow the eg-internal reporting pattern
The values live in service.properties
BAD

echo PASS
