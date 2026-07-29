---
description: Walk each decision branch in an implementation plan with focused questions and codebase exploration
allowed-tools: Read, Glob, Grep, AskUserQuestion, TodoWrite
argument-hint: "[plan-file-path] - omit to auto-detect from IDE or docs/plans/"
---

# Deep Grill

`Read` `${CLAUDE_PLUGIN_ROOT}/skills/deep-grill/SKILL.md` and follow it end to
end, treating `$ARGUMENTS` as its `$ARGUMENTS`. If that path does not resolve,
`Glob("**/plan-agent/skills/deep-grill/SKILL.md")` and read the match.

Load the file by path — do **not** call `Skill(skill: "plan-agent:deep-grill")`.
This command shadows the skill of that name, so the call would return this file
again and the workflow would never load.
