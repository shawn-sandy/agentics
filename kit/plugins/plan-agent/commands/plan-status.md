---
description: Check and update the lifecycle status of a plan file (todo, in-progress, completed) with type classification (feature, fix, refactor, docs, chore)
allowed-tools:
  Read, Glob, Grep, Bash, AskUserQuestion, Edit, TodoWrite
argument-hint: "[plan-file-path | directory] [--all] [--force] - omit to auto-detect; pass a directory or --all for bulk mode"
---

# Plan Status

`Read` `${CLAUDE_PLUGIN_ROOT}/skills/plan-status/SKILL.md` and follow it end to
end, treating `$ARGUMENTS` as its `$ARGUMENTS`. If that path does not resolve,
`Glob("**/plan-agent/skills/plan-status/SKILL.md")` and read the match.

Load the file by path — do **not** call `Skill(skill: "plan-agent:plan-status")`.
This command shadows the skill of that name, so the call would return this file
again and the workflow would never load.
