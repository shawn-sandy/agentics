---
status: todo
created: 2026-03-28
---

# Plan: Fix plan-status SKILL.md audit findings

## Context

The `plan-status` skill was audited against Anthropic's official skill authoring best practices using the `reviewing-skills` skill. It scored **7/10 (Good)** with 3 warnings and 3 suggestions. This plan addresses the 5 fixes needed to reach 9-10/10.

**File:** `plugins/plan-interview/skills/plan-status/SKILL.md`

## Changes

1. **Add scope exclusion to description** (frontmatter line 3)
   - Append: `— not for stress-testing, validating, or critiquing plan content.`
   - Mirrors exact language in sibling skills (deep-grill, plan-interview)
   - Original wording ("editing") was misleading — plan-status does write frontmatter

2. **Change H1 to H2** (line 8)
   - `# Plan Status` → `## Plan Status`
   - Per best practices, frontmatter `name` serves as title; body starts at H2

3. **Add freedom level signal** (after overview, before TOC)
   - Insert: `Follow these steps exactly.`
   - Signals rigid sequential workflow
   - Must appear before TOC — behavioral instruction precedes navigation scaffolding

4. **Add Table of Contents** (after freedom level signal)
   - Insert TOC with links to all 8 steps
   - Required because file exceeds 100-line threshold (178 lines)

5. **Add default to options in Step 4** (line 103)
   - `Offer options:` → `Offer options (default: todo):`
   - Fixes "options without default" anti-pattern

## Verification

- Confirm file is valid YAML frontmatter (no parse errors)
- Confirm heading hierarchy: H2 → H3, no H1 in body
- Confirm TOC links resolve to correct anchors
- Re-run `/skill-reviewer:reviewing-skills` to verify score improves

## Notes

- The TOC rule in `best-practices.md` (used by the skill-reviewer) is overstated: the live Anthropic docs require TOC only for **reference files** longer than 100 lines, not SKILL.md itself. The audit warning should be a suggestion. The TOC is still worth adding for navigability.

## Next Steps

- Consider adding a `references/` directory if the skill grows beyond 3,000 words
- Consider adding scope exclusions to other plan-interview skills (deep-grill, plan-interview)
- Update `plugins/skill-reviewer/skills/reviewing-skills/references/best-practices.md` to clarify TOC rule applies to reference files, not SKILL.md
