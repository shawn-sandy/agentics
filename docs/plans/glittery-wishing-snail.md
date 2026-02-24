# Plan: Optimize plan-interview skill with TodoWrite

## Context

The `plan-interview` SKILL.md has two issues:

1. A YAML frontmatter parse error (multi-line description causes "Unexpected indentation" diagnostic)
2. No progress tracking — the skill's 6-step process runs without creating todos, making it easy to skip steps

The `writing-skills` guide mandates using `TodoWrite` to create todos for each checklist step. Adding this to the skill gives Claude a self-tracking mechanism through the interview process.

## Files to Modify

1. `plugins/plan-interview/skills/plan-interview/SKILL.md`
2. `plugins/plan-interview/commands/plan-interview.md`
3. `plugins/plan-interview/.claude-plugin/plugin.json`
4. `.claude-plugin/marketplace.json`
5. `plugins/plan-interview/CHANGELOG.md` (create if absent)

## Steps

### 1. Fix YAML frontmatter in `SKILL.md`

- Collapse multi-line `description` to a single line
- Before: two lines with indented continuation (triggers parse error at line 5)
- After: `description: Use when the user asks to stress-test, validate, critique, or find gaps and risks in an implementation plan.`

### 2. Add TodoWrite step to `SKILL.md`

Add a new **Step 0 — Create progress todos** at the top of the Instructions section, immediately before Step 1.

After Step 1 resolves the plan file, use `TodoWrite` to create todos for all remaining steps:

```markdown
- [ ] Step 2: Read and analyze the plan
- [ ] Step 3a: Round 1 — Technical & Trade-offs
- [ ] Step 3b: Round 2a — UI/UX & Flows (if applicable)
- [ ] Step 3c: Round 2b — Accessibility & Semantic (if applicable)
- [ ] Step 3d: Round 3 — Edge Cases & Best Practices (if applicable)
- [ ] Step 4: Surface out-of-scope concerns & complexity check
- [ ] Step 5: Compile and present review summary
- [ ] Step 6: Offer to save findings
```

Mark each todo complete (`status: "completed"`) as each step finishes.

### 3. Add `TodoWrite` to `allowed-tools` in command file

- File: `plugins/plan-interview/commands/plan-interview.md`
- Change: `allowed-tools: Read, Glob, AskUserQuestion, Write, Edit`
- To: `allowed-tools: Read, Glob, AskUserQuestion, Write, Edit, TodoWrite`

### 4. Add Step 0 to command file instructions

Mirror the Step 0 block from `SKILL.md` into `commands/plan-interview.md`, inserting it between `## Instructions` and `### Step 1`.

### 5. Bump plugin version (MINOR)

- Edit `plugins/plan-interview/.claude-plugin/plugin.json` — increment minor version
- Edit `.claude-plugin/marketplace.json` — set matching version for `plan-interview` entry
- Verify both match: `grep -r '"version"' plugins/plan-interview/.claude-plugin/ .claude-plugin/marketplace.json`

### 6. Add CHANGELOG entry

- File: `plugins/plan-interview/CHANGELOG.md`
- Add entry under new version heading: "Add TodoWrite progress tracking (Step 0) to both SKILL.md and command file"

## Verification

1. Load the plugin: `claude --plugin-dir ~/devbox/agentics/plugins/plan-interview`
2. Point at a plan file and run `/plan-interview:plan-interview`
3. Confirm todos appear in the task list after Step 1
4. Confirm each todo is marked complete as steps finish
5. Confirm no YAML diagnostic errors in SKILL.md
6. Confirm version in `plugin.json` matches `marketplace.json`

## Interview Summary

Interview conducted against this plan on 2026-02-24.

### Key Decisions Confirmed

- All 8 todos created upfront before Step 1 — simpler logic, inapplicable rounds marked N/A
- Single-line YAML `description` retained — safest across all parser implementations
- Step 0 (`TodoWrite`) belongs in **both** `SKILL.md` and `commands/plan-interview.md`

### Open Risks & Concerns

- **Command file gap**: Step 0 currently only exists in `SKILL.md`; command-invoked interviews won't create progress todos
- **Version not bumped**: Adding Step 0 is a backward-compatible new feature (MINOR bump required); `plugin.json` and `marketplace.json` must stay in sync per marketplace rules

### Recommended Next Steps

1. Add Step 0 to `commands/plan-interview.md` instructions (mirror what was added to `SKILL.md`)
2. Bump plugin version (MINOR) in both `plugin.json` and `marketplace.json`
3. Add a CHANGELOG entry for the new progress-tracking feature
