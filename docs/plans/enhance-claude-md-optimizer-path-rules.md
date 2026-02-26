# Plan: Enhance claude-md-optimizer Plugin with Memory Docs Guidance

## Context

The claude-md-optimizer plugin audits CLAUDE.md files, but its Step 5 only generates an optimized CLAUDE.md. It doesn't guide developers to:
- Break content into path-scoped `.claude/rules/` files using `paths:` frontmatter
- Add `@import` references for external docs
- Reference the SKILL.md itself from their project so the optimizer is always available

The official Claude Code memory docs (<https://code.claude.com/docs/en/memory>) define the authoritative format for path-scoped rules, `@import` syntax, and memory load order. This plan enhances the plugin so when shared with other developers/projects, it guides this full optimization pattern.

**Scope:** Plugin files only. No changes to this project's own `CLAUDE.md` or `.claude/rules/`.

---

## Step 1 — Update `skills/claude-md-optimizer/SKILL.md`

**File:** `plugins/claude-md-optimizer/skills/claude-md-optimizer/SKILL.md`

### Change A — Dimension 4 (Progressive Disclosure)

After the existing delegation mechanism bullets, insert concrete `paths:` frontmatter examples with brace expansion and a link to the official docs:

```markdown
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
```

### Change B — Step 4 Recommendations (Progressive Disclosure low score)

In the "Top 3 Recommendations" guidance (Step 4 report), add a standing recommendation when Dimension 4 scores ≤ 1:

> When Progressive Disclosure scores 0 or 1, include as a Top 3 item: "Use Step 5's rule-file generation to break path-specific content into `.claude/rules/` files."

This primes users for what Step 5 will offer.

### Change C — Step 5 (Optimized version generation)

**Replace** the existing `## Suggested Move to Separate Files` block transformation with a new rule-file offer flow. The current block duplicates what the new flow handles — eliminate it.

After the existing transformation list, add:

```markdown
**Offer to generate `.claude/rules/` files:**

For each section removed as an 80%-rule violation or path-specific content:
1. Show the proposed rule file in a code block with `paths:` frontmatter:

```md
---
paths:
  - "<glob>"
---

# <Descriptive Title>

- Rule bullet 1
- Rule bullet 2
- Rule bullet 3
```

2. Check if `.claude/rules/` exists. If not, ask: "The `.claude/rules/` directory does not exist. Should I create it?"
3. Ask: "Should I write this to `.claude/rules/<name>.md`?" Wait for explicit confirmation before writing each file.

**After the CLAUDE.md code block, show a separate callout:**

```markdown
---
**To make this optimizer always available in your project**, add the following to your CLAUDE.md
(replace `<plugin-dir>` with the path passed to `--plugin-dir` when loading this plugin):

```md
@<plugin-dir>/skills/claude-md-optimizer/SKILL.md
```
---
```

This callout appears after — not inside — the generated CLAUDE.md code block.
```

### Change D — Notes section

Replace the existing `@path/to/file` bullet:

**Before:**

```text
- Use `@path/to/file` import syntax to reference external docs without embedding their full content. Use `.claude/rules/*.md` for modular, path-scoped rules.
```

**After:**

```text
- Use `@path/to/file` import syntax to reference external docs without embedding their full content. Use `.claude/rules/*.md` for modular, path-scoped rules. Official reference: <https://code.claude.com/docs/en/memory>
- To make this optimizer always available in a project, add `@<plugin-dir>/skills/claude-md-optimizer/SKILL.md` to the project's CLAUDE.md (replace `<plugin-dir>` with the actual `--plugin-dir` path).
```

---

## Step 2 — Update `skills/path-rules-advisor/SKILL.md`

**File:** `plugins/claude-md-optimizer/skills/path-rules-advisor/SKILL.md`

### Change — Rule file format section

Inside the existing `## Rule file format` section (after the current format block), append brace expansion examples:

```markdown
**Brace expansion** (from official docs: <https://code.claude.com/docs/en/memory>):

```md
---
paths:
  - "src/**/*.{ts,tsx}"
  - "{src,lib}/**/*.ts"
---
```

This expands to match multiple extensions or directories in a single rule.
```

---

## Step 3 — Version Bump: 1.2.0 → 1.3.0

Step 5 gains new observable behavior (rule-file generation, @import callout), warranting a **MINOR** bump.

### 3a. `plugins/claude-md-optimizer/.claude-plugin/plugin.json`

Change `"version"` from `"1.2.0"` to `"1.3.0"`.

### 3b. `.claude-plugin/marketplace.json`

Change `"version"` for the `claude-md-optimizer` entry from `"1.2.0"` to `"1.3.0"`.

### 3c. `plugins/claude-md-optimizer/CHANGELOG.md`

Prepend above `[1.2.0]`:

```markdown
## [1.3.0] - 2026-02-24

### Added

- Step 5: Offers to generate `.claude/rules/` files for each section extracted during optimization
- Step 5: Shows `@import` callout (after the CLAUDE.md block) for referencing the optimizer in any project
- Step 5: Checks for `.claude/rules/` directory existence; prompts to create if missing
- Dimension 4: Added `paths:` frontmatter glob examples and brace expansion patterns from official docs
- Step 4: Added standing recommendation to use Step 5 rule-file generation when Progressive Disclosure scores ≤ 1
- path-rules-advisor: Added brace expansion examples within Rule file format section
- Notes: Added official memory docs URL and self-referencing `@import` usage tip

### Changed

- Step 5: Removed `## Suggested Move to Separate Files` block — replaced by rule-file offer flow
```

---

## Execution Order

1. Step 1 — Update `claude-md-optimizer/SKILL.md` (Changes A–D, no dependencies)
2. Step 2 — Update `path-rules-advisor/SKILL.md` (no dependencies)
3. Step 3 — Version bump (after skill files are finalized)

---

## Verification

```bash
# Confirm version sync
grep -r '"version"' plugins/claude-md-optimizer/.claude-plugin/ .claude-plugin/marketplace.json

# Confirm skill files reference official docs URL
grep -n "code.claude.com/docs/en/memory" \
  plugins/claude-md-optimizer/skills/claude-md-optimizer/SKILL.md \
  plugins/claude-md-optimizer/skills/path-rules-advisor/SKILL.md

# Confirm Step 5 no longer mentions "Suggested Move to Separate Files"
grep -n "Suggested Move" \
  plugins/claude-md-optimizer/skills/claude-md-optimizer/SKILL.md
```

---

## Critical Files

| File | Action |
|------|--------|
| `plugins/claude-md-optimizer/skills/claude-md-optimizer/SKILL.md` | Dimension 4 examples, Step 4 recommendation, Step 5 rule-file flow + @import callout, Notes URL |
| `plugins/claude-md-optimizer/skills/path-rules-advisor/SKILL.md` | Brace expansion in Rule file format section |
| `plugins/claude-md-optimizer/.claude-plugin/plugin.json` | Bump to 1.3.0 |
| `.claude-plugin/marketplace.json` | Bump claude-md-optimizer to 1.3.0 |
| `plugins/claude-md-optimizer/CHANGELOG.md` | Add 1.3.0 entry |

---

## Interview Summary

### Key Decisions Confirmed

- `@import` path uses `<plugin-dir>` placeholder — user replaces with their actual `--plugin-dir` value
- Rule-file offers stay in Step 5 (not a new step), with inline write confirmation per file
- Version bump is MINOR → 1.3.0 (observable new Step 5 behavior)
- Rule file format template embedded inline in Step 5 (not delegated to path-rules-advisor)
- `.claude/rules/` directory existence checked before any write; prompt to create if missing
- Brace expansion examples go inside the existing `## Rule file format` section of path-rules-advisor

### Open Risks Resolved

- **Step 4 ↔ Step 5 disconnect** — resolved: Step 4 now surfaces rule-file recommendation when Dimension 4 scores ≤ 1
- **Duplicate outputs** — resolved: `## Suggested Move to Separate Files` block removed; rule-file offer replaces it
- **@import placement** — resolved: shown as a separate callout after the CLAUDE.md code block, not inside it
- **Directory gap** — resolved: Step 5 checks for `.claude/rules/` existence and prompts to create
