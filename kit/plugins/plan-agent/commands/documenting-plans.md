---
description: Generate developer-friendly documentation at docs/<slug>.md from a completed plan file, synthesized from the plan body, live code inspection, and git history
allowed-tools: Read, Glob, Grep, Bash(git *), AskUserQuestion, Write, Edit, TodoWrite, Skill
argument-hint: "[plan-file-path] - omit to auto-detect from IDE or settings"
---

# Documenting Plans

Read `${CLAUDE_PLUGIN_ROOT}/skills/documenting-plans/SKILL.md` and follow it
exactly, treating `$ARGUMENTS` as its input. If that path does not resolve,
`Glob` for `**/plan-agent/skills/documenting-plans/SKILL.md` and read the match.

Never ask the `Skill` tool for `plan-agent:documenting-plans` — a command
shadows a skill of the same name, so that call returns this file and the
workflow no-ops. Other skills, `plan-agent:plan-status` included, run normally.
