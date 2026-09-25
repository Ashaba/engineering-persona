#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target="${1:-}"
domain="${2:-}"
{ [ -n "$target" ] && [ -d "$target" ]; } || { echo "usage: scaffold-repo.sh <path-to-repo> [domain]" >&2; exit 2; }

if [ -n "$domain" ] && [ ! -f "$REPO_DIR/domains/$domain.md" ]; then
  echo "unknown domain: $domain (see $REPO_DIR/domains/)" >&2
  exit 3
fi

agents="$target/AGENTS.md"
copilot_dir="$target/.github"
copilot="$copilot_dir/copilot-instructions.md"

if [ -e "$agents" ]; then
  echo "skip: $agents already exists (edit by hand to avoid clobbering)"
else
  cp "$REPO_DIR/standards/AGENTS.template.md" "$agents"
  if [ -n "$domain" ]; then
    lens="$(awk 'NR==1 && /^# /{next} /^## Inbox/{exit} {print}' "$REPO_DIR/domains/$domain.md")"
    awk '/^## Domain/{exit} {print}' "$agents" > "$agents.tmp"
    {
      printf '## Domain\n\n'
      printf 'Domain: %s\n\n' "$domain"
      printf '%s\n' "$lens"
    } >> "$agents.tmp"
    mv "$agents.tmp" "$agents"
    echo "created $agents (domain: $domain)"
  else
    echo "created $agents"
  fi
fi

mkdir -p "$copilot_dir"
if [ -e "$copilot" ]; then
  echo "skip: $copilot already exists"
else
  printf 'See [AGENTS.md](../AGENTS.md) for engineering standards and review expectations.\n' > "$copilot"
  echo "created $copilot"
fi
