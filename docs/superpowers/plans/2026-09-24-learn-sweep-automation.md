# Learn-Sweep Automation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A local scheduled sweep that reads new eg-internal PR reviews, generalizes them into persona rules with a hard scrub of internal specifics, and opens a gated PR on the personal persona repo.

**Architecture:** A launchd job runs `run-sweep.sh`, which invokes Claude Code headless against a `learn-sweep` skill. The skill fetches review comments (gh, work account), generalizes and scrubs each into a rule, dedups, classifies, then branches/commits/pushes and opens a PR (gh, Ashaba). `scrub-check.sh` is the data-boundary guard. The source (host/org/query) lives in one place for future configurability. Nothing merges or touches main unattended.

**Tech Stack:** Bash, Markdown, Claude Code CLI (`-p`, `--allowed-tools`, `--add-dir`, `--permission-mode`), launchd, gh, git.

**Spec:** docs/superpowers/specs/2026-09-24-learn-sweep-automation-design.md

## Global Constraints

- Hand-authored; no build tooling; no em-dashes or emojis in prose.
- The sweep only ever OPENS a PR. It never merges, never commits to `main`, never posts or replies on a source PR.
- Internal content stays local: only generalized rules reach the personal repo, and every rule passes `scrub-check.sh` first; anything that fails is dropped and logged, not written.
- The review source (host `github.com`, org `eg-internal`, authored-PRs query) is defined in exactly one place in the skill, so making it configurable later is additive.
- Watermark state lives outside the repo at `~/.claude/engineering-persona/last-sweep`.
- Reads use the work gh account; the gate PR uses the Ashaba gh account. The two are never crossed.
- Work on branch `NO_JIRA_learn-sweep-automation` (already checked out, off `main`). Commit after each task with the `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>` trailer.

## Review Focus

- `scrub-check.sh` must reject a line containing a URL, a backtick/code span, a `PROJ-1234` ticket ID, a filename with an extension, or an internal org name, and must pass a generic rule line. (Task 1)
- The `learn-sweep` skill text must explicitly forbid merging the gate PR, posting to the source PR, and committing to `main`. (Task 2)
- `run-sweep.sh` must call Claude with a scoped `--allowed-tools` set (git, gh, the scrub script, file edits), not `--dangerously-skip-permissions`. (Task 3)
- `schedule-sweep.sh` must be idempotent, removable, and must not perform real `launchctl` calls when `LAUNCH_AGENTS_DIR` is set (test mode). (Task 4)
- The source definition must appear exactly once in the skill (host/org/query together), so a future config overrides one place. (Task 2)

---

### Task 1: `scrub-check.sh` data-boundary guard (TDD)

**Files:**
- Create: `scrub-check.sh`
- Test: `test/scrub_test.sh`

**Interfaces:**
- Consumes: nothing.
- Produces: `scrub-check.sh "<line>"` exits 0 if the line is generic/safe, non-zero if it contains an internal-specific marker. Used by the `learn-sweep` skill on every proposed rule.

- [ ] **Step 1: Write the failing test `test/scrub_test.sh`**

```bash
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
BAD

echo PASS
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `chmod +x test/scrub_test.sh && bash test/scrub_test.sh`
Expected: FAIL (scrub-check.sh does not exist yet).

- [ ] **Step 3: Write `scrub-check.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Exit 0 if the input line is generic and safe to store in the personal repo.
# Exit non-zero if it contains internal-specific markers that must not leak.
line="${1:-}"
[ -n "$line" ] || { echo "scrub: empty input" >&2; exit 2; }

fail() { echo "scrub: rejected ($1)" >&2; exit 1; }

case "$line" in *'`'*) fail "code-span" ;; esac
printf '%s' "$line" | grep -Eiq 'https?://' && fail "url"
printf '%s' "$line" | grep -Eq '\b[A-Z][A-Z0-9]+-[0-9]+\b' && fail "ticket-id"
printf '%s' "$line" | grep -Eq '[[:alnum:]_-]+\.[a-z]{2,5}\b' && fail "filename"
printf '%s' "$line" | grep -Eiq 'eg-internal|expediagroup|expedia' && fail "internal-name"

exit 0
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `bash test/scrub_test.sh`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
chmod +x scrub-check.sh
git add scrub-check.sh test/scrub_test.sh
git commit -m "NO_JIRA add scrub-check.sh data-boundary guard with tests

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 2: `learn-sweep` skill

