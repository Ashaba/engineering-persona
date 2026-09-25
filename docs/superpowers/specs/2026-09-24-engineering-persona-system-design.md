# Engineering Persona System: Design

Date: 2026-09-24
Status: Approved (design), pending implementation plan
Owner: jashabahebwa

## Problem

A senior engineer's daily work (code, PR review, docs, messages) is increasingly
done by AI across several tools. The AI produces work that repeatedly drifts from
the engineer's own beliefs and the team's standards, so a human reviewer spends
rounds restating the same objections. We want a portable, version-controlled
"engineering persona" that any AI surface can load so it works to the engineer's
standard without re-explanation, and an active check that catches drift before a
PR reaches a human reviewer.

The drift is not random. Across AI-authored work the same anti-patterns recur, and
in many cases the engineer's own tool instructions already forbid them. That shows
passive instructions alone are not enough; the missing piece is enforcement at
review time.

### Recurring anti-patterns (the drift signature)

1. Over-engineering or needless abstraction with no second consumer.
2. Reinventing platform, framework, or language features instead of reusing them.
3. Duplicating code or types instead of reusing what already exists (DRY).
4. Unnecessary nullability or optionality, and defensive re-validation away from
   the boundary.
5. Scope creep: changes unrelated to the task at hand.
6. Swallowing errors, leaking internal details, or dropping upstream status and
   context.
7. Breaking shared or consumer-facing behavior, and letting contracts or generated
   artifacts drift from their source.

Format weak spots that also recur: emojis in PR titles or descriptions, and
verbose, em-dash-heavy prose. Branch, commit, and ticket hygiene are typically
fine and are documented but not a focus.

## Goals (v1)

- Encode the engineer's persona in two layers: **personal** (durable beliefs +
  voice, travels with the person) and **team/industry standards** (shared, per
  repo).
- Deliver the persona to Claude Code, GitHub Copilot, Cursor/Windsurf, and Devin
  in each tool's native format from a single canonical source, with minimal
  duplication ("generic").
- Provide an active **pre-flight review** that runs before push and flags the
  recurring anti-patterns with `file:line`.
- Be portable: clone the source repo on any machine (work or personal) and wire it
  in with one command.
- Scope v1 to **code + PR review**. Docs, message replies, and support answers are
  explicit later layers. Web-chat surfaces are out of scope.

## Non-goals (v1)

