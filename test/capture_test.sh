#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/persona"
printf '# Beliefs\n\n- existing rule\n' > "$tmp/persona/beliefs.md"

# creates Inbox and appends note
PERSONA_REPO_DIR="$tmp" "$here/capture.sh" beliefs 'always verify assumptions'
grep -q '^## Inbox' "$tmp/persona/beliefs.md" || { echo "FAIL: no Inbox created"; exit 1; }
grep -q 'always verify assumptions' "$tmp/persona/beliefs.md" || { echo "FAIL: note missing"; exit 1; }

# second call does not create a second Inbox heading
PERSONA_REPO_DIR="$tmp" "$here/capture.sh" beliefs 'second note'
[ "$(grep -c '^## Inbox' "$tmp/persona/beliefs.md")" -eq 1 ] || { echo "FAIL: duplicate Inbox"; exit 1; }

# metacharacters appended literally
PERSONA_REPO_DIR="$tmp" "$here/capture.sh" beliefs 'use $VAR and `cmd` "quoted"'
grep -qF 'use $VAR and `cmd` "quoted"' "$tmp/persona/beliefs.md" || { echo "FAIL: metachars mangled"; exit 1; }

# empty note is rejected
if PERSONA_REPO_DIR="$tmp" "$here/capture.sh" beliefs '' 2>/dev/null; then
  echo "FAIL: empty note accepted"; exit 1
fi

echo PASS
