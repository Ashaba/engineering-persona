# Engineering Persona System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a portable, version-controlled engineering persona that any AI tool loads so it does code and PR-review work to the engineer's standard, plus a pre-flight review skill that catches recurring drift before a human reviewer does.

**Architecture:** Two hand-authored layers in one repo. Layer 1 (personal: `persona/`) installs globally on the machine; Layer 2 (team: `standards/` plus a scaffolded per-repo `AGENTS.md`) is committed into work repos. No build step: `install.sh` wires the repo into `~/.claude` via Claude Code `@`-imports and a symlinked skill, so edits and `git pull` propagate instantly. A `pre-flight-review` skill reuses the built-in `/code-review` and layers the persona gates on top.

**Tech Stack:** Bash (`#!/usr/bin/env bash`), Markdown, Claude Code skill format (Agent Skills spec), git.

**Spec:** `docs/superpowers/specs/2026-09-24-engineering-persona-system-design.md`

## Global Constraints

- No build/compilation toolchain; all deliverables are hand-authored (approach #1).
- v1 scope is code + PR review only. No docs/message/support generation, no web-chat.
- Prose contains no em-dashes and no emojis (matches `voice.md`).
- Persona files are living documents: `beliefs.md`, `voice.md`, and `review-checklist.md` each end with a `## Inbox` section.
- Instant propagation: link the repo into tools (symlink or `@`-import), never copy.
- Shell scripts must be idempotent and must never clobber a user's existing files.
- Work happens on branch `NO_JIRA_engineering-persona-system` (already checked out); base is `main`. Commit after every task.

## Review Focus

- `install.sh` run when `~/.claude/CLAUDE.md` already holds the user's own content: it must preserve that content and manage only its own marked block. (Task 5)
- `install.sh` run a second time: no duplicated import block or dangling symlink; fully idempotent. (Task 5)
- `capture.sh` run against a file that has no `## Inbox` heading yet: it must create the heading exactly once across repeated calls. (Task 4)
- `scaffold-repo.sh` run against a repo that already has `AGENTS.md` or `.github/copilot-instructions.md`: it must skip, never overwrite. (Task 6)
- `capture.sh` given a note with shell metacharacters or an empty note: it must append the text literally and reject an empty note. (Task 4)

---

### Task 1: Personal layer content (`persona/`)

**Files:**
- Create: `persona/beliefs.md`
- Create: `persona/voice.md`

**Interfaces:**
- Consumes: nothing.
- Produces: `persona/beliefs.md` and `persona/voice.md`, each ending with a `## Inbox` heading. Referenced later by `install.sh` (`@`-imports) and the skill.

- [ ] **Step 1: Write `persona/beliefs.md`**

```markdown
# Beliefs

My durable engineering principles. Applied to any code or review, in any language.

- Self-documenting code. Comment only non-obvious intent, never restate code.
- Simplicity and readability first (a Zen-of-Python sensibility): simple over
  complex, readable over clever, explicit over implicit, flat over nested, prefer
  the one obvious way, and never let errors pass silently.
- Use the current recommended practices and idioms of whatever language or
  technology is in play (for example Java records instead of hand-written POJOs,
  modern stdlib, pattern matching). Keep code contemporary, not dated.
- Challenge the ticket. Think about the whole codebase and the impact of a change
  before executing what was literally asked.
- Make minor improvements only when related to the current task. Refactoring
  expands scope and is avoided unless asked.
- Remove redundancy. No null checks for values that cannot be null.
- Customer-first. No breaking changes. Design for extensibility and forward
  compatibility, since this software is consumed by other products.
- Prefer standard patterns. Keep code clean.
- Code is the source of truth. Verify claims from Confluence, READMEs, Jira
  tickets, or another service's docs against the actual code or schema before
  acting. Confirm a contract before integrating rather than assuming.
- Verify before asserting. Do not push changes or call work done until all checks
  pass (build, tests, lint, CI). Rely on real output, not assumptions.

## Inbox

<!-- Quick jots land here via capture.sh; curate into rules above when convenient. -->
```

- [ ] **Step 2: Write `persona/voice.md`**

```markdown
# Voice

How I write and how I give feedback. Applied to PR descriptions, comments, and
review feedback.

- Concise, human, straightforward prose.
- No em-dashes.
- No emojis in PR titles or descriptions.
- Review feedback is kind and Socratic. Nudge the author toward the concern and
  let them decide ("what do you think about...?", "would it be simpler to...?")
  rather than issuing directives.
- Vary phrasing and keep it natural. Avoid a formulaic template so feedback reads
  as a thoughtful human, not a predictable bot.
- Comment only at high confidence. Keep each comment specific and actionable, not
  observational.

## Inbox

<!-- Quick jots land here via capture.sh; curate into rules above when convenient. -->
```

- [ ] **Step 3: Verify content**

Run: `grep -c '^## Inbox' persona/beliefs.md persona/voice.md && ! grep -n '—' persona/beliefs.md persona/voice.md && echo OK`
Expected: each file reports `1`, no em-dash matches, prints `OK`.

- [ ] **Step 4: Commit**

```bash
git add persona/beliefs.md persona/voice.md
git commit -m "NO_JIRA add personal persona layer (beliefs, voice)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 2: Team layer content (`standards/`)

**Files:**
- Create: `standards/engineering.md`
- Create: `standards/review-checklist.md`
- Create: `standards/AGENTS.template.md`

**Interfaces:**
- Consumes: nothing.
- Produces: `standards/review-checklist.md` (gates, ends with `## Inbox`), read by the skill; `standards/engineering.md`, read by the skill; `standards/AGENTS.template.md`, a self-contained per-repo spine copied by `scaffold-repo.sh`.

- [ ] **Step 1: Write `standards/engineering.md`**

```markdown
# Engineering standards

Team and industry standards. Kept generic so they age well; tailor specifics per repo.

- Reuse platform and framework features before building new (platform APM over
  custom metrics; framework exception handling; standard pagination types; existing
  error mappers and enums).
- DTOs are required-by-default. Validate at the controller/bean-validation
  boundary, not defensively in services.
- Prefer domain/application error codes over raw HTTP. Never leak internal or
  downstream names to clients. Preserve upstream status codes via shared mappers.
- Keep generated types (for example GraphQL) committed and in sync with the schema.
- Match the established sibling implementation for tagging, reporting, and auth.
- Do not touch shared handlers or config unrelated to the change. Keep PRs single
  purpose.
- Coverage must not regress.
- Follow the repo PR template and the branch/commit conventions.
```

- [ ] **Step 2: Write `standards/review-checklist.md`**

```markdown
# Review gates

Each gate is a challenge to raise against a diff. Findings cite file:line.

- What is the second consumer of this abstraction? If none, inline it.
- Does the framework, platform, or language already do this? If yes, use it.
- Does this duplicate existing code or a type? If yes, reuse the original.
- Can this field ever actually be null? If not, make it required, and validate at
  the boundary rather than defensively downstream.
- Is any of this unrelated to the task? If yes, remove or defer it.
- Does this swallow an error, leak an internal detail, or drop an upstream status?
- Does this change behavior for other callers, or let a contract or generated
  artifact drift from its source?
- Is this the current idiom for the language and tech, or a dated pattern?
- Was any assumption taken from a doc, README, or ticket without confirming it
  against the code or schema?

## Inbox

<!-- Quick jots land here via capture.sh; curate into gates above when convenient. -->
```

- [ ] **Step 3: Write `standards/AGENTS.template.md`** (self-contained; committed into other repos, so it inlines the standards and gates rather than referencing this repo)

```markdown
# Engineering standards for this repo

Contributors apply their personal engineering principles through their own global
setup. The standards below are team-level. Tailor the repo-specific section.

## Working here

<!-- Fill per repo: build command, test command, lint command, CI expectations. -->

## Standards

- Reuse platform and framework features before building new.
- DTOs required-by-default; validate at the boundary, not defensively in services.
- Domain/application error codes over raw HTTP; never leak internal names; preserve
  upstream status codes via shared mappers.
- Keep generated types committed and in sync with the schema.
- Match the established sibling implementation for tagging, reporting, and auth.
- Keep PRs single purpose; do not touch unrelated shared handlers or config.
- Coverage must not regress.
- No emojis in PR titles or descriptions; concise, human prose.

## Review gates

- Second consumer of this abstraction? If none, inline it.
- Does the framework, platform, or language already do this? Use it.
- Duplicates existing code or a type? Reuse the original.
- A field that can never be null but is optional? Make it required; validate at the
  boundary.
- Anything unrelated to the task? Remove or defer it.
- Swallows an error, leaks an internal detail, or drops an upstream status?
- Changes behavior for other callers, or lets a contract or generated artifact
  drift from its source?
- Dated pattern where a current idiom exists?
- An assumption taken from a doc or ticket without confirming against the code?
```

- [ ] **Step 4: Verify content**

Run: `grep -c '^## Inbox' standards/review-checklist.md && ! grep -rn '—' standards/ && echo OK`
Expected: reports `1`, no em-dash matches, prints `OK`.

- [ ] **Step 5: Commit**

```bash
git add standards/engineering.md standards/review-checklist.md standards/AGENTS.template.md
git commit -m "NO_JIRA add team standards layer and per-repo AGENTS template

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 3: Pre-flight review skill

**Files:**
- Create: `skills/pre-flight-review/SKILL.md`

**Interfaces:**
- Consumes: `persona/beliefs.md`, `persona/voice.md`, `standards/review-checklist.md` by relative path `../../` (the skill is symlinked from the repo, so relative paths resolve back into the repo).
- Produces: an installable skill directory `skills/pre-flight-review/` that `install.sh` symlinks into `~/.claude/skills/`.

- [ ] **Step 1: Write `skills/pre-flight-review/SKILL.md`**

```markdown
---
name: pre-flight-review
description: Use before pushing a branch or opening a PR. Reviews the working diff against the engineer's beliefs, team standards, and the recurring anti-pattern gates, confirms all checks pass, and reports drift with file:line so it is fixed before a human reviewer sees it.
---

# Pre-flight Review

Run before you push or open a PR. Goal: catch the recurring drift a human reviewer
would otherwise catch, and fix it first.

## Load the persona (relative to this skill)

- Gates: `../../standards/review-checklist.md`
- Beliefs: `../../persona/beliefs.md`
- Voice for any comments: `../../persona/voice.md`

Read those three files first. They are the source of truth and change over time.

## Steps

1. Determine the base branch (`main` or `master`) and get the diff: `git diff <base>...HEAD`.
2. Run the built-in `/code-review` on the current diff for correctness and cleanup findings.
3. Apply every gate from the review checklist to each changed file. For each hit,
   report `file:line`, which gate fired, and a one-line fix.
4. Confirm checks pass: build, tests, lint, and CI are green. Do not report
   ready-to-push until they are; if you cannot run them, say so explicitly.
5. Summarize findings most-severe first, or state plainly that the diff is clean.

## Writing any comments

Follow `voice.md`: kind and Socratic, invite the author to decide, vary phrasing,
no em-dashes, no emojis, concise and specific.
```

- [ ] **Step 2: Validate the skill**

Invoke the `platform-skills:skill-validator` skill against `skills/pre-flight-review/SKILL.md`.
Expected: PASS (valid frontmatter, `name` <= 64 chars, `description` <= 1024 chars).

- [ ] **Step 3: Commit**

```bash
git add skills/pre-flight-review/SKILL.md
git commit -m "NO_JIRA add pre-flight-review skill

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 4: `capture.sh` (Inbox appender)

**Files:**
- Create: `capture.sh`
- Test: `test/capture_test.sh`

**Interfaces:**
- Consumes: `PERSONA_REPO_DIR` env override (defaults to the script's own directory), for testability.
- Produces: CLI `capture.sh <beliefs|voice|review> <note...>` that appends `- [YYYY-MM-DD] note` under `## Inbox` in the mapped file, creating the heading if absent.

- [ ] **Step 1: Write the failing test `test/capture_test.sh`**

```bash
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `chmod +x test/capture_test.sh && bash test/capture_test.sh`
Expected: FAIL (capture.sh does not exist yet).

- [ ] **Step 3: Write `capture.sh`**

```bash
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash test/capture_test.sh`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
chmod +x capture.sh
git add capture.sh test/capture_test.sh
git commit -m "NO_JIRA add capture.sh Inbox appender with tests

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 5: `install.sh` (wire persona into the machine)

**Files:**
- Create: `install.sh`
- Test: `test/install_test.sh`

**Interfaces:**
- Consumes: `persona/beliefs.md`, `persona/voice.md`, `skills/pre-flight-review/` (from Tasks 1 and 3); `CLAUDE_HOME` env override (defaults to `$HOME/.claude`) for testability.
- Produces: a managed block in `$CLAUDE_HOME/CLAUDE.md` importing the persona files, and a symlink `$CLAUDE_HOME/skills/pre-flight-review`.

- [ ] **Step 1: Write the failing test `test/install_test.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
export CLAUDE_HOME="$tmp/.claude"
mkdir -p "$CLAUDE_HOME"
printf '# my notes\nkeep me\n' > "$CLAUDE_HOME/CLAUDE.md"

"$here/install.sh" >/dev/null
grep -q 'keep me' "$CLAUDE_HOME/CLAUDE.md" || { echo "FAIL: clobbered user content"; exit 1; }
grep -q "@$here/persona/beliefs.md" "$CLAUDE_HOME/CLAUDE.md" || { echo "FAIL: beliefs import missing"; exit 1; }
grep -q "@$here/persona/voice.md" "$CLAUDE_HOME/CLAUDE.md" || { echo "FAIL: voice import missing"; exit 1; }
[ -L "$CLAUDE_HOME/skills/pre-flight-review" ] || { echo "FAIL: skill not symlinked"; exit 1; }

# idempotent: second run keeps exactly one managed block
"$here/install.sh" >/dev/null
[ "$(grep -c 'engineering-persona:begin' "$CLAUDE_HOME/CLAUDE.md")" -eq 1 ] || { echo "FAIL: duplicate managed block"; exit 1; }
echo PASS
```

- [ ] **Step 2: Run test to verify it fails**

Run: `chmod +x test/install_test.sh && bash test/install_test.sh`
Expected: FAIL (install.sh does not exist yet).

- [ ] **Step 3: Write `install.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_HOME:-$HOME/.claude}"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
SKILLS_DIR="$CLAUDE_DIR/skills"

mkdir -p "$CLAUDE_DIR" "$SKILLS_DIR"

MARK_BEGIN="<!-- engineering-persona:begin -->"
MARK_END="<!-- engineering-persona:end -->"

# Rebuild the managed block, preserving any existing user content.
if [ -f "$CLAUDE_MD" ]; then
  tmp="$(mktemp)"
  awk -v b="$MARK_BEGIN" -v e="$MARK_END" '
    $0==b {skip=1} skip && $0==e {skip=0; next} !skip {print}
  ' "$CLAUDE_MD" > "$tmp"
  mv "$tmp" "$CLAUDE_MD"
else
  : > "$CLAUDE_MD"
fi

{
  printf '%s\n' "$MARK_BEGIN"
  printf '@%s/persona/beliefs.md\n' "$REPO_DIR"
  printf '@%s/persona/voice.md\n' "$REPO_DIR"
  printf '%s\n' "$MARK_END"
} >> "$CLAUDE_MD"
echo "linked persona into $CLAUDE_MD"

ln -sfn "$REPO_DIR/skills/pre-flight-review" "$SKILLS_DIR/pre-flight-review"
echo "linked skill into $SKILLS_DIR/pre-flight-review"

echo "note: for Cursor/Windsurf, add these as user rules (best-effort, manual):"
echo "  $REPO_DIR/persona/beliefs.md"
echo "  $REPO_DIR/persona/voice.md"
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash test/install_test.sh`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
chmod +x install.sh
git add install.sh test/install_test.sh
git commit -m "NO_JIRA add install.sh with safe idempotent wiring and tests

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 6: `scaffold-repo.sh` (inject team layer into a repo)

**Files:**
- Create: `scaffold-repo.sh`
- Test: `test/scaffold_test.sh`

**Interfaces:**
- Consumes: `standards/AGENTS.template.md` (from Task 2).
- Produces: CLI `scaffold-repo.sh <path-to-repo>` that creates `<repo>/AGENTS.md` from the template and `<repo>/.github/copilot-instructions.md` shim, skipping either if it already exists.

- [ ] **Step 1: Write the failing test `test/scaffold_test.sh`**

```bash
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
echo PASS
```

- [ ] **Step 2: Run test to verify it fails**

Run: `chmod +x test/scaffold_test.sh && bash test/scaffold_test.sh`
Expected: FAIL (scaffold-repo.sh does not exist yet).

- [ ] **Step 3: Write `scaffold-repo.sh`**

```bash
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash test/scaffold_test.sh`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
chmod +x scaffold-repo.sh
git add scaffold-repo.sh test/scaffold_test.sh
git commit -m "NO_JIRA add scaffold-repo.sh with no-clobber guard and tests

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 7: README, evals, and stub cleanup

**Files:**
- Create: `README.md`
- Create: `evals/README.md`
- Create: `evals/01-add-endpoint.md`
- Create: `evals/02-integrate-service.md`
- Delete: `ashabahebwa-as-a-senior-software-engineer.md` (superseded by `persona/beliefs.md`; it is untracked, so remove with `rm`)

**Interfaces:**
- Consumes: everything built in Tasks 1 to 6 (for documentation).
- Produces: user-facing docs and generic regression scenarios.

- [ ] **Step 1: Write `README.md`**

```markdown
# Engineering persona

A portable, version-controlled engineering persona that any AI tool loads so it
writes code and reviews PRs to my standard. Two layers: personal principles that
travel with me, and team standards committed per repo.

## Install (any machine)

    git clone <this-repo> && cd ai-skills-and-agent && ./install.sh

This links `persona/` into `~/.claude/CLAUDE.md` and symlinks the
`pre-flight-review` skill into `~/.claude/skills/`. Edits and `git pull` take
effect immediately. For Cursor and Windsurf, add `persona/beliefs.md` and
`persona/voice.md` as user rules (manual, one time).

## Layers

- `persona/` personal, global. `beliefs.md` and `voice.md`.
- `standards/` team, per repo. `engineering.md`, `review-checklist.md`, and
  `AGENTS.template.md`.

## Daily use

- Before pushing, run the `pre-flight-review` skill to catch drift.
- Add a team layer to a work repo: `./scaffold-repo.sh <path-to-repo>`.
- Jot a new rule: `./capture.sh beliefs "the rule"` (targets: beliefs, voice, review).

## Living documents

Persona files grow over time. Quick notes land under each file's `## Inbox` via
`capture.sh`; curate them into rules when convenient.
```

- [ ] **Step 2: Write `evals/README.md`**

```markdown
# Evals

Generic task scenarios that previously triggered the drift signature. Run a
scenario by giving its task to an AI with the persona active, then check that none
of the listed anti-patterns appear. Manual check; no framework.
```

- [ ] **Step 3: Write `evals/01-add-endpoint.md`**

```markdown
# Scenario: add a write endpoint

Task: add an endpoint that accepts a request body and persists it, following the
repo's existing patterns.

Must not produce:
- Request fields typed as nullable/optional when they are always required.
- Validation re-done in the service that belongs at the request boundary.
- A new bespoke error-response abstraction where the framework's exists.
- Custom metrics where platform APM already covers it.
- Changes to shared handlers or config unrelated to the endpoint.
```

- [ ] **Step 4: Write `evals/02-integrate-service.md`**

```markdown
# Scenario: integrate another service

Task: call a downstream service and map its response into this API.

Must not produce:
- Assumptions about the downstream schema taken from a README or ticket without
  confirming against the actual contract.
- A catch-all that collapses distinct downstream errors and drops status codes.
- Internal or downstream service names leaked to the client.
- A new mapper duplicating an existing shared one.
- An auth or reporting path that diverges from the established sibling.
```

- [ ] **Step 5: Remove the superseded stub and verify tree**

Run:
```bash
rm -f ashabahebwa-as-a-senior-software-engineer.md
ls persona standards skills evals && test ! -e ashabahebwa-as-a-senior-software-engineer.md && echo OK
```
Expected: directory listings shown, prints `OK`.

- [ ] **Step 6: Commit**

```bash
git add README.md evals/
git commit -m "NO_JIRA add README, generic eval scenarios, remove stub

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 8: End-to-end verification and remote

**Files:**
- None created; this task verifies the whole system and records the push step.

**Interfaces:**
- Consumes: all prior tasks.
- Produces: a green full-suite run and a pushed branch (push is the user's authorized action).

- [ ] **Step 1: Run the whole shell test suite**

Run: `for t in test/*_test.sh; do echo "== $t"; bash "$t" || exit 1; done`
Expected: each prints `PASS`.

- [ ] **Step 2: Dry-run install against a throwaway HOME**

Run:
```bash
tmp="$(mktemp -d)"; CLAUDE_HOME="$tmp/.claude" ./install.sh
cat "$tmp/.claude/CLAUDE.md"; ls -l "$tmp/.claude/skills"; rm -rf "$tmp"
```
Expected: CLAUDE.md shows the two `@`-imports inside the managed block; `skills/pre-flight-review` is a symlink into this repo.

- [ ] **Step 3: Confirm no em-dashes or emojis in shipped prose**

Run: `! grep -rn '—' persona standards README.md evals && echo OK`
Expected: prints `OK`.

- [ ] **Step 4: Create the remote and push (user-authorized)**

Confirm with the user first. Then, with a GitHub repo created:
```bash
git remote add origin <git-url>
git push -u origin main
git push -u origin NO_JIRA_engineering-persona-system
```
Expected: both refs pushed. Open a PR from the branch into `main` if desired.

---

## Notes for the implementer

- Run every shell script test with `bash test/<name>_test.sh` from the repo root.
- Scripts use `CLAUDE_HOME` and `PERSONA_REPO_DIR` env overrides only for tests; normal use needs neither.
- `install.sh` uses Claude Code `@`-imports (not a literal symlink of `CLAUDE.md`) because the global memory is composed from two files; this still gives instant propagation since the imports point at live repo files.