**Files:**
- Create: `skills/learn-sweep/SKILL.md`

**Interfaces:**
- Consumes: `scrub-check.sh` (Task 1), the persona files via `../../`, `gh`, `git`.
- Produces: an installable skill that performs the full sweep and opens a gated PR.

- [ ] **Step 1: Write `skills/learn-sweep/SKILL.md`**

```markdown
---
name: learn-sweep
description: Scheduled sweep that reads new eg-internal PR reviews since a watermark, generalizes and scrubs them into persona rules, and opens a gated PR on this repo. Runs locally. Never merges, never commits to main, never posts to a source PR.
---

# Learn Sweep

Automated, gated version of learn-from-review. Runs unattended and proposes
learnings as a pull request.

## Source (defined once)

- host: `github.com`
- org: `eg-internal`
- query: pull requests the current user authored
This block is the only place the source is defined; a future config overrides it.

## Accounts

- Read reviews with the work gh account (github.com, work identity).
- Open the gate PR with the `Ashaba` gh account.
Never cross them: internal reads use work; the personal repo uses Ashaba.

## Watermark

`~/.claude/engineering-persona/last-sweep` holds an ISO timestamp. If absent, use
7 days ago. Update it to now only after a successful run.

## Steps

1. Check gh auth and network. If either is missing, log and exit without changing
   the watermark.
2. List PRs from the source (authored) with review activity since the watermark;
   collect review comment bodies.
3. For each actionable comment, write the missed pattern as one generalized
   sentence: no code, URLs, repo or service names, ticket IDs, or paths.
4. Run each proposed rule through `../../scrub-check.sh "<rule>"`. If it exits
   non-zero, drop the rule and log that one was dropped (never write it).
5. Classify each surviving rule into `../../persona/beliefs.md`,
   `../../persona/voice.md`, `../../standards/engineering.md`,
   `../../standards/review-checklist.md`, or `../../domains/<domain>.md`. Dedup
   against the current file contents.
6. If any rules survive: create branch `NO_JIRA_learned-<YYYY-MM-DD>`, append each
   rule to its target section, commit, push (ash key), and open a PR with the
   Ashaba account titled `NO_JIRA learned rules (<YYYY-MM-DD>)`. The PR body lists
   each rule and its layer and notes it was auto-derived and generalized. No
   internal specifics anywhere.
7. Update the watermark to now.

## Rules

- Only open a PR. Never merge it, never commit to `main`, never post or reply on a
  source PR.
- One rule per pattern; generalized wording only.
- If nothing survives the scrub and dedup, exit cleanly with no branch and no PR.
```

- [ ] **Step 2: Validate the skill**

Invoke the `platform-skills:skill-validator` skill against `skills/learn-sweep/SKILL.md`.
Expected: PASS (valid frontmatter; name and description within limits).

- [ ] **Step 3: Commit**

```bash
git add skills/learn-sweep/SKILL.md
git commit -m "NO_JIRA add learn-sweep skill (gated, scrubbed, source-in-one-place)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 3: `run-sweep.sh` headless wrapper

**Files:**
- Create: `run-sweep.sh`

**Interfaces:**
- Consumes: the `learn-sweep` skill, the Claude CLI.
- Produces: `run-sweep.sh` that runs the sweep headless with a scoped allowlist and appends output to a log.

- [ ] **Step 1: Write `run-sweep.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="${SWEEP_LOG:-$HOME/.claude/engineering-persona/sweep.log}"
mkdir -p "$(dirname "$LOG")"

PROMPT="Run the learn-sweep skill: sweep new eg-internal PR reviews since the watermark, generalize and scrub them into persona rules, dedup, and open a single gated PR on this repo. Do not merge it, do not commit to main, do not post to any source PR."

{
  echo "=== sweep $(date -u +%FT%TZ) ==="
  claude -p "$PROMPT" \
    --add-dir "$REPO_DIR" \
    --allowed-tools "Bash(git *) Bash(gh *) Bash($REPO_DIR/scrub-check.sh *) Read Edit Write" \
    --permission-mode acceptEdits
  echo "=== done $(date -u +%FT%TZ) ==="
} >> "$LOG" 2>&1
```

- [ ] **Step 2: Syntax-check and confirm flags**

Run: `chmod +x run-sweep.sh && bash -n run-sweep.sh && echo OK`
Expected: prints `OK`. Then confirm the flags used exist: `claude --help | grep -E -- '--allowed-tools|--add-dir|--permission-mode|--print'`. If a flag name differs in this CLI version, adjust `run-sweep.sh` to match and re-run `bash -n`.

- [ ] **Step 3: Commit**

```bash
git add run-sweep.sh
git commit -m "NO_JIRA add run-sweep.sh headless wrapper with scoped allowlist

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 4: `schedule-sweep.sh` launchd installer (TDD)

