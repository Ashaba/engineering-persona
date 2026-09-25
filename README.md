# Engineering persona

A portable, version-controlled engineering persona that any AI tool loads so it
writes code and reviews PRs to my standard. Two layers: personal principles that
travel with me, and team standards committed per repo.

## Install (any machine)

    git clone <this-repo> && cd ai-skills-and-agent && ./install.sh

This links `persona/` into `~/.claude/CLAUDE.md` and symlinks every skill under
`skills/` into `~/.claude/skills/`. Edits and `git pull` take effect immediately.
For Cursor and Windsurf, add `persona/beliefs.md` and `persona/voice.md` as user
rules (manual, one time).

If you move or re-clone the repo, re-run `./install.sh` to refresh the links.

## Layers

- `persona/` personal, global. `beliefs.md` and `voice.md`.
- `standards/` team, per repo. `engineering.md`, `review-checklist.md`, and
  `AGENTS.template.md`.
- `domains/` industry lenses, per repo. Reweight review criticality and add domain
  rules. Declared in a repo's `AGENTS.md` `## Domain` section.

## Daily use

- Before pushing, run the `pre-flight-review` skill to catch drift.
- After a review catches a missed pattern, run `learn-from-review` to turn it into a rule.
- Add a team layer to a work repo: `./scaffold-repo.sh <path-to-repo> [domain]` (for example `finance-trading`).
- Jot a new rule: `./capture.sh beliefs "the rule"` (targets: beliefs, voice, review).

See [USAGE.md](USAGE.md) for how to run each command and what it requires.

## Domains

A repo declares its industry in its `AGENTS.md` `## Domain` section
(`Domain: finance-trading`). When set, the persona judges matching concerns more
critically and applies domain rules. If unset, it infers the domain and confirms
before applying. Seeded domains live in `domains/`; add one by adding a file.
Updating a repo's inlined lens after the library changes is a manual edit; re-running `scaffold-repo.sh` skips an existing `AGENTS.md`.

## Living documents

Persona files grow over time. Quick notes land under each file's `## Inbox` via
`capture.sh`; curate them into rules when convenient.
