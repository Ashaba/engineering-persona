# Learn-Sweep Automation: Design

Date: 2026-09-24
Status: Approved (design), pending implementation plan
Owner: jashabahebwa
Builds on: docs/superpowers/specs/2026-09-24-engineering-persona-system-design.md and the learn-from-review skill

## Problem

The manual `learn-from-review` skill only fires when invoked. The engineer wants
the persona to keep learning without having to remember to run it: when a PR review
catches a pattern the persona missed, that lesson should be captured and gated for
approval automatically.

There is no local event when a reviewer comments on a GitHub PR, so automation
means polling on a schedule. The engineer's work PRs are Expedia-internal
(`eg-internal`); the persona repo is personal (`Ashaba/engineering-persona`). The
design must keep internal content on the machine and only ever land a generalized
rule in the personal repo, behind an approval gate.

## Goals

- A local scheduled sweep that, on a cadence (default daily), reads new review
  comments on the engineer's authored `eg-internal` PRs since a stored watermark.
- Generalize each actionable comment into a persona rule, with a hard scrub that
  strips or rejects anything internal-specific (code, URLs, repo or service names,
  ticket IDs).
- Dedup against existing persona rules; classify each rule into the right layer.
- Gate every learning behind a pull request on the persona repo: branch, commit,
  push, open PR. Nothing reaches `main` unattended.
- Run locally with existing credentials; internal review content never leaves the
  machine.
- Never post or reply on the source PR. Never auto-merge.

## Non-goals

- No cloud execution and no event-driven/instant trigger (polling only).
- No auto-merge of the gate PR; the engineer reviews and merges.
- No dashboards or metrics.
- Personal-repo review learning is out of v1 scope; the sweep targets `eg-internal`.

## Prerequisites

- `gh` logged into `github.com` as the work account (present) to read `eg-internal`
  PRs.
- `gh` logged into the `Ashaba` account (one-time `gh auth login`) to open the gate
  PR on the personal repo. gh supports multiple accounts per host.
- The ash ssh key for pushing the branch (present and working).
- A non-interactive Claude Code permission allowlist scoped to exactly the tools
  the sweep uses (git, gh, read/write within the persona repo), so the headless run
  does not hang on prompts.
- A launchd job (macOS) to run the sweep on a cadence.

## Architecture

A scheduled local run of Claude Code executes a `learn-sweep` skill that does the
whole flow and opens a gated PR.

### Components

- `skills/learn-sweep/SKILL.md` - the sweep logic (fetch, generalize, scrub, dedup,
  classify, branch, commit, push, open PR, update watermark). Reuses the
  classification and wording rules from `learn-from-review`.
- `run-sweep.sh` - a thin wrapper that invokes Claude Code headless against the
  sweep skill, from the persona repo directory, and appends output to a log.
- `schedule-sweep.sh` - installs or removes a launchd job that runs `run-sweep.sh`
  on a cadence. Idempotent; `--remove` to uninstall.
- Watermark state at `~/.claude/engineering-persona/last-sweep` (an ISO timestamp),
  outside the repo so it is machine-local and never committed.
- Scrub guard: a small `scrub-check.sh` that, given a proposed rule line, exits
  non-zero if it contains internal-specific markers (a URL, a code span/backtick, a
  `LETTERS-DIGITS` ticket pattern, or a path). The skill runs each proposed rule
  through it and drops any that fail, logging the drop.

### Flow

1. Read the watermark (default: 7 days ago if absent).
2. `gh` (work account) lists the engineer's authored `eg-internal` PRs with review
   activity since the watermark; collect review comment bodies.
3. For each actionable comment, state the missed pattern in one generalized
   sentence. Run it through the scrub; drop and log anything that fails.
4. Classify into `beliefs.md`, `voice.md`, `standards/engineering.md`,
   `standards/review-checklist.md`, or `domains/<domain>.md`. Dedup against the
   current file contents.
5. If any new rules survive: create branch `NO_JIRA_learned-<date>`, append the
   rules to their target files, commit, push (ash key), and open a PR (Ashaba gh)
   titled `NO_JIRA learned rules (<date>)`. The PR body lists each rule, its target
   layer, and a note that it was auto-derived and generalized. No internal
   specifics appear anywhere.
6. Update the watermark to now. Exit cleanly with no writes if nothing survived.

### Data boundary

Internal content is read locally and only ever summarized into a generalized rule.
The scrub guard plus the PR gate (the engineer sees every proposed rule before
merge) are the two controls. The sweep never writes internal specifics to the
personal repo and never sends them off the machine.

## Validation

- Scrub: `scrub-check.sh` has a bash test feeding internal-specific sample lines
  (a URL, a backtick code span, `PROJ-1234`, a file path) and asserting each is
  rejected, plus generic lines asserted to pass.
- Skill: validated with the skill-validator; frontmatter within limits.
- schedule-sweep.sh: a test installs the launchd plist into a temp `LaunchAgents`
  dir and asserts it is written, then `--remove` deletes it (no real system load).
- End-to-end (manual, needs Ashaba gh auth): run `run-sweep.sh` once against a
  short lookback; confirm it opens a gate PR containing only generalized rules, and
  that a second run with an advanced watermark is a no-op.

## Risks and mitigations

- Internal content leaking into the personal repo. Mitigation: conservative scrub
  guard, generalized wording only, and the PR gate where every rule is reviewed
  before merge; the run is local.
- Overbroad headless permissions. Mitigation: the allowlist is scoped to git, gh,
  and file writes within the persona repo; no destructive commands; runs in the
  repo directory.
- Duplicate or noisy rules. Mitigation: dedup against existing file contents; one
  rule per pattern; low default cadence (daily).
- Partial run when offline or unauthenticated. Mitigation: the sweep checks auth
  and network first and exits cleanly, leaving the watermark unchanged.
- Wrong gh account used (work vs personal). Mitigation: the sweep names the account
  explicitly for reads (work) and for the PR (Ashaba); it never crosses them.
- launchd running unattended. Mitigation: it only ever opens a PR (never merges,
  never touches `main`), so the worst case is an unwanted PR the engineer closes.

## Out of scope

Cloud scheduling, event-driven triggers, auto-merge, personal-repo review learning,
and non-macOS schedulers (cron/systemd) beyond a documented note.
