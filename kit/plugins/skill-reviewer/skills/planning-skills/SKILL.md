---
name: planning-skills
description: "Scaffolds a new skill with SKILL.md and supporting files. Walks a structured workflow covering frontmatter, body, references, and scripts. Use when the user asks to plan or scaffold a new skill."
allowed-tools: AskUserQuestion, Read, TodoWrite, Write
---

## Overview

Walks users through a structured workflow to plan and generate a complete Claude Code skill. Produces a ready-to-use skill folder with SKILL.md, optional reference files, and optional scripts.

Follow these steps exactly.

## When not to use

Does not review or audit existing skills — use reviewing-skills for that.

## Table of Contents

- [Step 0: Create Progress Todos](#step-0-create-progress-todos)
- [Step 1: Understand the Skill Goal](#step-1-understand-the-skill-goal)
- [Step 2: Select a Design Pattern](#step-2-select-a-design-pattern)
- [Step 3: Plan the Folder Structure](#step-3-plan-the-folder-structure)
- [Step 4: Draft the YAML Frontmatter](#step-4-draft-the-yaml-frontmatter)
- [Step 5: Outline the SKILL.md Body](#step-5-outline-the-skillmd-body)
- [Step 6: Generate the Skill Files](#step-6-generate-the-skill-files)

---

## Step 0: Create Progress Todos

Before doing any other work, use `TodoWrite` to create todos for each step of this workflow. This gives the user visibility into progress.

Create the following todos (all starting with `status: "pending"`):

- Step 1: Understand the skill goal
- Step 2: Select a design pattern
- Step 3: Plan the folder structure
- Step 4: Draft the YAML frontmatter
- Step 5: Outline the SKILL.md body
- Step 6: Generate the skill files

Mark each todo `status: "completed"` as you finish that step.

---

## Step 1: Understand the Skill Goal

Ask the user up to 4 questions using `AskUserQuestion` to understand what they want to build. Tailor questions to what the user has already provided — skip questions they have already answered. If the user's initial message already covers purpose, triggers, tools, and expected output, skip directly to the concept summary without asking questions.

**Questions to consider (pick the most relevant):**

1. **What does the skill do?** — "What task or workflow should this skill handle?"
2. **Who triggers it?** — "What would a user say to activate this skill?" (helps draft trigger phrases)
3. **What tools or services does it use?** — "Does the skill need to call APIs, run scripts, read files, or use MCP tools?"
4. **What is the output?** — "What does the user receive when the skill finishes? (report, generated file, modified code, conversation guidance)"

After gathering answers, summarize the skill concept:

```
**Skill concept:**
- Purpose: [what it does]
- Trigger: [when it activates]
- Tools/services: [what it uses]
- Output: [what the user gets]
```

---

## Step 2: Select a Design Pattern

Based on the skill concept from Step 1, recommend a design pattern. Present the options using `AskUserQuestion` with descriptions from `references/design-patterns.md`.

If the skill concept clearly fits one pattern, recommend it as the first option with "(Recommended)" in the label. If ambiguous, present 2–3 patterns and let the user choose.

After selection, confirm:

```
**Design pattern:** [Pattern name]
**Why:** [One sentence explaining the fit]
```

---

## Step 3: Plan the Folder Structure

Based on the skill concept and design pattern, determine what the skill folder needs.

**Always include:**
- `SKILL.md` — core instructions

**Include `references/` when:**
- The skill has detailed criteria, checklists, or lookup tables
- The SKILL.md body would exceed 3,000 words without offloading
- The skill references external documentation or standards

**Include `scripts/` when:**
- The skill needs to run executable code (Python, Bash)
- The skill generates files, reports, or visual output
- The skill automates a process that goes beyond Claude's built-in tools

**Include `assets/` when:**
- The skill uses templates or configuration samples
- The skill generates output from a template

Present the proposed structure to the user:

```
my-skill/
├── SKILL.md
├── references/
│   └── [planned-reference-files]
└── scripts/
    └── [planned-scripts]
```

Ask if they want to adjust the structure before proceeding.

---

## Step 4: Draft the YAML Frontmatter

Generate the `name` and `description` fields following these rules:

**Name rules:**
- Lowercase letters, numbers, hyphens only
- ≤64 characters
- Must not contain `anthropic` or `claude` as substring
- Prefer gerund form (`reviewing-code`) over imperative (`review-code`)
- Use kebab-case matching the folder name

**Description rules:**
- ≤1,024 characters
- Third person (no "I", "you", "we", "your")
- Must contain "Use when..." trigger phrase
- Include ≥3 searchable keywords
- Add scope exclusion (what the skill does NOT handle)
- No XML tags, no newlines

Present the drafted frontmatter:

```yaml
---
name: [generated-name]
description: [generated-description]
---
```

Ask the user to confirm or adjust before proceeding.

---

## Step 5: Outline the SKILL.md Body

Generate a body outline based on the design pattern selected in Step 2. Each pattern has a recommended structure — see `references/design-patterns.md` for details.

**All patterns include:**
- Overview section (1–2 sentences + freedom level)
- Table of Contents (if the outline suggests ≥100 lines)
- Numbered steps or clearly separated sections

**Body quality targets:**
- <400 lines, <3,000 words in the main SKILL.md
- Imperative voice ("Read the file", not "You should read")
- At least one concrete example or code block
- No time-sensitive content

If the outline suggests the body will exceed 3,000 words, recommend creating a reference file for the most detailed section before proceeding. If the skill serves two distinct user intents, recommend a Skill Pack (multiple skills in one plugin) instead of a single oversized skill.

Present the outline as a numbered list of sections with brief descriptions:

```
1. ## Overview — What the skill does, freedom level
2. ## Step 1 — [First action]
3. ## Step 2 — [Second action]
...
```

Ask the user to confirm or adjust the outline.

---

## Step 6: Generate the Skill Files

After the user confirms the outline, generate the complete skill files on disk.

**Generation order:**

1. Create the skill folder (kebab-case name)
2. Write `SKILL.md` with:
   - Confirmed frontmatter from Step 4
   - Full body content following the outline from Step 5
   - Concrete examples where the outline calls for them
3. Write reference files (if planned in Step 3)
4. Write script files (if planned in Step 3)
5. Write asset files (if planned in Step 3)

**Before writing, confirm the target directory:**

> "I'll create the skill at `[path]/[skill-name]/`. Should I proceed?"

If the user declines or wants a different location, ask: "Where would you like me to create the skill folder? Please provide the path."

**After generation, present a summary:**

```
## Skill Generated

**Location:** `[path]/[skill-name]/`
**Files created:**
- `SKILL.md` ([line count] lines, [word count] words)
- `references/[file]` (if any)
- `scripts/[file]` (if any)

**Next steps:**
1. Review the generated SKILL.md and adjust as needed
2. Test activation by asking Claude something that matches the trigger phrase
3. Run the `reviewing-skills` skill to audit quality
```
