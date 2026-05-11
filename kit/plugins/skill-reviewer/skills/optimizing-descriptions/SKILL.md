---
name: optimizing-descriptions
description: Use when the user asks to optimize, trim, or shorten SKILL.md descriptions to ≤160 chars while preserving activation accuracy.
allowed-tools: AskUserQuestion, Read, Edit, Bash, Glob
---

## Overview

Rewrites `description:` frontmatter in SKILL.md files to ≤160 characters while preserving the triggers that drive accurate skill activation. Negative-scope clauses ("Does NOT cover X") are relocated to a `## When not to use` body section rather than dropped.

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
2. **Plugin scope** — user named a plugin: glob `kit/plugins/<name>/skills/*/SKILL.md`.
3. **All skills** — user said "all" or "everything": glob `kit/plugins/*/skills/*/SKILL.md`.
4. **Ask if still unclear** — "Which SKILL.md should I optimize? Provide a path or say 'all'."

---

## Step 2: Measure current descriptions

Extract the description value from each file's YAML frontmatter and measure its length:

```bash
grep -n "^description:" <file>
```

Then count the value's character length (excluding the `description: ` prefix).

**Skip rule:** if a description is already ≤160 chars AND starts with "Use when" or leads with a capability verb, mark it SKIP — do not rewrite unless the user explicitly asks.

Report a table of files, current char count, and SKIP/REWRITE status before proceeding.

---

## Step 3: Rewrite each description

Apply all five rules in order. Do not proceed to edits until rewrites are drafted.

### Rule 1 — Target ≤160 characters

The description value (not including `description: ` or surrounding quotes) must be ≤160 chars. Count carefully; the ≤160 limit is strict.

### Rule 2 — "Use when…" phrasing

Start with `Use when the user asks to…` (for reactive skills) or lead with the capability verb for proactive ones. Third-person voice throughout. No first-person ("I will", "I can").

### Rule 3 — Preserve the most discriminating trigger

If the current description lists 4+ triggers that are near-synonyms ("create", "generate", "scaffold", "build"), collapse to the 1–2 most distinctive. Keep the trigger that uniquely distinguishes this skill from sibling skills in the same plugin.

Example collapse: "create an agent, generate an agent plugin, scaffold an agent, add an agent to a plugin, build a new agent, or make a sub-agent" → "create, scaffold, or generate an agent or sub-agent in a plugin"

### Rule 4 — Relocate negative-scope clauses

Any clause matching these patterns belongs in the body, not the description:

- "Does not cover X"
- "Does NOT do Y — use Z for that"
- "Not for stress-testing / validating / critiquing"
- "Use X-skill for that"

**Remove** the clause from the description. **Add** a `## When not to use` section to the body with the same information. If the body already has a `## Scope`, `## Limitations`, or equivalent section, add the content there instead of creating a duplicate section.

**Insertion point for new section:** after `## Overview` (if present), otherwise before `## Table of Contents`, otherwise before the first `## Step N` heading.

### Rule 5 — Strip filler

Remove:
- `"or says '…'"` example lists that restate the trigger phrase in natural language (the runtime already does fuzzy matching)
- Round-trip qualifiers ("in any capacity", "for that", "in one flow")
- Implementation-detail sentences that describe what the skill does internally rather than what activates it ("Writes X, commits it, loops Y") — keep these in the body intro, not the description

---

## Worked example

**Before** (486 chars):
```
Use when the user asks to audit, recommend, fix, or generate the `allowed-tools`
frontmatter for a SKILL.md, or to review which tools/permissions Claude requested
during a Claude Code session. Triggers include "what allowed-tools should this skill
have", "fix skill permissions", "audit tool usage"... Does NOT score or audit general
SKILL.md quality — use reviewing-skills for that.
```

**After** (145 chars):
```
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

Use `Edit` with the full original `description: …` line as `old_string`. Preserve the original quoting style — if the original value was in double quotes, keep double quotes; if unquoted, keep unquoted.

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
  echo "${#val} $f"
done
```

Confirm every value ≤160. Report any that exceed the limit for a second rewrite pass.

**Reference:** Anthropic skill authoring best practices — https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
