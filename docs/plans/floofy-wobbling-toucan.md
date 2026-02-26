# Review: planning-skills Skill Audit

Audit of `plugins/skill-reviewer/skills/planning-skills/SKILL.md` against the updated best practices (aligned with Anthropic's guide, Jan 2026).

---

## Skill Audit Report

**File:** `plugins/skill-reviewer/skills/planning-skills/SKILL.md`
**Guidelines Source:** Static: references/best-practices.md
**Total Lines:** 210
**Word Count:** ~1,400 (body only)
**Folder Structure:** Standard (SKILL.md + references/)
**Design Pattern:** Sequential / Pipeline

## Scores

| Dimension | Score | Notes |
|-----------|-------|-------|
| 1. Frontmatter Validity | 2/2 | Name is kebab-case, ≤64 chars, no reserved words. Description is third person, has "Use when..." with 6 explicit trigger phrases, scope exclusion present. |
| 2. Body Quality | 2/2 | ~210 lines (<400), ~1,400 words (<3,000). Consistent terminology. Multiple concrete examples (folder structure, frontmatter, outline, summary). Imperative voice. No time-sensitive content. |
| 3. Structure & Progressive Disclosure | 2/2 | TOC present (file >100 lines). Freedom level explicit ("Follow these steps exactly."). Reference depth ≤1. Folder is kebab-case. Three-level architecture: frontmatter (L1) → body steps (L2) → design-patterns.md (L3). |
| 4. Anti-pattern Detection | 2/2 | No Windows paths, no `$ARGUMENTS`/`$PWD`, no XML in description, no hardcoded absolute paths, no reserved words, correct SKILL.md casing, kebab-case folder. Step 2 explicitly handles "recommended default" pattern. |
| 5. Discoverability | 2/2 | Six explicit trigger phrases in description. Keywords: "plan", "design", "scaffold", "skill", "design pattern", "folder structure", "frontmatter". Scope exclusion: "not skill review or auditing." Distinct from `reviewing-skills`. |
| **Total** | **10/10** | |

## Grade: Excellent

## Issues Found

### Errors (must fix)

None.

### Warnings (should fix)

None.

### Suggestions (consider)

1. **Step 6 — no decline path.** Step 6 confirms the target directory before writing but does not specify what to do if the user says no. Consider adding: "If the user declines, ask where they'd like the files created instead."

2. **Cross-platform note missing.** The skill uses `TodoWrite`, `AskUserQuestion`, and `Write` — these are Claude Code tools. If this skill is intended for Claude Code only, a brief note would satisfy the new "cross-platform note" suggestion-level check. If it should also work in Claude.ai Projects, the `TodoWrite` and `AskUserQuestion` calls would need alternatives.

3. **Step 1 — fallback when user provides full context upfront.** Step 1 says "skip questions they have already answered" but doesn't explicitly handle the case where the user's initial message already contains all four answers. Consider adding: "If the user's message already covers purpose, triggers, tools, and output — skip to the concept summary without asking questions."

4. **Step 5 — no word count validation of outline.** Step 5 targets <400 lines, <3,000 words but does not describe what to do if the generated outline would exceed these limits. Consider adding: "If the outline suggests the body will exceed 3,000 words, recommend offloading detail to a reference file before proceeding."

5. **Reference file (design-patterns.md) — no mention of the Skill Pack pattern.** The design patterns reference covers the four core patterns well, but does not address when a user should consider splitting their planned skill into a Skill Pack (multiple skills in one plugin). This is documented in `best-practices.md` under "Skill Packs" but could be cross-referenced.

---

## Reference File Review: `references/design-patterns.md`

**Lines:** 214
**Quality:** Strong. Each pattern has: use-when trigger, real-world examples, structure signals, recommended SKILL.md outline, and key considerations.
**Decision tree:** Present and clear (lines 185–198).
**Pattern combinations:** Documented with concrete examples (lines 202–213).

**Minor suggestions:**
- Add a brief note linking to the Skill Packs concept in `best-practices.md` for when a planned skill outgrows a single SKILL.md.
- The Orchestrator pattern's recommended outline uses "Adapt these principles to the situation" as freedom level, while its use case (multi-service coordination) might benefit from a rigid freedom level with explicit error handling. Consider noting that Orchestrator skills can be either rigid or flexible depending on whether the service order is fixed.

---

## Proposed Fixes

Based on the suggestions above, here are the targeted edits:

### Fix 1: Add decline path to Step 6 (SKILL.md line 192)

After the confirmation prompt, add:
```
If the user declines or wants a different location, ask: "Where would you like me to create the skill folder? Please provide the path."
```

### Fix 2: Add early-exit to Step 1 (SKILL.md line 43)

Add before the question list:
```
If the user's initial message already provides the purpose, triggers, tools, and expected output — skip directly to the concept summary without asking questions.
```

### Fix 3: Add word-count guardrail to Step 5 (SKILL.md line 156)

Add after the quality targets:
```
If the outline suggests the body will exceed 3,000 words, recommend creating a reference file for the most detailed section before proceeding.
```

### Fix 4: Cross-reference Skill Packs in design-patterns.md

Add a brief note at the end of the "Choosing a Pattern" section:
```
If the planned skill serves two distinct user intents, consider a Skill Pack instead of a single skill — see the Skill Packs section in `best-practices.md`.
```
