#!/usr/bin/env bash
# Refuse to push or open a PR until pre-flight-review has run on this commit.
#
# The skill has always said to run it before pushing, and on 2026-10-05 an agent
# opened eleven pull requests across two repositories without once invoking it.
# A description an agent is free to skip is a description it will skip, the same
# way AGENTS.md did not stop a commit landing on main. That one became
# guard-branch.sh. This is the same move for the same reason.
#
# Approval is recorded against the exact commit, so amending or adding one
# invalidates it and the review happens again on what is actually being pushed.
#
# stdin: PreToolUse event JSON. stdout: a block decision, or nothing.
set -uo pipefail

payload="$(cat)"

if ! cmd="$(printf '%s' "$payload" | python3 -c '
import json, sys
print(json.load(sys.stdin).get("tool_input", {}).get("command", ""))
')"; then
  # An event this cannot read means the schema moved. Exit non-zero but not 2:
  # Devin logs it and lets the call through. Blocking every shell command on a
  # payload change would brick the agent, and failing silently would leave the
  # gate quietly off, which is how the skill came to be skipped in the first
  # place. Loud and open beats either.
  echo "require-pre-flight-review: could not read the hook event" >&2
  exit 1
fi

# Only the two commands that put work in front of a human. Local commits,
# fetches and status calls are none of this hook's business.
#
# No exemption for --dry-run. It would be a reasonable one, but "contains
# --dry-run" also matches `git push --dry-run && git push`, and a gate with a
# one-line bypass is decoration. Checking a merge locally does not need a push.
case "$cmd" in
  *"git push"*|*"gh pr create"*) ;;
  *) exit 0 ;;
esac

cd "${DEVIN_PROJECT_DIR:-.}" 2>/dev/null || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

head="$(git rev-parse HEAD 2>/dev/null)" || exit 0
marker="$(git rev-parse --git-dir)/pre-flight-review/$head"

[ -f "$marker" ] && exit 0

cat <<JSON
{
  "decision": "block",
  "reason": "Pre-flight review has not run on commit ${head:0:12}. Invoke the pre-flight-review skill, fix what it finds, and record it by writing an empty file at $marker. Approval is per commit, so amending or adding one requires reviewing again."
}
JSON
exit 0
