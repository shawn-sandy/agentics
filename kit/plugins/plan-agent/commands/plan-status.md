---
description: Check and update the lifecycle status of a plan file (todo, in-progress, completed) with type classification (feature, fix, refactor, docs, chore)
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, Edit, TodoWrite
argument-hint: "[plan-file-path] - omit to auto-detect from IDE or settings"
---

# Plan Status

Read `${CLAUDE_PLUGIN_ROOT}/skills/plan-status/SKILL.md` and follow it exactly,
treating `$ARGUMENTS` as its input. If that path does not resolve, `Glob` for
`**/plan-agent/skills/plan-status/SKILL.md` and read the match instead.

Read the file by path — never hand off by skill name. A command shadows a
same-named skill in that namespace, so the lookup returns this file, the skill
body never loads, and the workflow silently does nothing.
