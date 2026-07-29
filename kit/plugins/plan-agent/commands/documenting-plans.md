---
description: Generate developer-friendly documentation at docs/<slug>.md from a completed plan file, synthesized from the plan body, live code inspection, and git history
allowed-tools: Read, Glob, Grep, Bash(git *), AskUserQuestion, Write, Edit, TodoWrite
argument-hint: "[plan-file-path] - omit to auto-detect from IDE or settings"
---

# Documenting Plans

Read `${CLAUDE_PLUGIN_ROOT}/skills/documenting-plans/SKILL.md` and follow it
exactly, treating `$ARGUMENTS` as its input. If that path does not resolve,
`Glob` for `**/plan-agent/skills/documenting-plans/SKILL.md` and read the match.

Do **not** reach for the `Skill` tool here. A command shadows a skill of the
same name, so asking it for `plan-agent:documenting-plans` returns this file —
the skill body never loads and the workflow silently no-ops.
