---
status: in-progress
created: 2026-02-27
---

# Plan: Optimize claude-md-optimizer SKILL.md (Progressive Disclosure Refactor)

## Context

The audit of `plugins/claude-md-optimizer/skills/claude-md-optimizer/SKILL.md` (score: 8/10,
"Good") surfaced three actionable gaps — the most significant being that all 295 lines are
inline with no `references/` delegation. This violates the three-level progressive disclosure
pattern that the skill itself teaches for CLAUDE.md files. The other gaps are a missing scope
boundary in the description and an unstated freedom level.

This plan extracts the dense Step 3 dimension rubrics and example output into a new
`references/audit-steps.md`, bringing the SKILL.md body down to ~175 lines and aligning the
plugin's own structure with the best practices it enforces.

---

## Files to Modify / Create

| File | Action |
|------|--------|
| `plugins/claude-md-optimizer/skills/claude-md-optimizer/SKILL.md` | Update (295 → ~175 lines) |
| `plugins/claude-md-optimizer/skills/claude-md-optimizer/references/audit-steps.md` | Create (new) |
| `plugins/claude-md-optimizer/.claude-plugin/plugin.json` | Version bump 1.4.0 → 1.5.0 |
| `.claude-plugin/marketplace.json` | Sync version to 1.5.0 |
| `plugins/claude-md-optimizer/CHANGELOG.md` | Add 1.5.0 entry |

---

## Step 1 — Update SKILL.md frontmatter description

**Current description:**
```
Use when the user asks to audit, optimize, review, clean up, or improve a CLAUDE.md file.
Also use when Claude is ignoring instructions, behaving inconsistently, or the CLAUDE.md
appears bloated or overloaded.
```

**Updated description (add scope boundary):**
```
Use when the user asks to audit, optimize, review, clean up, or improve a CLAUDE.md file.
Also use when Claude is ignoring instructions, behaving inconsistently, or the CLAUDE.md
appears bloated or overloaded. Does not cover SKILL.md files, plugin commands, or other
markdown files.
```

---

## Step 2 — Add freedom level to body intro

Replace the existing intro line:
```
Audit and optimize a CLAUDE.md file against Claude Code best practices. Follow all six steps
in order. Do not skip steps or combine them.
```

With:
```
Audit and optimize a CLAUDE.md file against Claude Code best practices.

> **Freedom level: Rigid** — Execute all six steps in the order listed. Do not skip, combine,
> or reorder them.
```

---

## Step 3 — Move Step 3 content and Example output to `references/audit-steps.md`

**Content to extract from SKILL.md body:**

1. All 6 dimension definitions under `## Step 3 — Run the 6-dimension audit` (the tables and
   scoring rules for Dimensions 1–6, ~90 lines)
2. The entire `## Example audit output` section (~45 lines of code block)
3. The `## Notes` section (~7 lines)

**Replace in SKILL.md body with a single pointer block:**

```md
## Step 3 — Run the 6-dimension audit

Score each dimension 0, 1, or 2. Maximum score: 12.

Full dimension definitions, scoring tables, and example audit output are in
[`references/audit-steps.md`](references/audit-steps.md). Load that file before scoring.
```

**New file `references/audit-steps.md` contains:**
- `# Audit Reference: Dimensions, Example Output, and Notes` heading
- All 6 dimension sections (verbatim from current SKILL.md Step 3)
- Example audit output section
- Notes section

---

## Step 4 — Update Table of Contents in SKILL.md

Remove `- [Example audit output](#example-audit-output)` and `- [Notes](#notes)` from TOC.
Update `- [Step 3 — Run the 6-dimension audit]` entry to reflect the shorter section.

---

## Step 5 — Version bump and changelog

- `plugin.json`: `"version": "1.4.0"` → `"version": "1.5.0"`
- `marketplace.json`: match the entry for `claude-md-optimizer` to `1.5.0`
- `CHANGELOG.md`: add entry:

```md
## [1.5.0] — 2026-02-27

### Changed
- Refactored SKILL.md to follow three-level progressive disclosure pattern
- Extracted Step 3 dimension scoring rubrics, example output, and notes to
  `references/audit-steps.md`
- Added explicit freedom level statement to skill body
- Added scope boundary to frontmatter description (excludes SKILL.md files and commands)
```

---

## Verification

1. After writing files, confirm line count: `wc -l .../SKILL.md` should be ~170–180 lines.
2. Confirm `references/audit-steps.md` exists and contains the 6 dimension sections.
3. Reload the plugin and run the skill on a test CLAUDE.md — all 6 dimensions should still
   score correctly (the content is referenced, not removed).
4. Run `grep -r '"version"' plugins/claude-md-optimizer/.claude-plugin/ .claude-plugin/marketplace.json`
   to confirm version sync.
