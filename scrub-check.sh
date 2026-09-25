#!/usr/bin/env bash
set -euo pipefail

# Exit 0 if the input line is generic and safe to store in the personal repo.
# Exit non-zero if it contains internal-specific markers that must not leak.
# This is a coarse backstop, not the boundary. The real controls are the model
# generalizing away internal specifics and the human PR gate; this catches only
# obvious leaks (URLs, code spans, uppercase ticket ids, filenames, org names).
line="${1:-}"
[ -n "$line" ] || { echo "scrub: empty input" >&2; exit 2; }

fail() { echo "scrub: rejected ($1)" >&2; exit 1; }

case "$line" in *'`'*) fail "code-span" ;; esac
printf '%s' "$line" | grep -Eiq 'https?://' && fail "url"
printf '%s' "$line" | grep -Eq '\b[A-Z][A-Z0-9]+-[0-9]+\b' && fail "ticket-id"
printf '%s' "$line" | grep -Eq '[[:alnum:]_-]+\.[a-z]{2,12}\b' && fail "filename"
printf '%s' "$line" | grep -Eiq 'eg-internal|expediagroup|expedia' && fail "internal-name"

exit 0
