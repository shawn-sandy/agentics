# Plan: Extract Deep Grill into Standalone Skill

## Context

The deep grill (Step 4 in plan-interview SKILL.md) is currently embedded in the
plan-interview workflow. Users can only access it as an optional step during a
full plan interview. Extracting it into a standalone skill lets users invoke a
deep grill session at any time — independently of the broader interview — making
it more accessible and reusable.

## Changes

### 1. Create `skills/deep-grill/SKILL.md`

New file at `plugins/plan-interview/skills/deep-grill/SKILL.md`.

- **Frontmatter:** `name: deep-grill`, description triggers on "deep grill",
  "walk through decisions", "examine each branch"
- **allowed-tools:** `Read, Glob, Grep, AskUserQuestion, TodoWrite` (read-only —
  no Write/Edit since it doesn't modify the plan)
- **Step 0:** Create progress todos (standard pattern)
- **Step 1:** Resolve plan file (same priority algorithm as plan-status/plan-interview)
- **Step 2:** Read plan and build design tree — identify decision nodes, present
  branch outline, ask user whether to grill all or select specific branches
- **Step 3:** Walk branches — core deep-grill logic (from current Step 4 lines
  334-346), one branch at a time, with focused questions, recommended answers,
  and codebase exploration via Glob/Grep/Read
- **Step 4:** Present deep grill summary (branches examined, decisions resolved,
  open questions, recommendations)

### 2. Create `commands/deep-grill.md`

New file at `plugins/plan-interview/commands/deep-grill.md`.

- Mirrors the skill with `$ARGUMENTS` for file path input
- Enables explicit invocation: `/plan-interview:deep-grill [path]`

### 3. Modify `skills/plan-interview/SKILL.md`

Remove deep grill and renumber steps:

- **TOC (line 21):** Remove `Step 4 — Deep grill` entry
- **Step 0 todos (line 42):** Remove `Step 4: Deep grill session` todo
- **Lines 322-346:** Replace entire Step 4 section with a callout directing
  users to the standalone `deep-grill` skill
- **Renumber:** Step 5 -> Step 4, Step 6 -> Step 5, Step 7 -> Step 6
- **Line 157:** Update `Steps 4-7 (especially Step 7's save operation)` to
  `Steps 4-6 (especially Step 6's save operation)`
- **Line 444:** Update `Step 6 summary` to `Step 5 summary`
- **Lines 409-411:** Remove `### Deep Grill Findings` subsection from the
  summary template in Step 5 (was Step 6)

### 4. Update `README.md`

- Add `deep-grill` command and skill rows to the Components table
- Add "Deep Grill" usage section with example invocations
- Add deep-grill activation phrases to skill activation examples
- Update the interview description (line 131) to reference standalone skill

### 5. Update `CHANGELOG.md`

Add `[1.10.0] - 2026-03-28` entry documenting:

- Added: `deep-grill` skill and command
- Changed: deep grill removed from plan-interview, steps renumbered

### 6. Bump version in `marketplace.json`

Update `plan-interview` version from `1.9.1` to `1.10.0` (MINOR — new skill
added, backward compatible).

## Files

| File | Action |
|------|--------|
| `plugins/plan-interview/skills/deep-grill/SKILL.md` | Create |
| `plugins/plan-interview/commands/deep-grill.md` | Create |
| `plugins/plan-interview/skills/plan-interview/SKILL.md` | Edit |
| `plugins/plan-interview/README.md` | Edit |
| `plugins/plan-interview/CHANGELOG.md` | Edit |
| `.claude-plugin/marketplace.json` | Edit |

## Verification

1. Load the plugin: `claude --plugin-dir ./plugins/plan-interview`
2. Test standalone deep grill: say "deep grill this plan" with a plan file open
3. Test explicit command: `/plan-interview:deep-grill docs/plans/some-plan.md`
4. Test plan-interview without deep grill: run `/plan-interview:plan-interview`
   and confirm Step 4 is now "Surface out-of-scope concerns" with no deep grill
   prompt
5. Verify step numbering consistency in plan-interview SKILL.md (no orphaned
   references to old step numbers)

## Next Steps

- Consider extracting the shared plan resolution algorithm (Step 1) into a
  reusable include if Claude Code adds support for skill imports — currently
  duplicated across three skills
- Add a `deep-grill` tag to the marketplace entry if searchability is a concern
