---
status: completed
created: 2026-05-26
---

# Plan: Two-Sentence Description Format for `optimizing-skill-frontmatter`

## Context

The `optimizing-skill-frontmatter` skill (the "skill formatter") currently strips capability sentences from skill descriptions, leaving only the "Use when…" trigger phrase. This contradicts three existing sources of truth:

1. **`skill-authoring.md` checklist** — "Description includes both what the Skill does and when to use it"
2. **`best-practices.md` Pattern 1** — `Reviews X for Y. Use when the user asks to [action].` (capability *then* trigger)
3. **`skill-authoring.md` core quality check** — "Description is specific and includes key terms"

The formatter's current **Rule 5** explicitly strips "implementation-detail sentences that describe what the skill does internally" — which is exactly what capability sentences are. This is the bug. The audit rubric (`audit-steps.md`) only requires the "Use when…" phrase and does not check for a capability component, so skills that omit it still score 2/2 on Dimension 1 and 2/2 on Dimension 5.

Additionally, `plugin-patterns.md` says: *"Make descriptions clear about WHEN (not what) the skill activates"* — which directly contradicts Anthropic's own checklist and the Pattern 1 recommendation. This inconsistency needs to be resolved.

**No new frontmatter field is needed.** The existing `description:` field is the correct place; the two-sentence format is already documented in `best-practices.md`'s Discoverability Patterns section. The formatter just needs to produce it instead of strip it.

---

## Target Format

```yaml
# Two-sentence: capability first, trigger second (Pattern 1 from best-practices.md)
description: "Reviews SKILL.md files against authoring best practices. Use when the user asks to review, audit, or score a SKILL.md."

# Trigger first, capability second (also acceptable — Pattern 2)
description: "Use when the user asks to optimize SKILL.md frontmatter. Trims descriptions to ≤160 chars and tunes disable-model-invocation."
```

- **Sentence 1 (capability):** Third-person present-tense verb phrase describing *what the skill produces/does*.
- **Sentence 2 (trigger):** `"Use when the user asks to [condition]."` — the activation signal.
- **Total budget:** ≤160 chars. When trimming, shorten the capability sentence first; touch the trigger only as a last resort.

---

## Files to Change

### 1. `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md`

**a) Frontmatter description (line 3)** — self-demonstrate the two-sentence format:
```yaml
description: "Trims SKILL.md descriptions to ≤160 chars and tunes disable-model-invocation. Use when the user asks to optimize SKILL.md frontmatter."
```

**b) Overview (line 8)** — add one sentence noting the two-sentence description target:
> "As part of the description rewrite (Step 3), the formatter now targets descriptions that include both a capability sentence *and* a trigger sentence — aligning with Anthropic's authoring checklist."

**c) Step 2 Skip rule (line 80)** — tighten the skip condition. Current text qualifies a file for SKIP if it is `≤160 chars AND starts with "Use when"`. Update to:
> SKIP when: ≤160 chars **AND** contains both (a) a "Use when…" trigger phrase **and** (b) a capability sentence (a third-person verb clause that is not the trigger phrase itself).
> Files with only a trigger phrase are REWRITE candidates even if ≤160 chars, because they are missing the capability component.

**d) Rule 2 (lines 103-105)** — rewrite as "Two-sentence format":
```
### Rule 2 — Two-sentence format

Target descriptions with two components:
- **Capability sentence**: Third-person verb phrase describing what the skill does or produces.
  Example: "Trims SKILL.md descriptions to ≤160 chars and tunes disable-model-invocation."
- **Trigger sentence**: "Use when the user asks to [activation condition]."
  Example: "Use when the user asks to optimize SKILL.md frontmatter."

Either order is acceptable. Pattern 1 from best-practices.md (capability first, then trigger) is preferred:
  `[Capability.] Use when the user asks to [trigger].`

If only one component is present, add the missing one (see Rule 2b).
```

**e) New Rule 2b** — generate capability sentence when absent:
```
### Rule 2b — Generate missing capability sentence

If the description contains only a trigger phrase, extract the capability from the skill body's
`## Overview` or first paragraph. Compress to ≤80 chars, third-person, present tense, no filler.
Prepend it before "Use when…" as Sentence 1.

If the description contains only a capability (no trigger phrase), add a "Use when the user asks to…"
clause as Sentence 2.

Do not add a second capability or a second trigger if either is already present.
```

**f) Rule 5 (lines 127-131)** — remove capability sentences from the strip list:
```
### Rule 5 — Strip filler only

Remove:
- `"or says '…'"` example lists that restate the trigger phrase (the runtime already does fuzzy matching)
- Round-trip qualifiers ("in any capacity", "for that", "in one flow")

