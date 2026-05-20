# Audit Reference: Dimensions, Example Output, and Notes

## Dimension 1 — Instruction Budget (max 2)

Claude Code allocates roughly 150–200 slots of its context for system-level instructions. Claude itself consumes ~50. This leaves ~100–150 for project instructions.

| Estimated instruction count | Score |
|-----------------------------|-------|
| 50–150                      | 2     |
| 150–200                     | 1     |
| >200 or <10                 | 0     |

## Dimension 2 — Section Quality (max 2)

Check for presence and conciseness of these five sections:

1. Project overview / purpose
2. Tech stack (languages, frameworks, key dependencies)
3. Common commands (build, test, lint, dev server)
4. Folder structure (key directories only)
5. Conventions (naming, patterns, style)

- All 5 present and concise = 2
- 3–4 present, or present but padded = 1
- Fewer than 3 present = 0

## Dimension 3 — 80% Rule Compliance (max 2)

The 80% Rule: only include instructions relevant to 80% or more of Claude sessions on this project.

Flag content that violates this rule:
- Task-specific workflows (e.g., "when deploying to staging, do X")
- Deployment runbooks or release procedures
- Onboarding steps for new team members
- One-off migration instructions
- Detailed troubleshooting guides for rare scenarios

- No violations found = 2
- 1–2 violations = 1
- 3+ violations = 0

## Dimension 4 — Progressive Disclosure (max 2)

Check whether complex, reference, or rarely-needed content is delegated outside CLAUDE.md rather than embedded in full. Claude Code supports two delegation mechanisms:

- **`.claude/rules/*.md`** — loaded automatically by Claude Code; can be path-scoped with `paths:` frontmatter to activate only for matching files
- **External docs** (e.g., `docs/architecture.md`, `CONTRIBUTING.md`) — referenced via `@import` or a plain link

**Path-scoped rule format** (official docs: <https://code.claude.com/docs/en/memory>):

```md
---
paths:
  - "src/api/**/*.ts"
  - "tests/**"
---
```

Brace expansion is supported: `src/**/*.{ts,tsx}`, `{src,lib}/**/*.ts`.
Use `paths:` only when the rule truly applies to specific file types — avoid over-scoping.

- Complex content properly delegated = 2
- Some delegation but file is still bloated = 1
- Everything is inline, file is very long = 0

## Dimension 5 — Safety and Hygiene (max 2)

Check for four hygiene issues:

1. **Secrets** — any sensitive credentials (caught in Step 2)
2. **Linter-replaceable rules** — style rules that belong in `.eslintrc`, `prettier.config.js`, or similar (e.g., "always use 2-space indentation", "never use semicolons")
3. **Inferable content** — facts Claude can deduce from reading the codebase (e.g., "this project uses React" when `package.json` is present)
4. **Default-restating rules** — instructions that merely restate Claude's built-in behavior and would not change what Claude does without them. Examples: "write clear and readable code", "add tests for new features", "use descriptive variable names", "be concise", "prefer composition over inheritance". A rule passes if it is specific enough that removing it would change Claude's behavior on this project.

- No hygiene issues = 2
- 1 issue = 1
- 2+ issues = 0

## Dimension 6 — Structure and Navigability (max 2)

- Clear `##` heading hierarchy (no flat walls of text)
- No instruction bleeding across sections
- `CLAUDE.local.md` pattern mentioned or considered (for machine-specific or personal overrides; Claude Code auto-adds it to `.gitignore`)
- No stale or contradictory instructions

- All criteria met = 2
- 1–2 gaps = 1
- Poorly structured or contradictory = 0

---

## Example audit output

For a 6/12 "Needs work" file:

```
## CLAUDE.md Audit Report

**File:** /Users/alice/projects/myapp/CLAUDE.md
**Lines:** 210 | **Estimated instructions:** 185 ± 40

### Scores

| Dimension              | Score | Max |
|------------------------|-------|-----|
| Instruction Budget     | 1     | 2   |
| Section Quality        | 2     | 2   |
| 80% Rule Compliance    | 0     | 2   |
| Progressive Disclosure | 1     | 2   |
| Safety & Hygiene       | 1     | 2   |
| Structure              | 1     | 2   |
| **Total**              | **6** | **12** |

**Grade:** Needs work

### Critical Issues

1. **80% Rule violations (Score: 0)** — File contains a 40-line deployment runbook for staging and a 20-line onboarding checklist. These apply to fewer than 20% of sessions and inflate the instruction count significantly.

### Per-dimension findings

- **Instruction Budget:** ~185 instructions is in the caution zone; removing the runbook and onboarding content should bring this below 150.
- **Section Quality:** All 5 key sections present and concise. Well done.
- **80% Rule:** Deployment runbook (lines 120–160) and onboarding checklist (lines 161–181) should be moved to separate docs.
- **Progressive Disclosure:** Architecture diagram is referenced, but the full API contract is embedded inline (50 lines).
- **Safety & Hygiene:** `.eslintrc` rules duplicated in the conventions section — these belong in the config file.
- **Structure:** Heading hierarchy is clear, but the last section mixes conventions and troubleshooting.

### Top 3 Recommendations

1. Move the deployment runbook to `docs/deploy.md` and replace with a one-line reference.
2. Move onboarding checklist to `CONTRIBUTING.md`.
3. Remove ESLint rules from the conventions section — they belong in `.eslintrc`.
```

