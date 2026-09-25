---
name: pre-flight-review
description: Use before pushing a branch or opening a PR. Reviews the working diff against the engineer's beliefs, team standards, and the recurring anti-pattern gates, confirms all checks pass, and reports drift with file:line so it is fixed before a human reviewer sees it.
---

# Pre-flight Review

Run before you push or open a PR. Goal: catch the recurring drift a human reviewer
would otherwise catch, and fix it first.

## Load the persona (relative to this skill)

- Gates: `../../standards/review-checklist.md`
- Beliefs: `../../persona/beliefs.md`
- Voice for any comments: `../../persona/voice.md`

Read those three files first. They are the source of truth and change over time.

## Steps

1. Determine the base branch (`main` or `master`) and get the diff: `git diff <base>...HEAD`.
2. Run the built-in `/code-review` on the current diff for correctness and cleanup findings.
3. Apply every gate from the review checklist to each changed file. For each hit,
   report `file:line`, which gate fired, and a one-line fix.
4. Confirm checks pass: build, tests, lint, and CI are green. Do not report
   ready-to-push until they are; if you cannot run them, say so explicitly.
5. Summarize findings most-severe first, or state plainly that the diff is clean.

## Writing any comments

Never post, submit, or publish comments or reviews on the user's behalf. Do not run
`/code-review --comment`, do not submit a GitHub review, do not post to a PR. Produce
findings as a local report or pending/draft comments only; the user posts them.

Follow `voice.md`: kind and Socratic, invite the author to decide, vary phrasing,
no em-dashes, no emojis, concise and specific.
