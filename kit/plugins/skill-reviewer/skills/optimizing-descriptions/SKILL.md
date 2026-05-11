---
name: optimizing-descriptions
description: Use when the user asks to optimize, trim, or shorten SKILL.md descriptions to ≤160 chars while preserving activation accuracy.
allowed-tools: AskUserQuestion, Read, Edit, Bash, Glob
---

## Overview

Rewrites `description:` frontmatter in SKILL.md files to ≤160 characters while preserving the triggers that drive accurate skill activation. Negative-scope clauses (“Does NOT cover X”) are relocated to a `## When not to use` body section (or an existing equivalent such as `## Scope` or `## Limitations`) rather than dropped.

**Why 160 chars?** Claude Code loads all skill descriptions into the context window each turn. The default `skillListingBudgetFraction` setting allocates 1% of the model’s context window for this listing — roughly 8,000 characters on a 200K-token model. With 50 skills installed (a realistic mix of plugin sets), that leaves ~160 chars per skill before descriptions start getting dropped. The platform hard limit is 1,024 chars per description and 1,536 chars per skill listing entry (description + `when_to_use` combined); 160 is a practical target for surviving the default budget, not a platform constraint.

Follow these steps exactly.

## When not to use

Does not review overall SKILL.md quality — use reviewing-skills for that. Does not change allowed-tools — use auditing-allowed-tools for that.

## Table of Contents

