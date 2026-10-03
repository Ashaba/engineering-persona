# Engineering persona

A portable, version-controlled engineering persona that any AI tool loads so it
writes code and reviews PRs to my standard. Two layers: personal principles that
travel with me, and team standards committed per repo.

## Install (any machine)

    git clone <this-repo> && cd engineering-persona && ./install.sh

One run wires the persona into every supported tool. Everything is a symlink or
an import, so edits and `git pull` take effect immediately.

| Tool | Persona (always on) | Skills |
| --- | --- | --- |
| Claude Code | managed `@`-import block in `~/.claude/CLAUDE.md` | `~/.claude/skills/` |
| Devin CLI | `~/.devin/rules/engineering-persona-{beliefs,voice}.md` | `~/.config/devin/skills/` |
| Cursor, Windsurf | add `persona/beliefs.md` and `persona/voice.md` as user rules (manual, one time) | not installed |

Devin does not expand `@`-imports, so it gets the persona files directly as
rules. The `trigger: always_on` front matter at the top of each persona file is
what makes Devin load them in every session; keep it there. To check, run
`devin rules list` and look for both rules marked `always-on`.

If you move or re-clone the repo, re-run `./install.sh` to refresh the links.

## Layers

- `persona/` personal, global. `beliefs.md` and `voice.md`.
- `standards/` team, per repo. `engineering.md`, `review-checklist.md`, and
  `AGENTS.template.md`.
- `domains/` industry lenses, per repo. Reweight review criticality and add domain
  rules. Declared in a repo's `AGENTS.md` `## Domain` section.

## Daily use

Skills work the same in Claude Code and Devin: type `/<skill-name>`, or just
describe the task and the agent picks the skill up.

- Before pushing, run `/pre-flight-review` to catch drift.
- After a review catches a missed pattern, run `/learn-from-review` to turn it into a rule.
- Add a team layer to a work repo: `./scaffold-repo.sh <path-to-repo> [domain]` (for example `finance-trading`).
- Jot a new rule: `./capture.sh beliefs "the rule"` (targets: beliefs, voice, review).

See [USAGE.md](USAGE.md) for how to run each command and what it requires.

## Domains

A repo declares its industry in its `AGENTS.md` `## Domain` section
(`Domain: finance-trading`). When set, the persona judges matching concerns more
critically and applies domain rules. If unset, it infers the domain and confirms
before applying. Seeded domains live in `domains/`; add one by adding a file.
Updating a repo's inlined lens after the library changes is a manual edit; re-running `scaffold-repo.sh` skips an existing `AGENTS.md`.

## Automated learning

`learn-from-review` can run on a schedule. `./schedule-sweep.sh` installs a daily
launchd job that sweeps new eg-internal PR reviews, generalizes them into rules
(scrubbing anything internal-specific), and opens a gated PR on this repo for you
to review and merge. It never merges, never commits to `main`, and never posts to
the source PR. Remove it with `./schedule-sweep.sh --remove`. It runs headless
in whichever agent is installed (Devin first, then Claude Code); set
`SWEEP_AGENT=devin` or `SWEEP_AGENT=claude` to pin one.
Requires a one-time `gh auth login` for the Ashaba account. See [USAGE.md](USAGE.md).

## Living documents

Persona files grow over time. Quick notes land under each file's `## Inbox` via
`capture.sh`; curate them into rules when convenient.
