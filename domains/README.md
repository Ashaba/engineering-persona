# Domains

Per-industry lenses layered on top of the personal and team layers. When a domain
is active, the persona raises the severity of findings that match the domain's
criticality ordering and applies its domain rules to code, comments, and reviews.

## How the domain is resolved

1. Declared: the work repo's `AGENTS.md` `## Domain` section names a domain
   (`Domain: <name>`). This is the source of truth.
2. Inferred: if no domain is declared, the persona infers one from repo signals
   (dependencies, domain terms, org or repo name) and confirms with the user
   before applying it.
3. Default: if unconfirmed, or in a non-interactive tool, use `_default` (no
   reweighting).

## Files

Each `<domain>.md` has `## Criticality ordering`, `## Domain rules`, and `## Inbox`.
`scaffold-repo.sh <repo> <domain>` inlines a domain's ordering and rules into a work
repo's `AGENTS.md`. Add a domain by adding a file here.
