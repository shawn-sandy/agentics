---
name: optimizing-skill-frontmatter
description: "Optimizes SKILL.md frontmatter fields. Rewrites descriptions to three-part format (≤200 chars) and tunes disable-model-invocation. Use when the user asks to optimize SKILL.md frontmatter."
allowed-tools: AskUserQuestion, Read, Edit, Bash, Glob, ToolSearch, ExitPlanMode
disable-model-invocation: true
---

## Overview

Optimizes two frontmatter fields in SKILL.md files in a single pass: rewrites `description:` to the **three-part format** (≤200 chars total, short description ≤80 chars) and sets `disable-model-invocation` to the correct value based on whether the skill is a write-heavy workflow or a read-only advisory tool.

The description rewrite targets the **three-part format**: a short description (≤80 chars) capturing the essential function, followed by a capability sentence with richer detail, followed by the "Use when…" trigger phrase — aligning with Anthropic's authoring checklist requirement that descriptions include both *what the skill does* and *when to use it* (Pattern 1 in `references/best-practices.md`).

**Why three-part format?** Claude Code loads all skill descriptions into the context window each turn. The default `skillListingBudgetFraction` allocates 1% of the model’s context window — roughly 8,000 characters on a 200K-token model. The three-part format is designed around this budget:

- **Short description ≤80 chars**: survives at ~100 skills installed (8,000 ÷ 100 = 80 chars/skill). Always the first sentence so truncation still leaves a meaningful label.
- **Total ≤200 chars**: fits the full three-part description for ~40 skills (8,000 ÷ 200 = 40). Users with the agentics-kit alone (~16 skills) have headroom to spare.
- **Legacy ≤160 target**: still safe for ~50 skills installed; remains the recommendation in the budget advisory table.

The platform hard limit is 1,024 chars per description and 1,536 chars per skill listing entry; 200 is a practical target for surviving the default budget, not a platform constraint.

**Why `disable-model-invocation`?** This flag controls how a skill activates. `true` forces explicit invocation only (via `/plugin:skill-name`); omitting it lets the model auto-fire the skill when user intent matches. Workflow skills that write files, commit code, or run pipelines should require explicit invocation — auto-firing a deploy on a loose intent match causes unintended side effects. Advisory/read-only skills benefit from auto-activation. Negative-scope clauses (“Does NOT cover X”) are relocated to a `## When not to use` body section rather than dropped.

Follow these steps exactly.

## When not to use

Does not review overall SKILL.md quality — use reviewing-skills for that. Does not change `allowed-tools` values — use auditing-allowed-tools for that. This skill only touches `description:` and `disable-model-invocation`.

## Table of Contents

