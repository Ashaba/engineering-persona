#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target="${1:-}"
{ [ -n "$target" ] && [ -d "$target" ]; } || { echo "usage: scaffold-repo.sh <path-to-repo>" >&2; exit 2; }

agents="$target/AGENTS.md"
copilot_dir="$target/.github"
copilot="$copilot_dir/copilot-instructions.md"

if [ -e "$agents" ]; then
  echo "skip: $agents already exists (edit by hand to avoid clobbering)"
else
  cp "$REPO_DIR/standards/AGENTS.template.md" "$agents"
  echo "created $agents"
fi

mkdir -p "$copilot_dir"
if [ -e "$copilot" ]; then
  echo "skip: $copilot already exists"
else
  printf 'See [AGENTS.md](../AGENTS.md) for engineering standards and review expectations.\n' > "$copilot"
  echo "created $copilot"
fi
