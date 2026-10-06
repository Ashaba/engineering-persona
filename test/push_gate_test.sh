#!/usr/bin/env bash
# The gate that stops a push until pre-flight-review has run on that commit.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
gate="$here/hooks/require-pre-flight-review.sh"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

repo="$tmp/repo"
git init -q "$repo"
git -C "$repo" -c user.email=t@t -c user.name=t commit -q --allow-empty -m first
export DEVIN_PROJECT_DIR="$repo"

# Returns the hook's stdout for a given exec command.
ask() { printf '{"tool_input":{"command":"%s"}}' "$1" | bash "$gate"; }

blocked() {
  ask "$1" | grep -q '"decision": "block"' \
    || { echo "FAIL: '$1' should have been blocked"; exit 1; }
}
allowed() {
  [ -z "$(ask "$1")" ] \
    || { echo "FAIL: '$1' should have been allowed"; exit 1; }
}

# ── Unreviewed commit ─────────────────────────────────────────────────────────
blocked "git push -u origin my-branch"
blocked "gh pr create --base main --title x --body y"

# The reason has to say what to do, or an agent just retries the same thing.
ask "git push" | grep -q 'pre-flight-review skill' \
  || { echo "FAIL: block reason does not name the skill"; exit 1; }

# ── Commands that are none of its business ────────────────────────────────────
allowed "git status"
allowed "git commit -m wip"
allowed "git fetch origin"
allowed "gh pr list"
allowed "pytest -q"

# ── Once reviewed ─────────────────────────────────────────────────────────────
head="$(git -C "$repo" rev-parse HEAD)"
mkdir -p "$repo/.git/pre-flight-review"
touch "$repo/.git/pre-flight-review/$head"
allowed "git push -u origin my-branch"
allowed "gh pr create --base main --title x --body y"

# ── Approval does not carry to a new commit ───────────────────────────────────
# The thing reviewed has to be the thing pushed, so amending or adding a commit
# invalidates it. Without this the gate is a one-time formality per branch.
git -C "$repo" -c user.email=t@t -c user.name=t commit -q --allow-empty -m second
blocked "git push -u origin my-branch"

# ── No one-line bypass ────────────────────────────────────────────────────────
# A --dry-run exemption would match a real push chained after a dry one.
rm -f "$repo/.git/pre-flight-review/$head"
blocked "git push --dry-run origin main"
blocked "git push --dry-run origin main && git push origin main"

# ── Outside a repository it has nothing to say ────────────────────────────────
DEVIN_PROJECT_DIR="$tmp" allowed "git push"

# ── An unreadable event is logged, not silently ignored ───────────────────────
# Silence here would leave the gate off with nobody aware, which is how the
# skill came to be skipped. Exit 1 is logged by Devin and does not block.
if printf 'not json' | bash "$gate" 2>/dev/null; then
  echo "FAIL: malformed event should exit non-zero"; exit 1
fi
# Captured to a file rather than piped: the gate exits non-zero here, and
# pipefail would read that as the assertion itself failing.
printf 'not json' | bash "$gate" >/dev/null 2>"$tmp/err" || true
grep -q 'could not read' "$tmp/err" \
  || { echo "FAIL: malformed event should say so on stderr"; exit 1; }

echo PASS