Do NOT remove:
- The capability sentence — it is required content, not filler
- Negative-scope clauses found in the trigger — relocate to body (Rule 4), but don't simply delete them
```

**g) Worked example** — replace the existing worked example with one that demonstrates adding a capability sentence:

```
**Before** (131 chars, trigger-only):
description: Use when the user asks to audit, fix, or generate the `allowed-tools` frontmatter
for a SKILL.md, or review which tools Claude used in a session.

**After** (145 chars, two-sentence):
description: "Audits, fixes, or generates the `allowed-tools` frontmatter for a SKILL.md.
Use when the user asks to check, fix, or review tool permissions for a skill."

What changed:
- Extracted capability ("Audits, fixes, or generates…") from the Overview section
- Prepended as Sentence 1 (capability)
- Retained the most discriminating trigger in Sentence 2
- Negative-scope clause relocated to body ## When not to use (Rule 4)
```

---

### 2. `kit/plugins/skill-reviewer/skills/reviewing-skills/references/audit-steps.md`

**Dimension 1 checks table** — add a new row after the existing `description trigger` row (line 89):

| Check | Requirement | Error / Warning |
|-------|-------------|-----------------|
| `description` capability | Should contain a capability statement (what the skill does), not only "Use when…" | Warning if absent |

**Dimension 1 scoring** — update 2-pt criterion:
- **2 pts** — No errors; description has "Use when…" trigger *and* a capability statement; third person
- **1 pt** — Minor issues: trigger present but capability absent, or description slightly long

**Dimension 5 checks table** — update the trigger clarity row:
| Trigger clarity | Trigger phrases are specific, not vague; description also includes capability statement | Warning if vague OR if capability absent |

---

### 3. `kit/plugins/skill-reviewer/skills/reviewing-skills/references/best-practices.md`

**Description Field requirements table** — add capability row after the existing `Trigger phrase` row (≈line 72):

| Capability statement | Third-person verb clause describing *what the skill does or produces* | Warning if absent — trigger alone is insufficient |

**Trigger phrase patterns section (≈line 76)** — add two-sentence examples:
```
**Two-sentence format (recommended — Pattern 1):**
Trims X and validates Y. Use when the user asks to optimize Z.
Reviews code for bugs and security issues. Use when the user asks to review a file.
```
Note that Pattern 1 in the Discoverability section already shows this; the Description section should cross-reference it rather than duplicate.

---

### 4. `.claude/rules/plugin-patterns.md`

**Documentation Principles section** — find and update the misleading line:

Old: `**Skill Activation** — Make descriptions clear about WHEN (not what) the skill activates`

New:
```
**Skill Description Format** — Descriptions must include both WHEN (trigger) and WHAT (capability).
Use the two-sentence Pattern 1: `[Capability statement.] Use when the user asks to [trigger].`
Source the capability sentence from the skill body's ## Overview section.
Total budget: ≤160 chars.
```

---

### 5. `kit/plugins/skill-reviewer/CHANGELOG.md`

Add entry under a new `## [2.1.0] — 2026-05-26` section:

- **feat:** `optimizing-skill-frontmatter` — add Rule 2b (generate capability sentence when only trigger present); update Rule 2 to target two-sentence format; update Rule 5 to preserve capability sentences
- **feat:** `reviewing-skills` — Dimension 1 and Dimension 5 now warn when description lacks a capability statement
- **feat:** `best-practices.md` — added capability-sentence requirement to Description Field table
- **fix:** `plugin-patterns.md` — removed "WHEN (not what)" guidance that contradicted Anthropic's own checklist

---

### 6. `.claude-plugin/marketplace.json`

Bump `skill-reviewer` version: `2.0.0` → `2.1.0` (MINOR: new formatting rule, backward-compatible).

---

## Verification

1. **Dogfood check:** Run `/skill-reviewer:optimizing-skill-frontmatter` on the `optimizing-skill-frontmatter` SKILL.md itself. The skill's own description (after update) should be flagged as already compliant (two-sentence, ≤160 chars).

2. **Audit check:** Run `/skill-reviewer:reviewing-skills` on a skill that has only a trigger phrase (e.g., `wcag-compliance-reviewer`). Expect a Warning in Dimension 1: "missing capability statement."

3. **Format check:** Run the formatter on a trigger-only description. Confirm it generates a capability sentence from the Overview, prepends it, and produces a valid two-sentence description ≤160 chars.

4. **Non-regression:** Skills already at ≤160 chars with both components (e.g., `running-tests`) should be classified as SKIP — no unnecessary rewrites.

5. **Validate plugin:** Run `/validate-plugin skill-reviewer` to confirm the plugin structure is still valid after changes.

6. **Marketplace JSON lint:** Confirm `.claude/settings.json` auto-validator passes after the version bump in `marketplace.json`.
