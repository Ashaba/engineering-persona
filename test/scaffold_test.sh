#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

"$here/scaffold-repo.sh" "$tmp" >/dev/null
[ -f "$tmp/AGENTS.md" ] || { echo "FAIL: AGENTS.md not created"; exit 1; }
grep -q 'AGENTS.md' "$tmp/.github/copilot-instructions.md" || { echo "FAIL: copilot shim missing ref"; exit 1; }

# does not clobber an existing AGENTS.md
printf 'custom repo rules\n' > "$tmp/AGENTS.md"
"$here/scaffold-repo.sh" "$tmp" >/dev/null
grep -q 'custom repo rules' "$tmp/AGENTS.md" || { echo "FAIL: clobbered existing AGENTS.md"; exit 1; }

# does not clobber an existing copilot shim
printf 'custom shim\n' > "$tmp/.github/copilot-instructions.md"
"$here/scaffold-repo.sh" "$tmp" >/dev/null
grep -q 'custom shim' "$tmp/.github/copilot-instructions.md" || { echo "FAIL: clobbered existing copilot shim"; exit 1; }

# usage guard: missing arg exits non-zero
if "$here/scaffold-repo.sh" >/dev/null 2>&1; then echo "FAIL: missing arg accepted"; exit 1; fi
# usage guard: non-directory arg exits non-zero
if "$here/scaffold-repo.sh" "$tmp/does-not-exist" >/dev/null 2>&1; then echo "FAIL: non-directory arg accepted"; exit 1; fi

# domain: known domain inlines the lens into a fresh repo
d1="$(mktemp -d)"
"$here/scaffold-repo.sh" "$d1" finance-trading >/dev/null
grep -q '^Domain: finance-trading' "$d1/AGENTS.md" || { echo "FAIL: domain not declared"; exit 1; }
grep -q 'exact decimal types' "$d1/AGENTS.md" || { echo "FAIL: lens not inlined"; exit 1; }
if grep -q '## Inbox' "$d1/AGENTS.md"; then echo "FAIL: domain Inbox leaked into AGENTS.md"; exit 1; fi
rm -rf "$d1"

# domain: omitted leaves Domain unset
d2="$(mktemp -d)"
"$here/scaffold-repo.sh" "$d2" >/dev/null
grep -q '^Domain: unset' "$d2/AGENTS.md" || { echo "FAIL: expected Domain unset"; exit 1; }
rm -rf "$d2"

# domain: unknown domain is rejected (non-zero, no AGENTS.md written)
d3="$(mktemp -d)"
if "$here/scaffold-repo.sh" "$d3" nonsense-domain >/dev/null 2>&1; then echo "FAIL: unknown domain accepted"; exit 1; fi
if [ -e "$d3/AGENTS.md" ]; then echo "FAIL: AGENTS.md written for unknown domain"; exit 1; fi
rm -rf "$d3"

# domain: no-clobber still holds when a domain is passed
d4="$(mktemp -d)"
printf 'custom repo rules\n' > "$d4/AGENTS.md"
"$here/scaffold-repo.sh" "$d4" finance-trading >/dev/null
grep -q 'custom repo rules' "$d4/AGENTS.md" || { echo "FAIL: clobbered existing AGENTS.md with domain"; exit 1; }
rm -rf "$d4"

# domain: path-traversal name is rejected
d5="$(mktemp -d)"
if "$here/scaffold-repo.sh" "$d5" '../finance-trading' >/dev/null 2>&1; then echo "FAIL: traversal domain accepted"; exit 1; fi
rm -rf "$d5"

echo PASS
