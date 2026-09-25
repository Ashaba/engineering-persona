#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${PERSONA_REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

usage() { echo "usage: capture.sh <beliefs|voice|review> <note text>" >&2; exit 2; }

[ $# -ge 2 ] || usage
target="$1"; shift
note="$*"
[ -n "$note" ] || usage

case "$target" in
  beliefs) file="$REPO_DIR/persona/beliefs.md" ;;
  voice)   file="$REPO_DIR/persona/voice.md" ;;
  review)  file="$REPO_DIR/standards/review-checklist.md" ;;
  *) echo "unknown target: $target" >&2; usage ;;
esac

[ -f "$file" ] || { echo "missing file: $file" >&2; exit 1; }

if ! grep -q '^## Inbox' "$file"; then
  printf '\n## Inbox\n' >> "$file"
fi

printf -- '- [%s] %s\n' "$(date +%F)" "$note" >> "$file"
echo "captured to ${file#"$REPO_DIR"/}"
