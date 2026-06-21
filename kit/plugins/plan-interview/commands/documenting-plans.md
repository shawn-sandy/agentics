---
description: Generate developer-friendly documentation at docs/<slug>.md from a completed plan file, synthesized from the plan body, live code inspection, and git history
argument-hint: "[plan-file-path] - omit to auto-detect from IDE or settings"
allowed-tools: Read, Glob, Grep, Bash(git *), AskUserQuestion, Write, Edit, TodoWrite, Skill
---

# Documenting Plans

Generate a developer-friendly prose document at `docs/<slug>.md` from a
completed plan file, reflecting what actually shipped.

## Instructions

Follow the steps in `skills/documenting-plans/SKILL.md` exactly:

### Step 0 — Create progress todos

Use `TodoWrite` to create todos for Steps 1–9 before doing any other work.

### Step 1 — Resolve plan file

Priority order: `$ARGUMENTS` path → IDE open `.md` file with plan headings →
settings `plansDirectory` (project-local `.claude/settings.local.json` → project
`.claude/settings.json` → global `~/.claude/settings.json`) → latest
`${PWD}/docs/plans/*.md`.

Announce: `"Documenting plan: path/to/plan.md"`

### Step 2 — Ensure plan is completed

Read frontmatter. If `status: completed`, continue. Otherwise invoke
`plan-interview:plan-status` via the `Skill` tool with the resolved plan path.
Re-read frontmatter after it completes — if still not `completed`, stop with
an informative message.

### Step 3 — Parse plan content

Extract: H1 title, frontmatter fields (`created`, `modified`, `status`,
`type`), body sections (Context, Objective, Steps with *Why:*, Files to
Create/Modify), and inline backtick tokens (file paths + named identifiers —
skip fenced code blocks).

### Step 4 — Derive output slug

Slug = plan filename without `.md`, verbatim. Confirm with `AskUserQuestion`
("Generated doc will be written to `docs/<slug>.md`. Accept, or rename?").

### Step 5 — Inspect shipped files

For each token: `Glob` for existence → `Grep` basename if not found →
`Read` first ~150 lines to capture public surface. Build index
`{planned_path, actual_path, status, kind, exported_surface}`.

### Step 6 — Collect git history

```bash
git log --since=<created> --until=<modified-or-today> \
  --format="%h %ad %s" --date=short \
  -- <plan-file> <indexed-files...>
```

Cap at 20 commits. Also collect the shipped date:
`git log -1 --format="%cd" --date=short -- <plan-file>`

### Step 7 — Check target doc

If `docs/<slug>.md` exists, `AskUserQuestion` → Overwrite / Refresh / Cancel.
Refresh mode regenerates only content between `<!-- generated:start -->` and
`<!-- generated:end -->` markers.

### Step 8 — Synthesize and write

Write `docs/<slug>.md` using the template defined in the skill. Compute the
plan link as a relative path from the output doc to the resolved plan file.
Cite the plugin CHANGELOG entry rather than reproducing it verbatim.

### Step 9 — Report

Output a summary table: output path, plan link, shipped date, files indexed
count, commits in window.

---

Arguments: $ARGUMENTS

## Examples

```
/plan-interview:documenting-plans                                              # auto-detects from IDE or settings
/plan-interview:documenting-plans docs/plans/add-branch-agent-skill.md        # specific plan file
/plan-interview:documenting-plans ~/.claude/plans/my-feature.md               # absolute path
```
