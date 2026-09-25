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

If you move or re-clone the repo, re-run `./install.sh` to refresh the links.

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
