---
description: Check and update the lifecycle status of a plan file (todo, in-progress, completed) with type classification (feature, fix, refactor, docs, chore)
allowed-tools:
  Read, Glob, Grep, Bash, AskUserQuestion, Edit, TodoWrite
argument-hint: "[plan-file-path | directory] [--all] [--force] - omit to auto-detect; pass a directory or --all for bulk mode"
---

# Plan Status

Read `${CLAUDE_PLUGIN_ROOT}/skills/plan-status/SKILL.md` and follow it exactly,
treating `$ARGUMENTS` as its input. If that path does not resolve, `Glob` for
`**/plan-agent/skills/plan-status/SKILL.md` and read the match instead.

Do **not** reach for the `Skill` tool here. A command shadows a skill of the
same name, so asking it for `plan-agent:plan-status` returns this file — the
skill body never loads and the workflow silently no-ops.
