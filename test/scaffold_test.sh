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

echo PASS
