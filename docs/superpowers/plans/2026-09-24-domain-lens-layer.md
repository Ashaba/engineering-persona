# Domain Lens Layer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a per-industry domain lens layer that reweights review criticality and adds domain rules, resolved from a declared domain (source of truth) with a confirmed-inference fallback.

**Architecture:** A new `domains/` library of per-industry lens files in the persona repo. Each work repo declares its domain in its `AGENTS.md` `## Domain` section; `scaffold-repo.sh` inlines the chosen domain's lens there. The pre-flight skill resolves the domain (declared, else infer and confirm, else default) and applies its criticality ordering and rules. No build step; all hand-authored.

**Tech Stack:** Bash, Markdown, Claude Code skill format, git.

**Spec:** docs/superpowers/specs/2026-09-24-domain-lens-layer-design.md

## Global Constraints

- Hand-authored; no build/compilation tooling.
- No em-dashes and no emojis in any prose.
- Each domain file (except `domains/README.md`) has `## Criticality ordering`, `## Domain rules`, and `## Inbox` sections (living document).
- Declared domain is the source of truth; inference must be confirmed before applying; unknown or unconfirmed degrades to `_default` (no reweighting).
- `scaffold-repo.sh` stays idempotent and never clobbers an existing `AGENTS.md` or copilot shim, even when a domain is passed.
- Keep the existing `test/scaffold_test.sh` assertions intact; only add to them.
- Work on branch `NO_JIRA_domain-lens-layer` (already checked out, off `main`). Commit after each task with the `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>` trailer.

## Review Focus

- `scaffold-repo.sh <repo> <unknown-domain>` must exit non-zero and write no `AGENTS.md`, not silently produce a default one. (Task 3)
- `scaffold-repo.sh <repo> <domain>` must not leak the domain file's `## Inbox` section into the work repo's `AGENTS.md`. (Task 3)
- `scaffold-repo.sh <repo>` with no domain must leave `Domain: unset`, and the pre-existing no-clobber behavior must still hold. (Task 3)
- `scaffold-repo.sh <repo> <domain>` against a repo that already has `AGENTS.md` must not overwrite it (no-clobber holds with a domain too). (Task 3)
- The pre-flight skill must never apply an inferred domain lens without confirmation, and must fall back to `_default` when unconfirmed or non-interactive. (Task 4, verified by reading the SKILL text)

---

### Task 1: Domain library (`domains/`)

**Files:**
- Create: `domains/README.md`
- Create: `domains/_default.md`
- Create: `domains/finance-trading.md`
- Create: `domains/travel.md`
- Create: `domains/agriculture.md`

