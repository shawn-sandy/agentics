---
status: completed
type: standard
created: 2026-03-26
---

# Plan: Add `allowed-tools` Recommendation Capability to plan-interview

## Context

The plan-interview plugin reviews plans but cannot currently analyze Claude Code skill files or recommend `allowed-tools` for them. Skills work better when their frontmatter explicitly declares the tools they invoke — it improves security, auditability, and discoverability. This plan extends both the skill and command to:

1. Accept `SKILL.md` files as valid review targets (not just plan files)
2. Analyze skill instruction bodies to detect tool references
3. Recommend `allowed-tools` additions to the reviewed skill's frontmatter
4. Add `allowed-tools` to the plan-interview skill's own frontmatter (currently missing)

---

## Files to Modify

1. `plugins/plan-interview/skills/plan-interview/SKILL.md`
2. `plugins/plan-interview/commands/plan-interview.md`
3. `.claude-plugin/marketplace.json` — bump `plan-interview` version `1.6.0` → `1.7.0`
4. `plugins/plan-interview/CHANGELOG.md` — add v1.7.0 entry

---

## Changes

### 1. `SKILL.md` — Add `allowed-tools` frontmatter

Add `allowed-tools` listing every tool the skill already uses:

```yaml
---
name: plan-interview
description:
  Use when the user asks to stress-test, validate, critique, or find gaps and
  risks in an implementation plan.
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, Write, Edit, TodoWrite
---
```

(`Grep` is used in Step 4.5 deep grill; `Bash` is used for `mv` rename in Step 2.)

---

### 2. Both files — Extend Step 1 to detect `SKILL.md` input

After resolving the target file, add a skill-detection check before proceeding to Step 2:

**A skill file is detected when:**
- The filename is `SKILL.md`, **or**
- The file contains YAML frontmatter with both `name:` and `description:` fields but no plan-style headings (`## Implementation`, `## Plan`, `## Steps`, `## Context`)

When a skill file is detected:
- Set internal mode = `skill-review`
- Skip Step 2's plan name validation (not applicable to skill files)
- Announce: _"Reviewing skill: `path/to/SKILL.md`"_
- Proceed directly to Step 2.5

---

### 3. Both files — Add Step 2.5: Skill Tool Analysis _(runs only in `skill-review` mode)_

Insert after Step 2, before Step 3.

**Instructions:**

1. **Parse existing `allowed-tools`**: Extract the current `allowed-tools` value from the skill's YAML frontmatter. If absent, treat as empty.

2. **Scan for tool references**: Search the skill body for any of the following known Claude tool names (match as whole words or in backticks):

   ```
   Read, Write, Edit, MultiEdit, Glob, Grep, Bash, AskUserQuestion,
   TodoWrite, Agent, WebFetch, WebSearch, NotebookRead, NotebookEdit
   ```

   Also detect filtered tool patterns such as `Bash(git *)` or `Bash(gh *)`.

3. **Classify each detected tool** as one of:
   - **Declared** — already in `allowed-tools`
   - **Missing** — detected in instructions but absent from `allowed-tools`
   - **Undeclared** — in `allowed-tools` but not detected in instructions (flag for review, not removal)

4. **Present the analysis table:**

   ```markdown
   ### Skill Tool Analysis

   | Status    | Tool         | Detected In                          |
   |-----------|--------------|--------------------------------------|
   | Declared  | Read         | Step 1 — reading skill file          |
   | Missing   | Grep         | Step 4.5 — deep grill codebase search|
   | Undeclared| Write        | Listed in allowed-tools, not detected|
   ```

5. **Output a suggested `allowed-tools` line** covering all detected tools, sorted alphabetically:

   ```markdown
   **Suggested frontmatter:**

   ```yaml
   allowed-tools: AskUserQuestion, Bash, Edit, Glob, Grep, Read, TodoWrite
   ```
   ```

---

### 4. Both files — Update Step 5 summary template

Add an `Allowed Tools Recommendation` section to the summary output, shown only in `skill-review` mode:

```markdown
### Allowed Tools Recommendation

[Reproduce the tool analysis table from Step 2.5, including the suggested
`allowed-tools` frontmatter line. Omit this section entirely when reviewing
a plan file, not a skill file.]
```

---

### 5. Both files — Update Step 6 save offer

When in `skill-review` mode and the user confirms saving, also offer to apply the `allowed-tools` update:

> "Would you like me to also update the `allowed-tools` frontmatter in the skill file?"

If confirmed, use `Edit` to add or replace the `allowed-tools` line in the YAML frontmatter.

---

### 6. `plan-interview.md` command — Update `allowed-tools` frontmatter

The command is missing `Grep` (used in deep grill). Update frontmatter:

```yaml
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, Write, Edit, TodoWrite
```

---

### 7. Version and changelog

- Bump `plan-interview` in `.claude-plugin/marketplace.json`: `1.6.0` → `1.7.0` (MINOR — new capability)
- Add CHANGELOG entry:
  ```
  ## [1.7.0] — 2026-03-26
  ### Added
  - SKILL.md files accepted as review targets (not just plan files)
  - Step 2.5: Skill Tool Analysis detects tool references and recommends `allowed-tools`
  - `allowed-tools` frontmatter added to the plan-interview SKILL.md itself
  - Step 6 offers to apply `allowed-tools` updates directly to reviewed skill files
  ```

---

## Verification

1. Load the plugin: `claude --plugin-dir ~/devbox/agentics/plugins/plan-interview`
2. Open `SKILL.md` in IDE, then trigger the skill → confirm it detects the file as a skill, not a plan
3. Verify Step 2.5 table appears with correct tool classifications
4. Confirm the suggested `allowed-tools` line is accurate
5. Accept the Step 6 save offer → confirm `allowed-tools` is written to frontmatter
6. Run with a normal plan file → confirm Step 2.5 is silently skipped

---

## Next Steps _(out of scope)_

- Add `allowed-tools` recommendation to the `plan-hygiene` and `review-rename-plans` commands
- Add a dedicated "skill review mode" with skill-specific interview rounds (activation criteria quality, edge cases for intent-matching)
- Auto-detect agent files (`.md` with `agent` in path) and add tool analysis there too
