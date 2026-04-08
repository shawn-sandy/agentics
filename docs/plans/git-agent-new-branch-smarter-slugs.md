# Plan: Smarter Branch Slugs in `new-branch` Skill

> Suggested rename on save: `git-agent-new-branch-smarter-slugs.md`

## Context

The `new-branch` skill in the `git-agent` plugin currently slugifies the user's
argument mechanically — lowercase, replace non-alphanumerics with `-`, truncate
at 50 characters. That turns realistic prompts into verbose, ugly branch names:

| User argument                                | Current slug                      | Desired slug      |
| --------------------------------------------- | --------------------------------- | ----------------- |
| "new branch for the login fix"                | `new-branch-for-the-login-fix`    | `login-fix`       |
| "start a feature for dark mode"               | `start-a-feature-for-dark-mode`   | `dark-mode`       |
| "add authentication middleware for API routes"| `add-authentication-middleware-…` | `auth-middleware` |

The user wants Claude to **interpret the argument semantically**, extract the
core subject, and produce a short, readable slug (≤20 characters when possible)
— then apply the mechanical slug normalization on top.

Scope is limited to the branch-slug logic. The skill's own name
(`new-branch`), activation criteria, and overall flow remain unchanged.

---

## Objective

Teach the `new-branch` skill to generate concise, human-readable branch slugs
from the user's natural-language description instead of mechanically
slugifying the whole sentence.

## Critical Files

- [kit/plugins/git-agent/skills/new-branch/SKILL.md](kit/plugins/git-agent/skills/new-branch/SKILL.md) — the only file with logic changes (Steps 4b and 4d)
- [kit/plugins/git-agent/CHANGELOG.md](kit/plugins/git-agent/CHANGELOG.md) — add a v1.2.1 entry
- [.claude-plugin/marketplace.json](.claude-plugin/marketplace.json) — bump `git-agent` version from `1.2.0` → `1.2.1`

## Steps

### 1. Rewrite Step 4b — "Description source" (SKILL.md:98-108)

Change the instructions so Claude actively strips filler wording when
extracting the subject from the user's message.

- Keep: check user's message first; fall back to `AskUserQuestion` if no
  description is present.
- Add: explicit guidance to discard meta-phrases like "new branch for",
  "start a feature for", "can you make a branch to", "I need a branch that".
- Add: reduce the subject to the **actual work**, not the ask. Example:
  "start a feature for dark mode" → subject is `dark mode`, not
  `start a feature for dark mode`.

Why: separating "what did they say" from "what's the work" is cleaner than
trying to make Step 4d un-do filler after the fact.

### 2. Rewrite Step 4d — "Slugify the description" (SKILL.md:133-144)

Replace the section title with **"Build a concise, readable slug"** and
replace the body with these rules:

1. From the extracted subject, pick a short, descriptive phrase — the noun
   phrase that names the work (e.g., "login fix", "dark mode",
   "auth middleware", "onboarding tour").
2. Drop articles (`a`, `an`, `the`), filler verbs (`add`, `make`, `create`,
   `update`, `fix`, `start`), and filler prepositions (`for`, `of`, `to`,
   `with`, `about`) **unless removing them would make the slug ambiguous**.
3. Aim for **≤20 characters** in the final slug. If the natural phrase
   exceeds 20 characters, shorten by: (a) using well-known abbreviations
   (`authentication` → `auth`, `middleware` → `mw` only if needed,
   `configuration` → `config`, `database` → `db`), or (b) dropping the
   least-essential word. Never truncate mid-word except as a last resort.
4. Normalize the chosen phrase: lowercase, replace any run of non-`[a-z0-9-]`
   with a single `-`, trim leading/trailing `-`.
5. If the resulting slug still exceeds 40 characters (hard cap), truncate at
   the last `-` before 40. If empty, print
   `Could not derive a branch name from that input.` and **STOP**.

Include 3–4 worked examples inline in the skill body so Claude has concrete
patterns to follow. Use the examples from the Context table above.

Why: a hard algorithm (step 1 of old 4d) can't judge which words matter.
Delegating "pick the noun phrase" to Claude's language understanding, then
applying deterministic normalization on top, gets both judgment and
repeatability.

### 3. Update `argument-hint` frontmatter (SKILL.md:5)

Leave as-is. The existing hints (`"new branch for the login fix"`,
`"start a feature for dark mode"`) are exactly the cases the new logic
handles well — they become the proof that the change works.

### 4. Add a CHANGELOG entry

Prepend to [kit/plugins/git-agent/CHANGELOG.md](kit/plugins/git-agent/CHANGELOG.md):

```markdown
## v1.2.1 — Smarter branch slugs in new-branch

- `new-branch` now extracts the core subject from the user's argument and produces short, readable slugs (≤20 chars when possible) instead of mechanically slugifying the whole sentence
- Example: "start a feature for dark mode" → `dark-mode` (was `start-a-feature-for-dark-mode`)
```

### 5. Bump version in marketplace.json

Change the `git-agent` entry's `version` from `"1.2.0"` to `"1.2.1"`
([.claude-plugin/marketplace.json:137](.claude-plugin/marketplace.json#L137)).

Why PATCH not MINOR: no new component is added, no activation contract
changes. This is a behavior refinement of an existing skill — PATCH per
[.claude/rules/marketplace.md](.claude/rules/marketplace.md).

## Verification

1. **Dry-run the examples against the updated instructions.** Read the
   revised SKILL.md and mentally walk each Context-table row through Step 4b
   then 4d. Each should land on the desired slug (or something comparably
   short and readable).

2. **Load the plugin locally and invoke the skill:**
   ```bash
   claude --plugin-dir ./kit/plugins/git-agent
   ```
   Then try each of these prompts in a clean git repo and confirm the
   proposed branch name is short and readable:
   - "new branch for the login fix" → expect `fix/login-fix` or similar
   - "start a feature for dark mode" → expect `feat/dark-mode`
   - "add authentication middleware for the API routes" → expect
     `feat/auth-middleware` or similar
   - "chore to clean up the test fixtures" → expect `chore/test-fixtures`

3. **Validate JSON.** The project's `.claude/settings.json` hook runs JSON
   validation on `marketplace.json` after every Write/Edit. Confirm no
   errors surface after the version bump.

4. **Commit message check.** When committing, use:
   `fix(kit/plugins/git-agent): bump version to 1.2.1` — matches the project's
   conventional commit pattern for PATCH bumps.

## Unresolved Questions

- None. User confirmed (via AskUserQuestion) that the target is branch-naming
  logic, not a skill rename.

## Next Steps (out of scope)

- Consider applying the same "concise, readable name" treatment to
  `commit-agent` subjects (e.g., commit message scope derivation) if users
  report similar verbosity there.
- Audit `ship` skill for any other mechanical text transformations that
  might benefit from semantic extraction.
- Add a small test fixture under `tests/fixtures/` with example user
  messages and expected slug outputs, so this behavior can be regression-
  tested in the future.
