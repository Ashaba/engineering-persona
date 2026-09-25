# Engineering standards for this repo

Contributors apply their personal engineering principles through their own global
setup. The standards below are team-level. Tailor the repo-specific section.

## Working here

<!-- Fill per repo: build command, test command, lint command, CI expectations. -->

## Standards

- Reuse platform and framework features before building new.
- DTOs required-by-default; validate at the boundary, not defensively in services.
- Domain/application error codes over raw HTTP; never leak internal names; preserve
  upstream status codes via shared mappers.
- Keep generated types committed and in sync with the schema.
- Match the established sibling implementation for tagging, reporting, and auth.
- Keep PRs single purpose; do not touch unrelated shared handlers or config.
- Coverage must not regress.
- No emojis in PR titles or descriptions; concise, human prose.

## Review gates

- Second consumer of this abstraction? If none, inline it.
- Does the framework, platform, or language already do this? Use it.
- Duplicates existing code or a type? Reuse the original.
- A field that can never be null but is optional? Make it required; validate at the
  boundary.
- Anything unrelated to the task? Remove or defer it.
- Swallows an error, leaks an internal detail, or drops an upstream status?
- Changes behavior for other callers, or lets a contract or generated artifact
  drift from its source?
- Dated pattern where a current idiom exists?
- An assumption taken from a doc or ticket without confirming against the code?

## Domain

Domain: unset

No domain is declared. Infer the domain from repo signals and confirm with me
before applying a lens. Until confirmed, use the default lens.
