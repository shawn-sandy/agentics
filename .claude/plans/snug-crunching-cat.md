# Plan: Add `claude-md-optimizer` Skill to dev-tools Plugin

## Context

This adds a new skill to the existing `dev-tools` plugin that audits and optimizes CLAUDE.md files against Claude Code best practices from the CLAUDE.md Masterclass. The skill enforces:
- The ~150-200 instruction budget limit (Claude Code uses ~50 of those)
- The "80% Rule" (only include instructions relevant to 80%+ of sessions)
- Progressive disclosure (reference separate docs instead of bloating the main file)
- Safety hygiene (no secrets, no linter-duplicating rules)

---

## Files to Create

1. `plugins/dev-tools/skills/claude-md-optimizer/SKILL.md` — new skill file

## Files to Modify

2. `plugins/dev-tools/.claude-plugin/plugin.json` — bump version `1.0.0` → `1.1.0`
3. `marketplace-data/.claude-plugin/marketplace.json` — bump dev-tools version + add skill to components

---

## Steps

### 1. Create skill directory and SKILL.md

Create `plugins/dev-tools/skills/claude-md-optimizer/SKILL.md` with:

**YAML frontmatter:**
```yaml
---
name: claude-md-optimizer
description: Audit and optimize a CLAUDE.md file against Claude Code best practices. Use when the user asks to optimize, improve, audit, review, clean up, or analyze a CLAUDE.md file. Also activate when the user reports Claude ignoring instructions or behaving inconsistently — these are symptoms of a poorly structured CLAUDE.md.
version: 1.0.0
allowed-tools: Read, Glob, Edit, Write
---
```

**Skill body (6 steps using progressive disclosure):**

- **Step 1 — Resolve target file**: Priority: explicit arg → `$PWD/CLAUDE.md` → `~/.claude/CLAUDE.md`. Tell user which file will be audited. Stop if none found.
- **Step 2 — Read and measure**: Approximate instruction count (verb-starting bullets, numbered directives, bolded imperatives). Record line count. Inventory `##` sections. Scan for sensitive data patterns (`sk-`, `ghp_`, `AKIA`, etc. and label-preceded long strings).
- **Step 3 — Run 6-dimension audit** (each scored 0/1/2, max 12):
  1. **Instruction Budget** — 50–150 = 2, 150–200 = 1, >200 or <10 = 0
  2. **Section Quality** — presence + conciseness of 5 key sections (overview, tech stack, commands, folder structure, conventions)
  3. **80% Rule Compliance** — no task-specific workflows, deployment runbooks, onboarding steps
  4. **Progressive Disclosure** — complex content delegated to referenced files
  5. **Safety and Hygiene** — no secrets, no linter-replaceable style rules, no content Claude can deduce from code
  6. **Structure and Navigability** — clear heading hierarchy, no instruction bleeding, CLAUDE.md.local pattern mentioned
- **Step 4 — Present scored report**: Table of scores + grade (10–12 optimized, 7–9 functional, 4–6 needs work, 0–3 rewrite). Critical issues section first. Per-dimension findings. Top 3 recommendations.
- **Step 5 — Offer optimized version**: Ask user. If confirmed, generate in chat (do not write yet). Apply: remove critical issues, prune 80%-rule violations (move to `## Suggested Move to Separate Files` block), condense padded sections, add missing section stubs.
- **Step 6 — Offer to write**: Ask again with warning to commit first. Write only on second explicit confirmation.

**Also include:** example audit output showing a 6/12 score scenario, tips section, scope boundaries.

---

### 2. Update `plugin.json`

`plugins/dev-tools/.claude-plugin/plugin.json`:
- Change `"version": "1.0.0"` → `"version": "1.1.0"`
- Change `"description"` → `"Developer productivity tools for code formatting, review, and CLAUDE.md optimization"`

### 3. Update `marketplace.json`

`marketplace-data/.claude-plugin/marketplace.json`, in the `dev-tools` entry:
- Change `"version": "1.0.0"` → `"version": "1.1.0"`
- Add `"plan-interview"` to `components.commands` array (currently missing from registry)
- Add `"claude-md-optimizer"` to `components.skills` array

---

## Verification

1. Confirm skill file exists: `ls plugins/dev-tools/skills/claude-md-optimizer/SKILL.md`
2. Validate YAML frontmatter has `name`, `description`, `version`, `allowed-tools`
3. Confirm version parity: `plugin.json` and `marketplace.json` both show `1.1.0`
4. Load plugin and test activation:
   ```bash
   claude --plugin-dir ./plugins/dev-tools "Optimize my CLAUDE.md"
   ```
5. Test explicit invocation path: ask Claude to audit `~/.claude/CLAUDE.md` and verify it resolves the correct file and produces a scored report.

---

## Unresolved Questions

- None. Scope is clear from the blog post analysis and existing skill patterns.

---

## Interview Summary

### Key Decisions Confirmed
- **Instruction count heuristic**: Rough estimate (±30-50 variance) is acceptable given the wide scoring bands
- **Skill-only, no command**: File resolution via natural language in Step 1 is sufficient
- **Broad activation description**: Symptom-based triggers ("Claude ignoring instructions") are intentional — valuable for catching root-cause cases
- **`allowed-tools` removed from frontmatter**: Drop it; no reference skills use it and it may be silently ignored or cause a parse warning

### Open Risks & Concerns
- `plan-interview` command fix in Step 3 is bundled without explicit rationale — could be missed in review
- No CLAUDE.md test fixture planned — inconsistent with the repo's testing pattern
- The "audit both files" path in the skill description is not verified in the plan's test steps
- Edge case for empty/very short CLAUDE.md files has no explicit user-facing handling

### Recommended Next Steps
1. Update Step 3 to explicitly call out the `plan-interview` fix as a separate named sub-step with rationale
2. Cut or scope the "audit both files" path — either add it to verification steps, or remove it from the skill to keep scope focused
3. Remove `allowed-tools` from the planned YAML frontmatter (confirmed)
4. Consider adding a `tests/fixtures/sample-claude-md/` directory with a representative CLAUDE.md for manual testing reference

### Simplification Opportunities
None identified — the plan's scope matches the task complexity.
