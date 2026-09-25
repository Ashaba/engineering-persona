---
name: learn-sweep
description: Scheduled sweep that reads new eg-internal PR reviews since a watermark, generalizes and scrubs them into persona rules, and opens a gated PR on this repo. Runs locally. Never merges, never commits to main, never posts to a source PR.
---

# Learn Sweep

Automated, gated version of learn-from-review. Runs unattended and proposes
learnings as a pull request.

## Source (defined once)

- host: `github.com`
- org: `eg-internal`
- query: pull requests the current user authored
This block is the single place the source is configured; a future config overrides it here. Other mentions of the org or host in this file are descriptive prose, not configuration.

## Accounts

- Read reviews with the work gh account (github.com, work identity).
- Open the gate PR with the `Ashaba` gh account.
Never cross them: internal reads use work; the personal repo uses Ashaba.

## Watermark

`~/.claude/engineering-persona/last-sweep` holds an ISO timestamp. If absent, use
7 days ago. Update it to now only after a successful run.

## Steps

1. Check gh auth and network. If either is missing, log and exit without changing
   the watermark.
2. List PRs from the source (authored) with review activity since the watermark;
   collect review comment bodies.
3. For each actionable comment, write the missed pattern as one generalized
   sentence: no code, URLs, repo or service names, ticket IDs, or paths.
4. Run each proposed rule through `../../scrub-check.sh "<rule>"`. If it exits
   non-zero, drop the rule and log that one was dropped (never write it).
5. Classify each surviving rule into `../../persona/beliefs.md`,
   `../../persona/voice.md`, `../../standards/engineering.md`,
   `../../standards/review-checklist.md`, or `../../domains/<domain>.md`. Dedup
   against the current file contents.
6. If any rules survive: create branch `NO_JIRA_learned-<YYYY-MM-DD>`, append each
   rule to its target section, commit, push (ash key), and open a PR with the
   Ashaba account titled `NO_JIRA learned rules (<YYYY-MM-DD>)`. The PR body lists
   each rule and its layer and notes it was auto-derived and generalized. No
   internal specifics anywhere.
7. Update the watermark to now.

## Rules

- Only open a PR. Never merge it, never commit to `main`, never post or reply on a
  source PR.
- One rule per pattern; generalized wording only.
- If nothing survives the scrub and dedup, exit cleanly with no branch and no PR.
