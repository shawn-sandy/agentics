---
name: documenting-plans
description: "Generates a prose reference doc from a completed plan. Inspects the codebase and git history to produce accurate, evidence-backed documentation. Use when the user asks to document a completed plan."
allowed-tools: Read, Glob, Grep, Bash(git *), AskUserQuestion, Write, Edit, TodoWrite, Skill
argument-hint: "[plan-file-path] - omit to auto-detect from IDE or settings"
disable-model-invocation: true
---

# Documenting Plans

Generate a developer-friendly prose document at `docs/<slug>.md` from a
completed plan file, reflecting what actually shipped by inspecting the codebase
and git history.

Follow these steps exactly.

## When not to use

Only runs on completed plans that are 30+ days old (based on `created` or
`modified` date in frontmatter). Use plan-status to set status before running.
Use review-plan or the built-in interview to stress-test the plan first.

## References

- `references/resolve-and-preconditions.md` — Steps 0–2: progress todos, the plan-file resolution priority order, the completed-and-30-days-old gate
- `references/gather-evidence.md` — Steps 3–7: plan parsing, output slug, shipped-file inspection, git history, target-doc collision
- `references/doc-template.md` — Steps 8–9: the full document template and the closing report table

---

## Instructions

### Step 0 — Create progress todos

Use `TodoWrite` to create one todo per step, listed in
`references/resolve-and-preconditions.md`. Mark each completed as you go.

### Step 1 — Resolve plan file

Resolve in priority order — argument, currently open IDE file, settings
`plansDirectory`, then `docs/plans/*.md` — exactly as
`references/resolve-and-preconditions.md` specifies. Stop if nothing resolves.

### Step 2 — Ensure plan is completed and old enough

Hard gate: `status: completed` **and** 30+ days old. Run `plan-status` when the
status is anything else; stop when either check fails. Full rules and stop
messages in `references/resolve-and-preconditions.md`.

### Step 3 — Parse plan content

Extract the H1 title, frontmatter fields, body sections, and inline backtick
tokens per `references/gather-evidence.md`.

### Step 4 — Derive output slug

Slug = plan filename without `.md`; confirm the output path via
`AskUserQuestion` per `references/gather-evidence.md`.

### Step 5 — Inspect shipped files

Resolve every file token to its actual path and read its exported surface,
building the file index defined in `references/gather-evidence.md`.

### Step 6 — Collect git history

Run the windowed `git log` over the plan file and the resolved paths, capped at
20 commits, per `references/gather-evidence.md`.

### Step 7 — Check target doc

If `docs/<slug>.md` already exists, offer Overwrite / Refresh / Cancel per
`references/gather-evidence.md`.

### Step 8 — Synthesize and write the doc

Compose and write the doc using the template in `references/doc-template.md`,
following its dynamic plan link and CHANGELOG citation rules.

### Step 9 — Report

Output the summary table defined in `references/doc-template.md`.

## Examples

```
/plan-agent:documenting-plans                                              # auto-detects from IDE or settings
/plan-agent:documenting-plans docs/plans/add-branch-agent-skill.md        # specific plan file
/plan-agent:documenting-plans ~/.claude/plans/my-feature.md               # absolute path
```