- No build/compilation toolchain (files are hand-authored; approach #1).
- No docs/message/support generation.
- No web-chat integration.
- No org-wide rollout; this is one engineer's portable setup that others may adopt.

## Architecture

Two layers, one generic spine per repo, no build step. `install.sh` symlinks
hand-authored files into each tool's expected location so `git pull` propagates
updates everywhere at once.

```
ai-skills-and-agent/                 # canonical source -> personal GitHub
  persona/                           # LAYER 1 - personal, global, per-person
    beliefs.md                       #   durable engineering principles
    voice.md                         #   writing/review style
  standards/                         # LAYER 2 - team/industry, per-repo
    engineering.md                   #   curated standards
    review-checklist.md              #   the recurring anti-patterns as gates
    AGENTS.template.md               #   per-repo spine to scaffold into work repos
  skills/
    pre-flight-review/SKILL.md       #   active enforcement component
  install.sh                         #   wire persona + skill into a machine
  scaffold-repo.sh                   #   inject the team layer into a target repo
  capture.sh                         #   append a quick jot to a file's Inbox
  README.md
```

### Layer 1: personal, global

Installed to `~/.claude/CLAUDE.md` and `~/.claude/skills/`, plus best-effort
Cursor/Windsurf user-level rules. Applies to every repo the person touches, work
or personal. Contents: `beliefs.md` + `voice.md`.

### Layer 2: team/industry, per repo

A single `AGENTS.md` (the generic spine that Cursor, Windsurf, Devin, and Copilot
read or are adopting) plus a one-line `.github/copilot-instructions.md` shim that
points at it. Committed into each work repo so teammates and repo-aware tools also
benefit. `scaffold-repo.sh` seeds it from `AGENTS.template.md`.

### Per-tool delivery map

| Tool | Personal (global) | Team (per-repo) |
|------|-------------------|-----------------|
| Claude Code | `~/.claude/CLAUDE.md` (symlink), `~/.claude/skills/pre-flight-review/` | `./AGENTS.md` (imported by a one-line `./CLAUDE.md`) |
| GitHub Copilot | best-effort via editor user setting | `.github/copilot-instructions.md` (shim -> `AGENTS.md`) |
| Cursor | user rules | `.cursor/rules/*.mdc` or `AGENTS.md` |
| Windsurf | user rules/memories | `.windsurfrules` or `AGENTS.md` |
| Devin | n/a | `AGENTS.md` |

## Content model

### persona/beliefs.md (personal)

- Self-documenting code; comment only non-obvious intent, never restate code.
- Simplicity and readability first (a Zen-of-Python sensibility): simple over
  complex, readable over clever, explicit over implicit, flat over nested, prefer
  the one obvious way, and never let errors pass silently.
- Use the current recommended practices and idioms of whatever language or
  technology is in play (for example Java records instead of hand-written POJOs,
  modern stdlib, pattern matching); keep code contemporary rather than dated.
- Challenge the ticket; think big-picture about codebase impact before executing.
- Minor improvements only when related to the current task; refactoring expands
  scope and is avoided unless asked.
- Remove redundancy; no null checks for values that cannot be null.
- Customer-first: no breaking changes; design for extensibility and forward
  compatibility since the software is consumed by other products.
- Prefer standard patterns; keep code clean.
- Code is the source of truth. Verify claims from Confluence, READMEs, Jira
  tickets, or another service's docs against the actual code or schema before
  acting; confirm a contract before integrating rather than assuming.
- Verify before asserting. Do not push changes or call work done until all checks
  pass (build, tests, lint, CI); rely on real output, not assumptions.

### persona/voice.md (personal)

- Concise, human, straightforward prose.
- No em-dashes.
- No emojis in PR titles or descriptions.
- Review feedback is kind and Socratic: nudge the author toward the concern and
  let them decide ("what do you think about...?", "would it be simpler to...?")
  rather than issuing directives.
- Vary phrasing and keep it natural; avoid a formulaic template so feedback reads
  as a thoughtful human, not a predictable bot.
- Comment only at high confidence; keep each comment specific and actionable, not
  observational.

### standards/engineering.md (team, curated)

- Reuse platform/framework features before building new (platform APM over custom
  metrics; framework exception handling; standard pagination types; existing error
  mappers and enums).
- DTOs required-by-default; validate at the controller/bean-validation boundary,
  not defensively in services.
- Domain/application error codes over raw HTTP; never leak internal/downstream
  names to clients; preserve upstream status codes via shared mappers.
- Keep generated types (e.g. GraphQL) committed and in sync with the schema.
- Match the established sibling implementation for tagging/reporting/auth.
- Do not touch shared handlers/config unrelated to the change; keep PRs single
  purpose.
- Coverage must not regress.
- Follow the repo PR template and Jira branch/commit conventions.

### standards/review-checklist.md (the review gates)

Each gate is phrased as the reviewer's challenge:

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

## Pre-flight review skill

A Claude Code skill (`skills/pre-flight-review/SKILL.md`) run before pushing
(`/pre-flight-review` or before PR creation). It reads the branch diff, applies the
review gates plus beliefs and standards, confirms all checks pass, and reports
drift with `file:line` so the AI fixes its own work before a human reviewer sees
it. It **reuses the built-in `/code-review` skill** and layers the persona-specific
gates on top, rather than reimplementing review logic (itself one of the
standards). This is the component that catches the recurring anti-patterns before
they reach review.

## Portability

Canonical repo lives on personal GitHub. New machine:

```
git clone <repo> && cd ai-skills-and-agent && ./install.sh
```

`install.sh` symlinks `persona/` into `~/.claude/CLAUDE.md`, installs the skill
into `~/.claude/skills/`, and best-effort points Cursor/Windsurf user rules at the
same files. `scaffold-repo.sh <path>` drops `AGENTS.md` + the Copilot shim into a
target repo. Symlinks (not copies) mean `git pull` updates every tool at once. On
personal machines, Layer 1 applies automatically; Layer 2 is scaffolded only when
a repo needs specific rules.

Design choices confirmed: symlink install (auto-update); pre-flight skill reuses
`/code-review`; team layer is one `AGENTS.md` + Copilot shim per repo.

## Living documents

`beliefs.md`, `voice.md`, `review-checklist.md`, and the validation fixtures are
expected to grow as the engineer remembers rules or observes new drift. Two
properties keep editing frictionless:

- **Instant propagation.** Symlink install means editing a source file immediately
  changes what every tool reads locally, with no rebuild or re-install; committing
  and pulling propagates it to other machines.
- **Low-friction capture.** `beliefs.md` and `review-checklist.md` each end with an
  `## Inbox` section for quick, half-formed jots. An optional `capture.sh "text"`
  one-liner appends a timestamped note to the inbox of the relevant file. Inbox
  items are curated into proper rules whenever convenient. No tooling beyond a
  single append.

## Validation

Acceptance for v1: given tasks that previously triggered the drift signature, the
persona active produces work free of those anti-patterns (no nullable-required
fields, no single-use abstractions, no scope creep, and so on). A small set of
generic task scenarios is kept under `evals/`, each a short description of the task
and the anti-patterns it should no longer produce. No test framework; a written
scenario and a manual check is sufficient for v1. Scenarios are seeded from real
drift but written generically so they stay meaningful over time.

## Risks and mitigations

- **Tool support for `AGENTS.md` varies.** Mitigation: keep the Copilot shim and a
  one-line Claude Code import so no tool relies on native `AGENTS.md` alone.
- **Symlinks on a fresh machine may need the repo present before tools start.**
  Mitigation: `install.sh` is idempotent and documents the clone-first order.
- **Persona could grow verbose and lose signal.** Mitigation: v1 stays scoped to
  code + PR review; each rule earns its place from observed drift.
- **Global personal layer could leak personal prefs into shared repos.** Mitigation:
  personal layer stays on the machine; only the curated team layer is committed to
  work repos.

## Out of scope / later layers

Docs generation, message/support replies, web-chat prompt packs, and any
build/compilation step. These become additive layers once v1 is in daily use.
