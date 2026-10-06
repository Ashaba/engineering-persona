# Usage and requirements

Run scripts from the persona repo root. Personal-layer edits take effect
immediately, since `install.sh` uses symlinks and CLAUDE.md imports.

## install.sh

Wire the personal layer and skills into this machine, for Claude Code and Devin.

- Run: `./install.sh`
- Adds for Claude Code: a managed block in `~/.claude/CLAUDE.md` importing
  `persona/beliefs.md` and `persona/voice.md`, plus a symlink in `~/.claude/skills/`
  for every skill under `skills/`.
- Adds for Devin: symlinks `~/.devin/rules/engineering-persona-beliefs.md` and
  `engineering-persona-voice.md` to the persona files, plus a symlink in
  `~/.config/devin/skills/` for every skill. Verify with `devin rules list` (both
  `always-on`) and `devin skills list`.
- Requires: nothing beyond the tools you use; a tool that is not installed just
  ignores its files. Re-run after moving or re-cloning the repo. For Cursor and
  Windsurf, add `persona/beliefs.md` and `persona/voice.md` as user rules once,
  manually.
- Safe: preserves existing `~/.claude/CLAUDE.md` content; idempotent.
- Keep the `trigger: always_on` front matter at the top of each persona file.
  Without it Devin treats the rule as manual and does not load it.

## scaffold-repo.sh

Plant the team layer, and optionally a domain lens, into a work repo.

- Run: `./scaffold-repo.sh <path-to-repo> [domain]`
  Domains: `finance-trading`, `travel`, `agriculture`, or omit for `unset`.
- Adds: `<repo>/AGENTS.md` (standards, review gates, and the domain lens if given)
  and `<repo>/.github/copilot-instructions.md` (a shim pointing at AGENTS.md).
- Requires: the target path is an existing directory; a named domain matches a file
  in `domains/`.
- Safe: never overwrites an existing `AGENTS.md` or copilot shim; does not commit.
  Review and commit the files yourself.

## capture.sh

Jot a quick note into a persona file's Inbox for later curation.

- Run: `./capture.sh <beliefs|voice|review> "the note"`
- Adds: a timestamped note under the file's `## Inbox`.
- Requires: nothing.

## pre-flight-review (skill)

Review your working diff against the persona before you push.

- Run: `/pre-flight-review` in Claude Code or Devin on a branch with changes.
- Does: resolves the domain, applies the review gates and your beliefs, confirms
  checks pass, and reports drift with `file:line`.
- Requires: the skill installed (`install.sh`). Uses the tool's built-in code
  review if it has one (Claude Code `/code-review`); otherwise the agent does that
  pass itself.
- Safe: reports only. Never posts or submits a review.
- Enforced in Devin: `install.sh` registers a user-level `PreToolUse` hook that
  blocks `git push` and `gh pr create` until the review has run. The skill
  records it by touching `.git/pre-flight-review/<commit sha>`, so a later
  commit or an amend needs reviewing again. Not yet wired for Claude Code.
- To bypass for one push, create that file yourself. It is deliberately easy;
  the hook exists to stop the review being forgotten, not to stop you.

## learn-from-review (skill)

Turn a PR review comment that caught a missed pattern into a persona rule.

- Run: `/learn-from-review` in Claude Code or Devin with a PR URL, or paste the
  review comments.
- Does: extracts the missed pattern, classifies its layer, proposes the exact rule
  and a diff, and on your approval commits it to the persona repo.
- Requires: to read a PR by URL, a connected GitHub MCP server or an authenticated
  `gh` CLI for that host (the enterprise tool for eg-internal PRs, the github.com
  tool for personal repos). No access needed if you paste the comments.
- Safe: never posts to the PR; never pushes.

## run-sweep.sh

Run the automated learning sweep once, now.

- Run: `./run-sweep.sh`. It uses `devin` if installed, otherwise `claude`. Pin
  one with `SWEEP_AGENT=devin` or `SWEEP_AGENT=claude`.
- Does: invokes the agent headless against the `learn-sweep` skill with a scoped
  tool allowlist; logs to `~/.local/state/engineering-persona/sweep.log`. The
  watermark lives next to it in `last-sweep`.
- Devin specifics: runs `devin -p` with a temporary `--config` holding only the
  allowlist and denylist (in print mode any call that is not allowlisted is
  rejected), and `--respect-workspace-trust false`, since print mode cannot show
  the trust prompt. Merging, reviewing or commenting on PRs, `gh api`, force-pushes
  and pushing to `main` are denied outright.
- Requires: `gh` logged into the work account (reads eg-internal PRs) and the
  `Ashaba` account (opens the gate PR); the ash ssh key for pushing; the chosen
  agent logged in (`devin auth login` or `claude login`).
- Safe: only opens a PR; never merges, never commits to `main`, never posts to a
  source PR. Every rule passes `scrub-check.sh` first.

## schedule-sweep.sh

Install or remove the daily launchd job that runs the sweep.

- Run: `./schedule-sweep.sh` (install), `./schedule-sweep.sh --remove` (uninstall).
  Set `SWEEP_HOUR` to change the hour (default 9). Leave `SWEEP_AGENT` unset to
  pick the installed agent at each run, or set it to pin one. Re-run to change
  either.
- Does: writes a launchd plist to `~/Library/LaunchAgents/` that runs
  `run-sweep.sh` daily.
- Requires: macOS. First-time setup: `gh auth login` for the Ashaba account.
- Safe: idempotent; `--remove` fully uninstalls.

## Prerequisites for automated learning

- `gh auth login` once for the `Ashaba` account (gh keeps both accounts).
- The sweep reads eg-internal reviews locally and only ever writes generalized,
  scrubbed rules to the personal repo, behind a PR you merge.