**Files:**
- Create: `schedule-sweep.sh`
- Test: `test/schedule_test.sh`

**Interfaces:**
- Consumes: `run-sweep.sh` (as the program the job runs).
- Produces: `schedule-sweep.sh` that installs a daily launchd job, `--remove` to uninstall; honors `LAUNCH_AGENTS_DIR` and `SWEEP_HOUR`; skips real `launchctl` calls when `LAUNCH_AGENTS_DIR` is set.

- [ ] **Step 1: Write the failing test `test/schedule_test.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
export LAUNCH_AGENTS_DIR="$tmp/agents"
plist="$LAUNCH_AGENTS_DIR/com.engineering-persona.learn-sweep.plist"

"$here/schedule-sweep.sh" >/dev/null
[ -f "$plist" ] || { echo "FAIL: plist not installed"; exit 1; }
grep -q 'run-sweep.sh' "$plist" || { echo "FAIL: plist missing program"; exit 1; }
grep -q '<key>StartCalendarInterval</key>' "$plist" || { echo "FAIL: no schedule"; exit 1; }

"$here/schedule-sweep.sh" --remove >/dev/null
if [ -e "$plist" ]; then echo "FAIL: plist not removed"; exit 1; fi
echo PASS
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `chmod +x test/schedule_test.sh && bash test/schedule_test.sh`
Expected: FAIL (schedule-sweep.sh does not exist yet).

- [ ] **Step 3: Write `schedule-sweep.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LA_DIR="${LAUNCH_AGENTS_DIR:-$HOME/Library/LaunchAgents}"
LABEL="com.engineering-persona.learn-sweep"
PLIST="$LA_DIR/$LABEL.plist"
REAL=0; [ -z "${LAUNCH_AGENTS_DIR:-}" ] && REAL=1

if [ "${1:-}" = "--remove" ]; then
  [ "$REAL" = 1 ] && [ -f "$PLIST" ] && launchctl unload "$PLIST" 2>/dev/null || true
  rm -f "$PLIST"
  echo "removed $PLIST"
  exit 0
fi

HOUR="${SWEEP_HOUR:-9}"
mkdir -p "$LA_DIR" "$HOME/.claude/engineering-persona"
cat > "$PLIST" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$REPO_DIR/run-sweep.sh</string>
  </array>
  <key>StartCalendarInterval</key>
  <dict><key>Hour</key><integer>$HOUR</integer><key>Minute</key><integer>0</integer></dict>
  <key>StandardOutPath</key><string>$HOME/.claude/engineering-persona/sweep.log</string>
  <key>StandardErrorPath</key><string>$HOME/.claude/engineering-persona/sweep.log</string>
</dict>
</plist>
PL
echo "installed $PLIST (daily at ${HOUR}:00)"

if [ "$REAL" = 1 ]; then
  launchctl unload "$PLIST" 2>/dev/null || true
  launchctl load "$PLIST" 2>/dev/null || echo "note: run 'launchctl load $PLIST' to activate"
fi
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `bash test/schedule_test.sh`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
chmod +x schedule-sweep.sh
git add schedule-sweep.sh test/schedule_test.sh
git commit -m "NO_JIRA add schedule-sweep.sh launchd installer with tests

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 5: Document the automation

**Files:**
- Modify: `README.md`
- Modify: `USAGE.md`

**Interfaces:**
- Consumes: all prior tasks.
- Produces: user-facing docs for the automated learning loop and its prerequisites.

- [ ] **Step 1: Add an "Automated learning" section to `README.md`**

Insert immediately BEFORE the `## Living documents` heading:

