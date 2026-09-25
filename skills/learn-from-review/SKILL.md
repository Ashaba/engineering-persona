---
name: learn-from-review
description: Use after a PR review catches something the persona missed. Turns a review comment into a concrete persona rule in the right layer (beliefs, voice, standards, review gates, or a domain), shows a diff for approval, and commits it. Never posts to the PR and never pushes.
---

# Learn from Review

Turn a missed pattern from a PR review into a durable persona rule, so the persona
catches it next time.

## When to use

After a human PR review flags something the code or the review should have caught.

## Input and requirements

Give the skill one of:

- A PR URL. Reading it needs a GitHub tool: a connected GitHub MCP server or the
  `gh` CLI, authenticated for that host. For Expedia (eg-internal) PRs use the
  enterprise GitHub tool; for personal repos use the github.com tool.
- Or the review comments pasted directly. No GitHub access needed.

If a PR URL is given but no GitHub access is available, ask the user to paste the
comments rather than guessing.

## Steps

1. Get the review comments: fetch them via the GitHub tool for the URL, or use the
   pasted text.
2. For each substantive comment, state in one sentence the underlying pattern that
   was missed.
3. Classify where the rule belongs (paths relative to this skill):
   - personal principle -> `../../persona/beliefs.md`
   - writing or review conduct -> `../../persona/voice.md`
   - team standard -> `../../standards/engineering.md`
   - a review gate -> `../../standards/review-checklist.md`
   - industry-specific -> `../../domains/<domain>.md`
   Read the target file first. If the rule, or a near-duplicate, is already there,
   say so and stop rather than adding a duplicate.
4. Propose the exact rule wording and the target file, and show the diff. Keep it
   concise, in the user's voice, no em-dashes, general rather than tied to this one
   PR.
5. On the user's approval, append the rule to the correct section of the target
   file and commit to the persona repo with a `NO_JIRA` message.

## Rules

- One rule per pattern; keep it short and general.
- Never post, comment, or reply on the PR. This skill only updates the persona
  locally.
- Never push. The user pushes.
