# Description rewrite rules

Loaded by Step 3. Apply all five rules in order. Do not proceed to edits until
rewrites are drafted.

## Contents

- [Rule 1 — Target ≤200 chars total; short description ≤80 chars](#rule-1--target-200-chars-total-short-description-80-chars)
- [Rule 2 — Three-part format](#rule-2--three-part-format)
- [Rule 2b — Generate missing component(s)](#rule-2b--generate-missing-components)
- [Rule 3 — Preserve the most discriminating trigger](#rule-3--preserve-the-most-discriminating-trigger)
- [Rule 4 — Relocate negative-scope clauses](#rule-4--relocate-negative-scope-clauses)
- [Rule 5 — Strip filler only](#rule-5--strip-filler-only)
- [Worked example A](#worked-example-a--trimming-an-over-long-description--adding-short-description-rules-1-2-35)
- [Worked example B](#worked-example-b--adding-missing-short-description-rule-2b)
- [Step 4 apply order](#step-4-apply-order)

## Rule 1 — Target ≤200 chars total; short description ≤80 chars

The description value (not including `description:` or surrounding quotes) must be ≤200 chars total. The first sentence (short description, up to and including the first `. `) must be ≤80 chars. Count carefully — both limits apply independently.

These are budget targets, not platform limits. The platform enforces ≤1,024 chars per description. The 200-char total target fits the full three-part description for ~40 skills installed (8,000 ÷ 200 = 40). The 80-char short description survives at ~100 skills. If the user explicitly wants a higher total target, use their stated limit — but keep the short description ≤80 chars regardless, since it must survive aggressive truncation.

## Rule 2 — Three-part format

Target descriptions with three components in this order:

1. **Short description**: One sentence, ≤80 chars, third-person. The single most essential function in plain language — what the skill *is* at a glance. Distilled from the skill name and the first sentence of `## Overview`. Example: `”Optimizes SKILL.md frontmatter fields.”`
2. **Capability sentence**: Third-person verb phrase with richer detail — specific outputs, flags, or modes the skill handles. Example: `”Rewrites descriptions to three-part format (≤200 chars) and tunes disable-model-invocation.”`
3. **Trigger sentence**: `”Use when the user asks to [activation condition].”` Example: `”Use when the user asks to optimize SKILL.md frontmatter.”`

Fixed order: short description first, capability second, trigger last. Third-person voice throughout. No first-person (“I will”, “I can”).

If any component is missing, see Rule 2b.

## Rule 2b — Generate missing component(s)

Handle each missing component independently:

**Missing short description** (most common after this format change): extract the first sentence of the `## Overview` section and compress to ≤80 chars, third-person, present tense. Prepend as Sentence 1 before the existing capability and trigger.

**Missing capability** (description has only short description + trigger, or only trigger): extract the core action/output from `## Overview`. Compress to ≤120 chars, third-person. Insert as Sentence 2 between the short description and the trigger.

**Missing trigger** (no "Use when…" phrase): draft `"Use when the user asks to [condition]."` from the skill name and Overview. Append as the final sentence.

Do not add a second short description, a second capability, or a second trigger if any is already present.

When all three components together exceed 200 chars: shorten the capability sentence first, then the short description (keeping it ≤80 chars), then shorten the trigger only if the capability is already minimal.

## Rule 3 — Preserve the most discriminating trigger

If the current description lists 4+ triggers that are near-synonyms (“create”, “generate”, “scaffold”, “build”), collapse to the 1–2 most distinctive. Keep the trigger that uniquely distinguishes this skill from sibling skills in the same plugin.

Example collapse: “create an agent, generate an agent plugin, scaffold an agent, add an agent to a plugin, build a new agent, or make a sub-agent” → “create, scaffold, or generate an agent or sub-agent in a plugin”

## Rule 4 — Relocate negative-scope clauses

Any clause matching these patterns belongs in the body, not the description:

- “Does not cover X”
- “Does NOT do Y — use Z for that”
- “Not for stress-testing / validating / critiquing”
- “Use X-skill for that”

**Remove** the clause from the description. **Add** a `## When not to use` section to the body with the same information. If the body already has a `## Scope`, `## Limitations`, or equivalent section, add the content there instead of creating a duplicate section.

**Insertion point for new section:** after `## Overview` (if present), otherwise before `## Table of Contents`, otherwise before the first `## Step N` heading.

## Rule 5 — Strip filler only

Remove:
- `”or says ‘…’”` example lists that restate the trigger phrase in natural language (the runtime already does fuzzy matching)
- Round-trip qualifiers (“in any capacity”, “for that”, “in one flow”)

Do NOT remove:
- The capability sentence — it is required content per Rule 2, not filler
- Scope-exclusion clauses (“Does not cover X”) — relocate to body via Rule 4; do not simply delete them

---

## Worked example A — trimming an over-long description + adding short description (Rules 1, 2, 3–5)

**Before** (486 chars, trigger-only, no short description):
```yaml
Use when the user asks to audit, recommend, fix, or generate the `allowed-tools`
frontmatter for a SKILL.md, or to review which tools/permissions Claude requested
during a Claude Code session. Triggers include "what allowed-tools should this skill
have", "fix skill permissions", "audit tool usage"... Does NOT score or audit general
SKILL.md quality — use reviewing-skills for that.
```

**After** (198 chars, three-part):
```yaml
Audits allowed-tools frontmatter for SKILL.md files. Fixes, generates, or reviews tool permissions for a skill or Claude Code session. Use when the user asks to check, fix, or review tool permissions for a skill.
```

**Body addition inserted before `## Mode 1: Static audit`:**
```markdown
## When not to use

Does not score or audit general SKILL.md quality — use reviewing-skills for that.
```

**What changed and why:**
- Added short description as Sentence 1 (Rule 2): "Audits allowed-tools frontmatter for SKILL.md files." (52 chars ≤80 ✓)
- Added capability as Sentence 2 (Rule 2): extracted from body Overview, compressed
- Dropped the `Triggers include "…"` list: 7 near-synonyms with no selectivity gain (Rule 5)
- Removed negative-scope clause from description → body (Rule 4)
- Retained the most discriminating trigger in Sentence 3
- Result: 486 → 198 chars, all three components present

---

## Worked example B — adding missing short description (Rule 2b)

**Before** (136 chars, two-part — REWRITE because short description is missing):
```yaml
Trims SKILL.md descriptions to ≤200 chars and tunes disable-model-invocation. Use when
the user asks to optimize SKILL.md frontmatter.
```

**After** (188 chars, three-part):
```yaml
Optimizes SKILL.md frontmatter fields. Rewrites descriptions to three-part format (≤200 chars) and tunes disable-model-invocation. Use when the user asks to optimize SKILL.md frontmatter.
```

**What changed and why:**
- Extracted short description from skill name + Overview: "Optimizes SKILL.md frontmatter fields." (38 chars ≤80 ✓)
- Existing capability sentence updated to reflect new format targets and kept as Sentence 2
- Trigger unchanged as Sentence 3: "Use when the user asks to optimize SKILL.md frontmatter."
- Result: 136 → 188 chars; all three components present (188 ≤200 ✓)

---

## Step 4 apply order

For each file marked REWRITE, make edits in this order:

**Edit A — Body insertion (if Rule 4 applies):**

Read the file, identify the insertion point, then use `Edit` with sufficient surrounding context as `old_string` to make the match unique. Add the `## When not to use` section.

**Edit B — Description rewrite:**

Use `Edit` with the full original `description: …` line as `old_string`. Preserve the original quoting style — if the original value was in double quotes, keep double quotes; if single-quoted, keep single quotes; if unquoted, keep unquoted.

Confirm each edit succeeded before moving to the next file. If the file has both edits, do body insertion first to avoid line-number drift.