- [Step 1: Resolve target files](#step-1-resolve-target-files)
- [Step 2: Measure current descriptions](#step-2-measure-current-descriptions)
- [Step 3: Rewrite each description](#step-3-rewrite-each-description)
- [Step 4: Apply edits](#step-4-apply-edits)
- [Step 5: Verify results](#step-5-verify-results)

---

## Step 1: Resolve target files

Determine which SKILL.md files to optimize using this priority order:

1. **Explicit path** — user provided a path: use it directly.
2. **Plugin scope** — user named a plugin: use `Glob` for `**/plugins/<name>/skills/*/SKILL.md` from the current project directory. If no results, fall back to `kit/plugins/<name>/skills/*/SKILL.md`.
3. **All skills** — user said “all” or “everything”: use `Glob` for `**/skills/*/SKILL.md` from the current project directory. If no results, fall back to `kit/plugins/*/skills/*/SKILL.md`.
4. **Ask if still unclear** — “Which SKILL.md should I optimize? Provide a path or say ‘all’.”

---

## Step 2: Measure current descriptions

Extract the description value from each file’s YAML frontmatter and measure its length:

```bash
grep -n "^description:" <file> | head -1
```

Use only the **first match** — YAML frontmatter always appears before the body, so the first result is the frontmatter `description:`. Body lines (examples, worked output) may also contain `description:` and must be ignored.

Then count the value’s character length (excluding the `description:` prefix).

**Skip rule:** if a description is already ≤160 chars AND starts with “Use when” or leads with a capability verb, mark it SKIP — do not rewrite unless the user explicitly asks.

Report a table of files, current char count, and SKIP/REWRITE status before proceeding.

---

## Step 3: Rewrite each description

Apply all five rules in order. Do not proceed to edits until rewrites are drafted.

### Rule 1 — Target ≤160 characters

The description value (not including `description:` or surrounding quotes) must be ≤160 chars. Count carefully.

This is a budget target, not a platform limit. The platform enforces ≤1,024 chars per description. The 160-char target ensures descriptions survive the default `skillListingBudgetFraction` (1% of context window ≈ 8,000 chars total) for users with ~50 skills installed. If the user explicitly wants a higher target, use their stated limit instead — but note that descriptions over ~286 chars may be dropped for users who have installed only the agentics-kit (28 skills) and nothing else.

### Rule 2 — “Use when…” phrasing

Start with `Use when the user asks to…` (for reactive skills) or lead with the capability verb for proactive ones. Third-person voice throughout. No first-person (“I will”, “I can”).

### Rule 3 — Preserve the most discriminating trigger

If the current description lists 4+ triggers that are near-synonyms (“create”, “generate”, “scaffold”, “build”), collapse to the 1–2 most distinctive. Keep the trigger that uniquely distinguishes this skill from sibling skills in the same plugin.

Example collapse: “create an agent, generate an agent plugin, scaffold an agent, add an agent to a plugin, build a new agent, or make a sub-agent” → “create, scaffold, or generate an agent or sub-agent in a plugin”

### Rule 4 — Relocate negative-scope clauses

Any clause matching these patterns belongs in the body, not the description:

- “Does not cover X”
- “Does NOT do Y — use Z for that”
- “Not for stress-testing / validating / critiquing”
- “Use X-skill for that”

**Remove** the clause from the description. **Add** a `## When not to use` section to the body with the same information. If the body already has a `## Scope`, `## Limitations`, or equivalent section, add the content there instead of creating a duplicate section.

**Insertion point for new section:** after `## Overview` (if present), otherwise before `## Table of Contents`, otherwise before the first `## Step N` heading.

### Rule 5 — Strip filler

Remove:
- `"or says ‘…’"` example lists that restate the trigger phrase in natural language (the runtime already does fuzzy matching)
- Round-trip qualifiers (“in any capacity”, “for that”, “in one flow”)
- Implementation-detail sentences that describe what the skill does internally rather than what activates it (“Writes X, commits it, loops Y”) — keep these in the body intro, not the description

---

## Worked example

**Before** (486 chars):
```yaml
Use when the user asks to audit, recommend, fix, or generate the `allowed-tools`
frontmatter for a SKILL.md, or to review which tools/permissions Claude requested
during a Claude Code session. Triggers include "what allowed-tools should this skill
have", "fix skill permissions", "audit tool usage"... Does NOT score or audit general
SKILL.md quality — use reviewing-skills for that.
```

**After** (145 chars):
```yaml
Use when the user asks to audit, fix, or generate the `allowed-tools` frontmatter
for a SKILL.md, or review which tools Claude used in a session.
```

**Body addition inserted before `## Mode 1: Static audit`:**
```markdown
## When not to use

Does not score or audit general SKILL.md quality — use reviewing-skills for that.
```

**What changed and why:**
- Dropped the `Triggers include "…"` list: 7 near-synonyms added 200+ chars with no selectivity gain
- Removed negative-scope clause from description → body (Rule 4)
- Retained the two most discriminating triggers: `allowed-tools` frontmatter and session tool review
- Result: 486 → 145 chars, selectivity unchanged

---

## Step 4: Apply edits

For each file marked REWRITE, make edits in this order:

**Edit A — Body insertion (if Rule 4 applies):**

Read the file, identify the insertion point, then use `Edit` with sufficient surrounding context as `old_string` to make the match unique. Add the `## When not to use` section.

**Edit B — Description rewrite:**

Use `Edit` with the full original `description: …` line as `old_string`. Preserve the original quoting style — if the original value was in double quotes, keep double quotes; if single-quoted, keep single quotes; if unquoted, keep unquoted.

Confirm each edit succeeded before moving to the next file. If the file has both edits, do body insertion first to avoid line-number drift.

---

## Step 5: Verify results

After all edits, re-measure:

```bash
for f in <edited-files>; do
  line=$(grep "^description:" "$f" | head -1)
  val="${line#description: }"
  val="${val%\"}"
  val="${val#\"}"
  val="${val%\'}"
  val="${val#\'}"
  echo "${#val} $f"
done
```

Confirm every value ≤160. Report any that exceed the limit for a second rewrite pass.

---

### Budget advisory

After verification, count the total number of installed skills:

```bash
find . -name "SKILL.md" | wc -l
```

Then output this advisory to the user, substituting the actual count:

> **Skill listing budget check**
> You have N skills installed. Claude Code’s default `skillListingBudgetFraction` allocates 1% of the context window (~8,000 chars on a 200K-token model) for all skill descriptions combined.
>
> | Installed skills | Safe avg description length |
> |---|---|
> | ≤28 | ~286 chars |
> | ~50 | ~160 chars |
> | ~100 | ~80 chars |
>
> Run `/doctor` to see whether any descriptions are currently being truncated or dropped.
>
> If `/doctor` shows overflow, add this to your `.claude/settings.json`:
> ```json
> {
>   "skillListingBudgetFraction": 0.02
> }
> ```
> This doubles the budget to ~16,000 chars at a cost of ~2,000 tokens of context per turn.

Skip the advisory if the count is ≤28 and all descriptions are already ≤160 chars — no action is needed in that case.

**References:**
- Skill authoring best practices — https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
- Claude Code settings (`skillListingBudgetFraction`, `maxSkillDescriptionChars`) — https://code.claude.com/docs/en/settings
- Skill description budgets and `/doctor` command — https://code.claude.com/docs/en/skills