```markdown
## Automated learning

`learn-from-review` can run on a schedule. `./schedule-sweep.sh` installs a daily
launchd job that sweeps new eg-internal PR reviews, generalizes them into rules
(scrubbing anything internal-specific), and opens a gated PR on this repo for you
to review and merge. It never merges, never commits to `main`, and never posts to
the source PR. Remove it with `./schedule-sweep.sh --remove`. Requires a one-time
`gh auth login` for the Ashaba account. See [USAGE.md](USAGE.md).
```

- [ ] **Step 2: Add entries to `USAGE.md`**

Append these sections to the end of `USAGE.md`:

```markdown
## run-sweep.sh

Run the automated learning sweep once, now.

- Run: `./run-sweep.sh`
- Does: invokes Claude Code headless against the `learn-sweep` skill with a scoped
  tool allowlist; logs to `~/.claude/engineering-persona/sweep.log`.
- Requires: `gh` logged into the work account (reads eg-internal PRs) and the
  `Ashaba` account (opens the gate PR); the ash ssh key for pushing.
- Safe: only opens a PR; never merges, never commits to `main`, never posts to a
  source PR. Every rule passes `scrub-check.sh` first.

## schedule-sweep.sh

Install or remove the daily launchd job that runs the sweep.

- Run: `./schedule-sweep.sh` (install), `./schedule-sweep.sh --remove` (uninstall).
  Set `SWEEP_HOUR` to change the hour (default 9).
- Does: writes a launchd plist to `~/Library/LaunchAgents/` that runs
  `run-sweep.sh` daily.
- Requires: macOS. First-time setup: `gh auth login` for the Ashaba account.
- Safe: idempotent; `--remove` fully uninstalls.

## Prerequisites for automated learning

- `gh auth login` once for the `Ashaba` account (gh keeps both accounts).
- The sweep reads eg-internal reviews locally and only ever writes generalized,
  scrubbed rules to the personal repo, behind a PR you merge.
```

- [ ] **Step 3: Verify**

Run: `grep -q '^## Automated learning' README.md && grep -q '^## run-sweep.sh' USAGE.md && grep -q '^## schedule-sweep.sh' USAGE.md && ! grep -rn '—' README.md USAGE.md && echo OK`
Expected: prints `OK`.

- [ ] **Step 4: Commit**

```bash
git add README.md USAGE.md
git commit -m "NO_JIRA document automated learning sweep and prerequisites

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 6: End-to-end verification

**Files:**
- None created; verifies the increment.

**Interfaces:**
- Consumes: all prior tasks.

- [ ] **Step 1: Full shell test suite**

Run: `for t in test/*_test.sh; do echo "== $t"; bash "$t" || exit 1; done`
Expected: each prints `PASS`.

- [ ] **Step 2: Syntax-check all scripts**

Run: `for s in scrub-check.sh run-sweep.sh schedule-sweep.sh install.sh scaffold-repo.sh capture.sh; do bash -n "$s" && echo "$s ok"; done`
Expected: each prints `ok`.

- [ ] **Step 3: Scrub spot-check**

Run: `./scrub-check.sh "Money uses exact decimal types, never floats." && echo pass1; ./scrub-check.sh "bug in OrderService.java" && echo "should-not-print" || echo pass2`
Expected: prints `pass1` then `pass2` (the second input is rejected).

- [ ] **Step 4: No em-dashes in shipped prose**

Run: `! grep -rn '—' skills/learn-sweep README.md USAGE.md docs/superpowers/specs/2026-09-24-learn-sweep-automation-design.md && echo OK`
Expected: prints `OK`.

- [ ] **Step 5: Manual end-to-end (needs Ashaba gh auth; not automated here)**

Documented for the engineer to run once after `gh auth login` for Ashaba:
`./run-sweep.sh` against a short watermark, confirm a gate PR is opened containing
only generalized rules, then a second run is a no-op. This step is manual and is
not part of the automated suite.

## Notes for the implementer

- Do not run real `launchctl` in tests; the `LAUNCH_AGENTS_DIR` gate prevents it.
- Do not invoke `run-sweep.sh` in the suite; it calls the Claude CLI and hits
  GitHub. It is syntax-checked only.
- The scrub is intentionally conservative: when in doubt it rejects, and the skill
  drops rejected rules rather than writing them.
- If the ticket-id `\b` word boundary does not behave on this macOS grep (the
  Task 1 test will reveal it), switch that pattern to `[[:<:]]`/`[[:>:]]` or
  `(^| )[A-Z][A-Z0-9]+-[0-9]+( |$|[.,])` and re-run the test.