**Interfaces:**
- Consumes: nothing.
- Produces: the domain library. `domains/finance-trading.md` contains the exact rule text `exact decimal types` (Task 3's test greps for it). Each lens file's first line is an H1 title, followed by `## Criticality ordering`, `## Domain rules`, `## Inbox`, in that order.

- [ ] **Step 1: Write `domains/README.md`**

```markdown
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
```

- [ ] **Step 2: Write `domains/_default.md`**

```markdown
# _default

The baseline lens. Used when no domain is declared, or an inferred domain is not
confirmed. It changes nothing: judge by the standard gates at their written
severity.

## Criticality ordering

- Correctness first, then the standard review gates as written. No domain-specific
  reweighting.

## Domain rules

- None beyond the standard engineering standards.

## Inbox

<!-- Quick jots land here via capture.sh; curate above when convenient. -->
```

- [ ] **Step 3: Write `domains/finance-trading.md`**

```markdown
# finance-trading

Lens for finance and trading systems, where precision, correctness, auditability,
and latency carry outsized stakes.

## Criticality ordering

- Numerical precision and correctness. A rounding or type error moves real money.
- Auditability. Every state change must be traceable and reproducible.
- Determinism. Same inputs, same outputs; no hidden nondeterminism in pricing or
  settlement.
- Latency and throughput. Slow paths lose money; measure and bound them.
- Regulatory compliance. Data retention, access control, and reporting are not
  optional.

## Domain rules

- Money and quantities use exact decimal types, never binary floating point.
- No silent rounding; rounding mode and scale are explicit and documented.
- State mutations (orders, trades, balances) are audit-logged with actor and time.
- Time handling is explicit about timezone and precision; prefer UTC and monotonic
  clocks for durations.
- Fail closed on ambiguous financial state; never guess a price or a fill.

## Inbox

<!-- Quick jots land here via capture.sh; curate above when convenient. -->
```

- [ ] **Step 4: Write `domains/travel.md`**

```markdown
# travel

Lens for travel and booking systems, where availability, consistency, and accurate
inventory and pricing drive customer trust.

## Criticality ordering

- Availability and graceful degradation. Prefer a degraded read over an outage.
- Data consistency across inventory, pricing, and bookings.
- Price and inventory accuracy at the moment of commit.
- Idempotency of bookings and payments; no double-charge, no double-book.
- Backward compatibility for downstream consumers of the API.

## Domain rules

- Never commit a booking or a charge against a cached or stale price; re-validate
  at commit time.
- Make booking and payment mutations idempotent with idempotency keys.
- Treat supplier and downstream failures as expected; map them without leaking
  internal names.
- Keep availability and pricing responses forward compatible; additive changes
  only.

## Inbox

<!-- Quick jots land here via capture.sh; curate above when convenient. -->
```

- [ ] **Step 5: Write `domains/agriculture.md`**

```markdown
# agriculture

Lens for agriculture and agri-tech systems. This is a thin starter; enrich it via
the Inbox as real needs appear rather than treating it as authoritative.

## Criticality ordering

- Units and measurement correctness (area, weight, volume, temperature); a unit
  mistake ruins downstream calculations.
- Time and season correctness; many operations are tied to narrow windows.
- Data provenance from sensors and field inputs, which are often noisy or missing.

## Domain rules

- Make units explicit in types and at boundaries; never assume a default unit.
- Handle missing or delayed sensor data explicitly; do not treat absence as zero.

## Inbox

<!-- Quick jots land here via capture.sh; curate above when convenient. -->
```

- [ ] **Step 6: Verify content**

Run: `grep -c '^## Inbox' domains/_default.md domains/finance-trading.md domains/travel.md domains/agriculture.md && grep -q 'exact decimal types' domains/finance-trading.md && ! grep -rn '—' domains/ && echo OK`
Expected: each lens file reports `1`, the finance rule string is present, no em-dashes, prints `OK`.

- [ ] **Step 7: Commit**

```bash
git add domains/
git commit -m "NO_JIRA add domain lens library (default, finance-trading, travel, agriculture)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 2: Add `## Domain` section to the AGENTS template

**Files:**
- Modify: `standards/AGENTS.template.md`

**Interfaces:**
- Consumes: nothing.
- Produces: a template ending with a `## Domain` section whose default is `Domain: unset` plus an infer note. Task 3 truncates the generated file at the `## Domain` line when inlining a domain, so this heading text must be exactly `## Domain`.

- [ ] **Step 1: Append the `## Domain` section**

Edit `standards/AGENTS.template.md`. It currently ends after the `## Review gates` list (last line: `- An assumption taken from a doc or ticket without confirming against the code?`). Append these lines to the end of the file:

```markdown

## Domain

Domain: unset

No domain is declared. Infer the domain from repo signals and confirm with me
before applying a lens. Until confirmed, use the default lens.
```

- [ ] **Step 2: Verify**

Run: `grep -n '^## Domain' standards/AGENTS.template.md && grep -n '^Domain: unset' standards/AGENTS.template.md && ! grep -n '—' standards/AGENTS.template.md && echo OK`
Expected: both lines found, no em-dashes, prints `OK`.

- [ ] **Step 3: Commit**

```bash
git add standards/AGENTS.template.md
git commit -m "NO_JIRA add Domain section to AGENTS template

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 3: Domain support in `scaffold-repo.sh` (TDD)

**Files:**
- Modify: `scaffold-repo.sh`
- Modify: `test/scaffold_test.sh`

**Interfaces:**
- Consumes: `domains/<name>.md` (Task 1) and the template's `## Domain` section (Task 2).
- Produces: `scaffold-repo.sh <path-to-repo> [domain]` that, for a fresh `AGENTS.md`, inlines the domain lens under a `## Domain` section and sets `Domain: <name>`; rejects an unknown domain with exit 3; preserves no-clobber.

- [ ] **Step 1: Add the failing domain assertions to `test/scaffold_test.sh`**

Insert the following block immediately BEFORE the final `echo PASS` line (keep all existing assertions above it unchanged):

```bash
# domain: known domain inlines the lens into a fresh repo
d1="$(mktemp -d)"
"$here/scaffold-repo.sh" "$d1" finance-trading >/dev/null
grep -q '^Domain: finance-trading' "$d1/AGENTS.md" || { echo "FAIL: domain not declared"; exit 1; }
grep -q 'exact decimal types' "$d1/AGENTS.md" || { echo "FAIL: lens not inlined"; exit 1; }
if grep -q '## Inbox' "$d1/AGENTS.md"; then echo "FAIL: domain Inbox leaked into AGENTS.md"; exit 1; fi
rm -rf "$d1"

# domain: omitted leaves Domain unset
d2="$(mktemp -d)"
"$here/scaffold-repo.sh" "$d2" >/dev/null
grep -q '^Domain: unset' "$d2/AGENTS.md" || { echo "FAIL: expected Domain unset"; exit 1; }
rm -rf "$d2"

# domain: unknown domain is rejected (non-zero, no AGENTS.md written)
d3="$(mktemp -d)"
if "$here/scaffold-repo.sh" "$d3" nonsense-domain >/dev/null 2>&1; then echo "FAIL: unknown domain accepted"; exit 1; fi
if [ -e "$d3/AGENTS.md" ]; then echo "FAIL: AGENTS.md written for unknown domain"; exit 1; fi
rm -rf "$d3"

# domain: no-clobber still holds when a domain is passed
d4="$(mktemp -d)"
printf 'custom repo rules\n' > "$d4/AGENTS.md"
"$here/scaffold-repo.sh" "$d4" finance-trading >/dev/null
grep -q 'custom repo rules' "$d4/AGENTS.md" || { echo "FAIL: clobbered existing AGENTS.md with domain"; exit 1; }
rm -rf "$d4"
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash test/scaffold_test.sh`
Expected: FAIL on the first new assertion (current `scaffold-repo.sh` ignores the second argument, so `Domain: finance-trading` is absent).

- [ ] **Step 3: Rewrite `scaffold-repo.sh` with domain support**

Replace the entire contents of `scaffold-repo.sh` with:

```bash
#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target="${1:-}"
domain="${2:-}"
{ [ -n "$target" ] && [ -d "$target" ]; } || { echo "usage: scaffold-repo.sh <path-to-repo> [domain]" >&2; exit 2; }

if [ -n "$domain" ] && [ ! -f "$REPO_DIR/domains/$domain.md" ]; then
  echo "unknown domain: $domain (see $REPO_DIR/domains/)" >&2
  exit 3
fi

agents="$target/AGENTS.md"
copilot_dir="$target/.github"
copilot="$copilot_dir/copilot-instructions.md"

if [ -e "$agents" ]; then
  echo "skip: $agents already exists (edit by hand to avoid clobbering)"
else
  cp "$REPO_DIR/standards/AGENTS.template.md" "$agents"
  if [ -n "$domain" ]; then
    lens="$(awk 'NR==1 && /^# /{next} /^## Inbox/{exit} {print}' "$REPO_DIR/domains/$domain.md")"
    awk '/^## Domain/{exit} {print}' "$agents" > "$agents.tmp"
    {
      printf '## Domain\n\n'
      printf 'Domain: %s\n\n' "$domain"
      printf '%s\n' "$lens"
    } >> "$agents.tmp"
    mv "$agents.tmp" "$agents"
    echo "created $agents (domain: $domain)"
  else
    echo "created $agents"
  fi
fi

mkdir -p "$copilot_dir"
if [ -e "$copilot" ]; then
  echo "skip: $copilot already exists"
else
  printf 'See [AGENTS.md](../AGENTS.md) for engineering standards and review expectations.\n' > "$copilot"
  echo "created $copilot"
fi
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `bash test/scaffold_test.sh`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add scaffold-repo.sh test/scaffold_test.sh
git commit -m "NO_JIRA add domain inlining to scaffold-repo with tests

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 4: Apply the lens in the skill, and document it

**Files:**
- Modify: `skills/pre-flight-review/SKILL.md`
- Modify: `README.md`
- Create: `evals/03-domain-criticality.md`

**Interfaces:**
- Consumes: the `domains/` library and the `## Domain` convention.
- Produces: a skill that resolves and applies the domain lens, and docs describing the layer.

- [ ] **Step 1: Add the "Resolve the domain" section to the skill**

In `skills/pre-flight-review/SKILL.md`, insert the following new section between the line `Read those three files first. They are the source of truth and change over time.` and the line `## Steps` (that is, after the persona-loading paragraph, before the Steps heading):

```markdown

## Resolve the domain

Determine the active domain before reviewing:

1. If the repo's `AGENTS.md` has a `## Domain` section naming a domain
   (`Domain: <name>`), use it.
2. If it is `unset` or absent, infer the domain from repo signals (dependencies,
   domain terms, org or repo name) and ask me to confirm before applying it. Never
   apply an unconfirmed inference.
3. If unconfirmed or non-interactive, use `_default` (no reweighting).

Load the resolved lens from the repo's inlined `## Domain` section, or from
`../../domains/<name>.md`. Apply it: raise the severity of findings that match its
criticality ordering, and check its domain rules.
```

- [ ] **Step 2: Update the Steps list in the skill**

Replace this exact block:

```markdown
1. Determine the base branch (`main` or `master`) and get the diff: `git diff <base>...HEAD`.
2. Run the built-in `/code-review` on the current diff for correctness and cleanup findings.
3. Apply every gate from the review checklist to each changed file. For each hit,
   report `file:line`, which gate fired, and a one-line fix.
4. Confirm checks pass: build, tests, lint, and CI are green. Do not report
   ready-to-push until they are; if you cannot run them, say so explicitly.
5. Summarize findings most-severe first, or state plainly that the diff is clean.
```

with:

```markdown
1. Determine the base branch (`main` or `master`) and get the diff: `git diff <base>...HEAD`.
2. Resolve the active domain (see "Resolve the domain") and load its lens.
3. Run the built-in `/code-review` on the current diff for correctness and cleanup findings.
4. Apply every gate from the review checklist to each changed file, using the domain
   lens to weight severity and adding its domain rules. For each hit, report
   `file:line`, which gate or rule fired, and a one-line fix.
5. Confirm checks pass: build, tests, lint, and CI are green. Do not report
   ready-to-push until they are; if you cannot run them, say so explicitly.
6. Summarize findings most-severe first, or state plainly that the diff is clean.
```

- [ ] **Step 3: Update `README.md` Layers list**

In `README.md`, replace this exact block:

```markdown
- `standards/` team, per repo. `engineering.md`, `review-checklist.md`, and
  `AGENTS.template.md`.
```

with:

```markdown
- `standards/` team, per repo. `engineering.md`, `review-checklist.md`, and
  `AGENTS.template.md`.
- `domains/` industry lenses, per repo. Reweight review criticality and add domain
  rules. Declared in a repo's `AGENTS.md` `## Domain` section.
```

- [ ] **Step 4: Update `README.md` Daily use scaffold line and add a Domains section**

In `README.md`, replace this exact line:

```markdown
- Add a team layer to a work repo: `./scaffold-repo.sh <path-to-repo>`.
```

with:

```markdown
- Add a team layer to a work repo: `./scaffold-repo.sh <path-to-repo> [domain]` (for example `finance-trading`).
```

Then insert this new section immediately AFTER the `## Daily use` list (after the `capture.sh` bullet) and BEFORE the `## Living documents` heading:

```markdown

## Domains

A repo declares its industry in its `AGENTS.md` `## Domain` section
(`Domain: finance-trading`). When set, the persona judges matching concerns more
critically and applies domain rules. If unset, it infers the domain and confirms
before applying. Seeded domains live in `domains/`; add one by adding a file.
```

- [ ] **Step 5: Write `evals/03-domain-criticality.md`**

```markdown
# Scenario: domain raises criticality

Task: in a repo declared `Domain: finance-trading`, review a diff that stores a
monetary amount in a binary float.

Must produce: the float-for-money issue raised at high severity, citing the finance
domain rule that money uses exact decimal types. Under `_default` the same issue
would carry only standard severity.
```

- [ ] **Step 6: Verify**

Run: `grep -q '^## Resolve the domain' skills/pre-flight-review/SKILL.md && grep -q '^## Domains' README.md && ! grep -rn '—' skills/pre-flight-review/SKILL.md README.md evals/03-domain-criticality.md && echo OK`
Expected: both sections present, no em-dashes, prints `OK`.

- [ ] **Step 7: Commit**

```bash
git add skills/pre-flight-review/SKILL.md README.md evals/03-domain-criticality.md
git commit -m "NO_JIRA apply domain lens in skill and document the layer

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 5: End-to-end verification

**Files:**
- None created; verifies the increment.

**Interfaces:**
- Consumes: all prior tasks.

- [ ] **Step 1: Full shell test suite**

Run: `for t in test/*_test.sh; do echo "== $t"; bash "$t" || exit 1; done`
Expected: each prints `PASS`.

- [ ] **Step 2: Live scaffold demo shows the finance lens inlined**

Run:
```bash
tmp="$(mktemp -d)"; ./scaffold-repo.sh "$tmp" finance-trading; echo "--- AGENTS.md Domain section ---"; awk '/^## Domain/{p=1} p' "$tmp/AGENTS.md"; rm -rf "$tmp"
```
Expected: output shows `Domain: finance-trading` followed by the `## Criticality ordering` and `## Domain rules` content, and no `## Inbox`.

- [ ] **Step 3: No em-dashes in shipped prose**

Run: `! grep -rn '—' domains standards/AGENTS.template.md skills README.md evals && echo OK`
Expected: prints `OK`.

## Notes for the implementer

- Domain files are read by `scaffold-repo.sh` via `awk` that skips the H1 title and stops at `## Inbox`, so the section order in each lens file matters: title, ordering, rules, then Inbox last.
- The `## Domain` heading text must stay exactly `## Domain` in both the template and the skill, since the scaffold truncates on it.