- [Step 0: Exit plan mode, then discover project skills](#step-0-exit-plan-mode-then-discover-project-skills)
- [Step 1: Resolve target files](#step-1-resolve-target-files)
- [Step 2: Measure current descriptions](#step-2-measure-current-descriptions)
- [Step 3: Rewrite each description](#step-3-rewrite-each-description) (Rules 1, 2, 2b, 3, 4, 5)
- [Step 4: Apply edits](#step-4-apply-edits)
- [Step 4b: Tune invocation control](#step-4b-tune-invocation-control)
- [Step 5: Verify results](#step-5-verify-results)
- [Step 6: Offer to optimize the rest of the project](#step-6-offer-to-optimize-the-rest-of-the-project)

---

## Step 0: Exit plan mode, then discover project skills

`ExitPlanMode` is a deferred tool. **Only call it if currently in plan mode** — skip this step entirely when not in plan mode. When calling: use `ToolSearch` with `select:ExitPlanMode` first, then call `ExitPlanMode` silently.

Then enumerate all SKILL.md files in the current project:

```bash
find . -name "SKILL.md" | sort
```

If the command returns no results, fall back to `Glob` for `kit/plugins/*/skills/*/SKILL.md`. Store the full list as `$PROJECT_SKILLS` — it is used by Step 6's follow-up prompt.

Output one summary line: `Found N SKILL.md files in this project.`

---

## Step 1: Resolve target files

Determine which SKILL.md files to optimize using this priority order:

1. **Explicit path** — user provided a path: use it directly.
2. **Plugin scope** — user named a plugin: use `Glob` for `**/plugins/<name>/skills/*/SKILL.md` from the current project directory. If no results, fall back to `kit/plugins/<name>/skills/*/SKILL.md`.
3. **All skills** — user said “all” or “everything”: use `Glob` for `**/skills/*/SKILL.md` from the current project directory. If no results, fall back to `kit/plugins/*/skills/*/SKILL.md`.
4. **Ask if still unclear** — “Which SKILL.md should I optimize? Provide a path or say ‘all’.”

Targeting the resolved file(s) for this pass. The full project list from Step 0 is held for the follow-up prompt in Step 6.

---

## Step 2: Measure current descriptions

Extract the description value from each file’s YAML frontmatter and measure its length:

```bash
grep -n "^description:" <file> | head -1
```

Use only the **first match** — YAML frontmatter always appears before the body, so the first result is the frontmatter `description:`. Body lines (examples, worked output) may also contain `description:` and must be ignored.

Then count the value’s character length (excluding the `description:` prefix).

**Skip rule:** a file qualifies for SKIP only if it meets **all three** conditions: (1) total description ≤200 chars, (2) short description (first sentence) ≤80 chars, and (3) all three components present — a short description, a capability sentence, and a “Use when…” trigger phrase. A file is a REWRITE candidate if any condition fails: total >200, first sentence >80, missing short description, missing capability, or missing trigger. Do not exit silently. Instead:

1. Print a row showing: `{path} | {current chars} | {current description text}`
2. Call `AskUserQuestion` with three options:
   - **Rewrite anyway** — proceed to Step 3 for this file
   - **Keep as-is** — accept the current description and continue to the next file
   - **Skip all remaining** — stop processing and jump to Step 6

Report a table of all files, current char count, and SKIP/REWRITE status before calling `AskUserQuestion` for each SKIP candidate.

---

## Step 3: Rewrite each description

Apply all five rules in order. Do not proceed to edits until rewrites are drafted.

### Rule 1 — Target ≤200 chars total; short description ≤80 chars

The description value (not including `description:` or surrounding quotes) must be ≤200 chars total. The first sentence (short description, up to and including the first `. `) must be ≤80 chars. Count carefully — both limits apply independently.

These are budget targets, not platform limits. The platform enforces ≤1,024 chars per description. The 200-char total target fits the full three-part description for ~40 skills installed (8,000 ÷ 200 = 40). The 80-char short description survives at ~100 skills. If the user explicitly wants a higher total target, use their stated limit — but keep the short description ≤80 chars regardless, since it must survive aggressive truncation.

### Rule 2 — Three-part format

Target descriptions with three components in this order:

1. **Short description**: One sentence, ≤80 chars, third-person. The single most essential function in plain language — what the skill *is* at a glance. Distilled from the skill name and the first sentence of `## Overview`. Example: `”Optimizes SKILL.md frontmatter fields.”`
2. **Capability sentence**: Third-person verb phrase with richer detail — specific outputs, flags, or modes the skill handles. Example: `”Rewrites descriptions to three-part format (≤200 chars) and tunes disable-model-invocation.”`
3. **Trigger sentence**: `”Use when the user asks to [activation condition].”` Example: `”Use when the user asks to optimize SKILL.md frontmatter.”`

Fixed order: short description first, capability second, trigger last. Third-person voice throughout. No first-person (“I will”, “I can”).

If any component is missing, see Rule 2b.

### Rule 2b — Generate missing component(s)

Handle each missing component independently:

**Missing short description** (most common after this format change): extract the first sentence of the `## Overview` section and compress to ≤80 chars, third-person, present tense. Prepend as Sentence 1 before the existing capability and trigger.

**Missing capability** (description has only short description + trigger, or only trigger): extract the core action/output from `## Overview`. Compress to ≤120 chars, third-person. Insert as Sentence 2 between the short description and the trigger.

**Missing trigger** (no "Use when…" phrase): draft `"Use when the user asks to [condition]."` from the skill name and Overview. Append as the final sentence.

Do not add a second short description, a second capability, or a second trigger if any is already present.

When all three components together exceed 200 chars: shorten the capability sentence first, then the short description (keeping it ≤80 chars), then shorten the trigger only if the capability is already minimal.

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

### Rule 5 — Strip filler only

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

## Step 4: Apply edits

For each file marked REWRITE, make edits in this order:

**Edit A — Body insertion (if Rule 4 applies):**

Read the file, identify the insertion point, then use `Edit` with sufficient surrounding context as `old_string` to make the match unique. Add the `## When not to use` section.

**Edit B — Description rewrite:**

Use `Edit` with the full original `description: …` line as `old_string`. Preserve the original quoting style — if the original value was in double quotes, keep double quotes; if single-quoted, keep single quotes; if unquoted, keep unquoted.

Confirm each edit succeeded before moving to the next file. If the file has both edits, do body insertion first to avoid line-number drift.

---

## Step 4b: Tune invocation control

For each SKILL.md **resolved in Step 1** (not just files that were rewritten — files that were SKIP'd in Step 2 may still need invocation control tuned), classify it as **workflow** or **advisory** using two static signals:

| Signal | Strong workflow → `true` | Strong advisory → omit |
|---|---|---|
| `allowed-tools:` | Contains `Edit`, `Write`, or `Bash` with side-effect verbs | Only `Read`, `Glob`, `Grep`, `WebFetch`, `WebSearch`, `AskUserQuestion` |
| `description:` verbs | commit, push, PR, ship, branch, deploy, migrate, generate, scaffold, iterate, TDD-loop, "writes to" | review, audit, check, analyze, score, advise, report, recommend |
| Body signals | mentions `ExitPlanMode` Step 0; mentions writing/editing files | "report under N words"; no Edit/Write calls in any step |

**Confidence rules:**
- Both signals agree → **confident** recommendation; still confirm per policy below.
- Signals disagree or are mixed → **ambiguous**; surface both in the prompt.

**Never write `disable-model-invocation: false`.** The convention in this repo is: write `true` for workflow skills; omit the field entirely for advisory skills.

### Classification output

Print a compact table — one row per touched SKILL.md:

```
| Path | Current value | Recommendation | Confidence | Reason |
|------|---------------|----------------|------------|--------|
| kit/plugins/foo/skills/bar/SKILL.md | missing | omit (no change) | confident | read-only tools, advisory verbs |
| kit/plugins/foo/skills/baz/SKILL.md | missing | true | confident | Edit+Bash in allowed-tools, "generates" in description |
```

Show `true` / `missing` in the **Current value** column. Show `omit (no change)` when the current value already matches the recommendation.

### Confirmation

Call `AskUserQuestion` with three options:

- **Apply recommendations** — apply all non-trivial changes (skip `omit (no change)` rows)
- **Pick per file** — loop back through each changed row individually, ask per file
- **Skip invocation changes** — leave all files untouched; proceed to Step 5

### Apply rules (on confirmation)

**To set `true`:** first check for any existing `disable-model-invocation:` line (any value — including `false`). If one exists, delete it. Then insert `disable-model-invocation: true` on a new line immediately after the `allowed-tools:` line.

Step 1 — delete any existing `disable-model-invocation` line:
1. Extract the YAML frontmatter block first: read lines between the opening `---` (line 1) and the closing `---` (the next `---` after line 1). Run `Grep` for `^disable-model-invocation:` **only within that extracted range** — stop after the first frontmatter block so instruction examples in the body code blocks are not matched.
2. If found, use `Edit` with that exact matched line as `old_string` and `""` as `new_string`.

```
# Example — if grep returned: disable-model-invocation: false
old_string: "disable-model-invocation: false\n"
new_string: ""
```

Step 2 — insert after the `allowed-tools:` line:
1. Extract the YAML frontmatter block (lines between `---` delimiters as above). Run `Grep` for `^allowed-tools:` within that range to get the exact frontmatter line content.
2. Use `Edit` with that exact line as `old_string`, appending `disable-model-invocation: true` on the next line.

```
# Example — if grep returned: allowed-tools: AskUserQuestion, Read, Edit, Bash
old_string: "allowed-tools: AskUserQuestion, Read, Edit, Bash\n"
new_string: "allowed-tools: AskUserQuestion, Read, Edit, Bash\ndisable-model-invocation: true\n"
```

Never use placeholder values like `<value>` — always grep the file for the exact current content and use that as `old_string`.

**To remove an existing `true`:** delete the `disable-model-invocation: true` line entirely (do not replace with `false`). If an existing `false` is present, delete it too — never leave `false` in the file.

**Never write `disable-model-invocation: false`** — the omit-the-field convention must be preserved.

---

## Step 5: Verify results

After all edits, re-measure both total length and short description length:

```bash
for f in <edited-files>; do
  line=$(grep "^description:" "$f" | head -1)
  val="${line#description: }"
  val="${val%\"}"
  val="${val#\"}"
  val="${val%\'}"
  val="${val#\'}"
  # Total length
  total=${#val}
  # Short description: first sentence (up to and including the first ". ")
  short="${val%%. *}"
  short_len=${#short}
  echo "total=${total} short=${short_len} $f"
done
```

Confirm every `total` ≤200 and every `short` ≤80. Report any violations for a second rewrite pass. Flag separately: total-only violations (capability too long) vs. short-only violations (first sentence needs trimming).

---

## Step 6: Offer to optimize the rest of the project

After the targeted file(s) from Step 1 have been handled, re-measure every file from the `$PROJECT_SKILLS` list captured in Step 0:

```bash
for f in $PROJECT_SKILLS; do
  line=$(grep "^description:" "$f" | head -1)
  val="${line#description: }"
  val="${val%\"}"
  val="${val#\"}"
  val="${val%\'}"
  val="${val#\'}"
  echo "${#val} $f"
done
```

Print a table with columns `path | chars | status` where status is:
- `DONE` — already processed this session
- `REWRITE` — >200 chars
- `SKIP` — ≤200 chars and compliant phrasing

Then call `AskUserQuestion` with three options:
- **Optimize all over 200** — process every REWRITE file automatically using Steps 3–5
- **Pick specific files** — prompt for a selection, then loop back to Step 2 with the chosen subset
- **Stop here** — end the skill run and proceed to the Budget advisory

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
> | Installed skills | Safe avg description length | Format target |
> |---|---|---|
> | ≤40 | ~200 chars | Full three-part (short + capability + trigger) |
> | ~50 | ~160 chars | Two-part (capability + trigger) |
> | ~100 | ~80 chars | Short description only |
>
> The three-part format is designed so the short description (≤80 chars, always Sentence 1) survives even at ~100 skills — truncation never removes the label entirely.
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

Skip the advisory if the count is ≤40 and all descriptions are already ≤200 chars — no action is needed in that case.

**References:**
- Skill authoring best practices — https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
- Claude Code settings (`skillListingBudgetFraction`, `maxSkillDescriptionChars`) — https://code.claude.com/docs/en/settings
- Skill description budgets and `/doctor` command — https://code.claude.com/docs/en/skills
