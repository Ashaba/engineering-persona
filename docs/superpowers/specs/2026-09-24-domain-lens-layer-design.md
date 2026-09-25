# Domain Lens Layer: Design

Date: 2026-09-24
Status: Approved (design), pending implementation plan
Owner: jashabahebwa
Builds on: docs/superpowers/specs/2026-09-24-engineering-persona-system-design.md

## Problem

The engineering persona applies the same criticality everywhere. But the same
workflow will be used across industries whose stakes differ: travel today,
finance/trading tomorrow (where numerical precision, auditability, and latency are
paramount), agriculture after that. A bug that is minor in one domain is severe in
another. The persona needs to know what field it operates in and adjust how
critically it judges code, comments, and PR reviews, and to bring domain-specific
intuition to bear.

## Goals

- Add a domain lens layer on top of the existing personal and team layers that,
  when active, (a) reweights how severely the review gates and coding priorities
  are judged and (b) adds concrete domain-specific rules.
- Resolve the active domain by a hybrid rule: a declared domain is the source of
  truth; when absent, infer from repo signals and confirm with the user before
  applying; otherwise fall back to a generic default.
- Keep the layer portable and self-contained per repo, consistent with the
  existing architecture (AGENTS.md spine, inlined content for work repos).
- Keep domain files as living documents, extensible via the existing Inbox
  convention.
- Seed a starter set of domains and make adding more trivial.

## Non-goals

- No automatic, unconfirmed domain switching. Inference never applies a lens
  without confirmation.
- No new runtime/build tooling. Detection-by-inference is model behavior in the
  pre-flight skill, not a script.
- No exhaustive or authoritative domain rulebooks in v1. Seed lenses are honest
  starters meant to grow via the Inbox.
- No change to the personal layer (beliefs, voice); domain is a property of the
  project, not the person.

## Architecture

The domain lens is a third layer:

    personal beliefs + voice  ->  team standards + gates  ->  domain lens

### The domain library (persona repo)

New directory `domains/`:

    domains/
      README.md              # registry + how detection works
      _default.md            # baseline lens; used when no domain is known/confirmed
      finance-trading.md
      travel.md
      agriculture.md

Each domain file (except README) has two sections plus an Inbox:

- `## Criticality ordering` - the concerns this domain judges hardest, most
  critical first, each with a one-line reason. This is what reweights review
  severity.
- `## Domain rules` - concrete, checkable rules specific to the domain.
- `## Inbox` - quick jots, curated later (living document).

`_default.md` carries a neutral ordering (correctness first, then the standard
gates as written) and no extra rules, so an unknown domain degrades to today's
behavior.

### Declaration (work repo)

The active domain is declared in the work repo's `AGENTS.md` under a `## Domain`
section as a single line: `Domain: <name>` (for example `Domain: finance-trading`).
This is committed and shared with the team, so it lives in the team layer, not the
personal layer. Every tool already reads `AGENTS.md`, so no tool-specific config is
needed. When no domain is chosen, the section reads `Domain: unset` with a note
that the persona will infer and confirm.

### Detection flow (hybrid)

Resolve the domain in this order:

1. Read the declared `Domain:` from the repo's `AGENTS.md`. If it names a known
   domain, use it.
2. If `unset` or absent, infer from repo signals (dependencies, domain terms in
   code, org/repo name, README) and ask the user to confirm the inferred domain
   before applying its lens.
3. If unconfirmed, or running in a non-interactive tool (for example plain
   autocomplete) where no confirmation is possible, fall back to `_default.md`.

Step 2 is model behavior described in the pre-flight skill; it requires no script.

### Delivery to code-writing tools

Work repos cannot read the persona repo, so the relevant domain lens is inlined
into the work repo's `AGENTS.md` at scaffold time, the same self-contained approach
the review gates already use. `scaffold-repo.sh` takes an optional domain argument,
validates it against `domains/`, and inlines that domain's `Criticality ordering`
and `Domain rules` into the generated `AGENTS.md` under `## Domain`. Omitting the
argument leaves `Domain: unset`.

## Changes to existing components

- `standards/AGENTS.template.md`: add a `## Domain` section with `Domain: unset`
  and a placeholder where a lens is inlined.
- `scaffold-repo.sh`: accept an optional second argument `<domain>`; if given,
  require that `domains/<domain>.md` exists (exit non-zero on unknown domain) and
  inline its two lens sections into the generated `AGENTS.md`; if omitted, write
  `Domain: unset` with the infer-and-confirm note. Preserve the existing
  no-clobber behavior.
- `skills/pre-flight-review/SKILL.md`: add a "Resolve the domain" step implementing
  the detection flow, then apply the resolved lens: raise the severity of findings
  that match the domain's criticality ordering and check the domain rules. Load the
  lens from the repo's `AGENTS.md` `## Domain` section if inlined, else from
  `../../domains/<domain>.md`.
- `README.md`: document the domain layer, the `Domain:` declaration, the detection
  flow, and `scaffold-repo.sh <path> <domain>`.

## Content model: seed domains

- `_default.md`: correctness first; standard gates at their written severity; no
  extra rules.
- `finance-trading.md`: ordering emphasizes numerical precision, correctness,
  auditability, determinism, latency, regulatory compliance. Rules include: money
  and quantities use exact decimal types, never binary floating point; state
  mutations are audit-logged; time handling is explicit about timezone and
  precision; no silent rounding.
- `travel.md`: ordering emphasizes availability, data consistency, price and
  inventory accuracy, idempotency of bookings, backward compatibility for
  consumers. Rules include: never trust a cached price for a commit action; make
  booking mutations idempotent.
- `agriculture.md`: a thin, honest starter (for example: units and measurement
  systems are explicit; seasonal/time-window correctness matters), clearly marked
  as a starter to enrich via the Inbox rather than invented authoritative rules.

Seed set for v1: `_default`, `finance-trading`, `travel`, `agriculture`. Adding a
domain is one new file plus, optionally, scaffolding a repo with it.

## Validation

- `scaffold-repo.sh <path> finance-trading` inlines the finance lens into the
  generated `AGENTS.md`; an unknown domain exits non-zero; omitting the domain
  leaves `Domain: unset`. Covered by an extended `test/scaffold_test.sh`.
- Manual eval: run the pre-flight skill against a diff in a repo declared as
  `finance-trading` and confirm a float-for-money finding is raised to a higher
  severity than it would carry under `_default`. Recorded as an `evals/` scenario.

## Risks and mitigations

- Wrong inferred domain misweights judgment. Mitigation: inference never applies
  without confirmation; declaration is always the source of truth.
- Domain files drift toward bloated, speculative rulebooks. Mitigation: seed
  lenses stay short and honest; growth happens through the Inbox as real needs
  appear.
- Inlined lens in a work repo goes stale versus the persona library. Mitigation:
  the declared `Domain:` line records which lens was applied; refreshing an inlined
  lens is a manual edit, since re-running `scaffold-repo.sh` preserves an existing
  `AGENTS.md`.
- Non-interactive tools cannot confirm an inference. Mitigation: they use the
  declared domain or the default; confirmation is only a convenience in
  interactive contexts.

## Out of scope

Automatic lens refresh in work repos, a domain-detection script, per-domain test
suites, and `capture.sh` support for domain files (domains are edited directly for
now). These can follow once the layer is in use.
