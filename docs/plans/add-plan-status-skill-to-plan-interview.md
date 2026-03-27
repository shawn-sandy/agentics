# Plan: Add `plan-status` Skill to plan-interview Plugin

## Context

Plan files accumulate over time with no indication of whether they were ever
implemented. This skill closes that gap by inspecting the codebase for
implementation evidence, determining a plan's lifecycle status, and writing
that status into the plan file's YAML frontmatter for future reference.

---

## Summary

Add a new `plan-status` skill (+ paired command) to the `plan-interview` plugin.
When triggered, the skill checks whether a plan has been implemented, assigns a
status label, and updates the plan file's YAML frontmatter with `status`,
`created`, and `modified` fields.

**Status values:** `todo` · `in-progress` · `completed` · `artifact`

---

## Files to Create

1. `plugins/plan-interview/skills/plan-status/SKILL.md` — skill definition
2. `plugins/plan-interview/commands/plan-status.md` — paired command (invoked via `/plan-interview:plan-status`)

## Files to Modify

1. `plugins/plan-interview/CHANGELOG.md` — add v1.8.0 entry
2. `plugins/plan-interview/README.md` — document new skill/command
3. `.claude-plugin/marketplace.json` — bump version `1.7.0` → `1.8.0`

---

## Implementation Steps

### 1. Create `skills/plan-status/SKILL.md`

Frontmatter:

```yaml
---
name: plan-status
description: Use when the user asks to check, update, or determine the status of a plan file.
---
```

Skill instructions (steps):

#### Step 0 — Create progress todos

Create todos for: resolve file, get dates, analyze codebase, determine status,
confirm with user, update frontmatter.

#### Step 1 — Resolve plan file

Same resolution order as `plan-interview` skill:

1. File path in user message
2. Currently open `.md` file in IDE (if it looks like a plan)
3. `plansDirectory` from `.claude/settings.json`
4. `plansDirectory` from `~/.claude/settings.json`
5. Most recently modified file in `~/.claude/plans/`

If no file found, tell user and stop.

#### Step 2 — Get file dates

Created date (first in order that succeeds):

1. `git log --follow --diff-filter=A --format="%Y-%m-%d" -- <file> | tail -1`
2. Current date as fallback (skip `stat` — not cross-platform)

Modified date:

1. `git log -1 --format="%Y-%m-%d" -- <file>`
2. Omit if same as created date or if no git history

#### Step 3 — Read existing frontmatter

Parse YAML frontmatter if present. If a `status` field already exists, surface
it to the user and ask if they want to re-analyze or just confirm the existing
status.

#### Step 4 — Analyze codebase for implementation evidence

Extract **inline backtick tokens only** from the plan body (exclude fenced code
block content). Look for:

- File paths (e.g. `` `src/components/Foo.tsx` ``, `` `plugins/bar/SKILL.md` ``)
- Function/class/component names
- Feature names, command names, skill names

If no inline backtick tokens are found, skip codebase analysis and prompt the
user to set the status manually via `AskUserQuestion`.

For each extracted token:

- Use `Glob` to check if it matches an existing file path
- Use `Grep` to check if it appears as a name in the codebase

Score:

- 0% found → `todo`
- 1–79% found → `in-progress`
- 80%+ found → `completed`

#### Step 5 — Artifact check _(only when status resolves to `completed`)_

Compute days since the `modified` date (proxy for completion date). If ≥ 30
days, ask the user via `AskUserQuestion`:

> "This plan appears to have been completed 30+ days ago. Would you like to
> mark it as `artifact` (preserved as valuable project documentation) rather
> than `completed`?"

- If user confirms → status = `artifact`
- If user declines → status stays `completed`

#### Step 6 — Present findings and confirm

Output a summary table:

```text
| Field    | Value                          |
|----------|--------------------------------|
| File     | docs/plans/my-feature.md       |
| Status   | in-progress                    |
| Created  | 2026-01-15                     |
| Modified | 2026-03-26                     |
| Evidence | 3/5 items found in codebase    |
```

List what was found and what was not found.

Ask user: "Should I update the plan file's YAML frontmatter with this status?"

Do NOT write to the file unless user confirms.

#### Step 7 — Update plan file frontmatter

Only on user confirmation. Add or update YAML frontmatter at the top of the
file:

```yaml
---
status: in-progress
created: 2026-01-15
modified: 2026-03-26
---
```

Rules:

- If frontmatter already exists: update/add only `status`, `created`,
  `modified` — preserve all other fields untouched
- If no frontmatter: insert a new block at the very top of the file
- Omit `modified` if same as `created`
- Use `Edit` tool for the update

---

### 2. Create `commands/plan-status.md`

Frontmatter:

```yaml
---
description: Check and update the lifecycle status of a plan file (todo, in-progress, completed, artifact)
argument-hint: "[plan-file-path] - omit to auto-detect from IDE or settings"
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, Edit, TodoWrite
---
```

Body: Full step-by-step instructions mirroring the skill steps above (Steps 0–7),
written out explicitly. Do not reference the skill — the command file must be
self-contained.

---

### 3. Update `CHANGELOG.md`

Add at top:

```markdown
## [1.8.0] - 2026-03-26

### Added

- New `plan-status` skill and command — determines plan lifecycle status
  (todo, in-progress, completed, artifact) by inspecting the codebase for
  implementation evidence, then writes status + dates to plan YAML frontmatter
```

### 4. Update `README.md`

Add a new entry under the Skills section documenting:

- Skill name and activation trigger
- Command invocation: `/plan-interview:plan-status [path]`
- Status values and what each means
- Example output

### 5. Bump `marketplace.json`

Change `"version": "1.7.0"` → `"version": "1.8.0"` for the `plan-interview`
entry in `.claude-plugin/marketplace.json`.

---

## Verification

1. Load the plugin: `claude --plugin-dir ~/devbox/agentics/plugins/plan-interview`
2. Open a plan file in IDE, then invoke: `/plan-interview:plan-status`
3. Verify skill auto-activates: say "check the status of this plan"
4. Confirm YAML frontmatter is written correctly to the plan file
5. Test with a plan whose codebase items don't exist (expect `todo`)
6. Test with a completed plan dated 30+ days ago (expect artifact prompt)

---

## Next Steps

- Add a `--force` flag to skip the user confirmation and always overwrite status
- Surface plan status in `plan-hygiene` output (show status column alongside filenames)
- Add batch mode: scan a directory and update status on all plan files at once
- Consider a hook that auto-runs `plan-status` when a plan file is opened in the IDE

---

## Interview Summary

### Key Decisions Confirmed

- **Signal extraction**: Inline backtick tokens only (`` `token` ``) — fenced code block content excluded
- **Completion threshold**: 80%+ signals found = `completed`; 1–79% = `in-progress`; 0% = `todo`
- **Date strategy**: Git-first only; skip `stat` entirely; fall back to current date if file not git-tracked
- **Frontmatter conflicts**: Add `status`, `created`, `modified` only — never rename or remove existing fields

### Open Risks & Concerns

1. **Fenced code blocks produce false signals** — extraction must be scoped to inline backticks only (addressed in updated plan)
2. **Zero-signal edge case unhandled** — pure-prose plans produce no extractable signals; fallback added (manual status prompt)
3. **Artifact threshold uses wrong anchor date** — fixed: now uses `modified` date instead of `created`
4. **README not in scope** — added to files to modify
5. **Command body underspecified** — clarified: command file must contain full self-contained instructions

### Recommended Next Steps

Plan has been updated to address all five concerns above. Ready for implementation.
