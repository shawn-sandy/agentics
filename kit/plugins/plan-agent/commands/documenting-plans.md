---
description: Generate developer-friendly documentation at docs/<slug>.md from a completed plan file, synthesized from the plan body, live code inspection, and git history
allowed-tools:
  Read, Glob, Grep, Bash(git *), AskUserQuestion, Write, Edit, TodoWrite, Skill
argument-hint: "[plan-file-path] - omit to auto-detect from IDE or settings"
---

# Documenting Plans

`Read` `${CLAUDE_PLUGIN_ROOT}/skills/documenting-plans/SKILL.md` and follow it
end to end, treating `$ARGUMENTS` as its `$ARGUMENTS`. If that path does not
resolve, `Glob("**/plan-agent/skills/documenting-plans/SKILL.md")` and read the
match.

Load the file by path — do **not** call
`Skill(skill: "plan-agent:documenting-plans")`. This command shadows the skill of
that name, so the call would return this file again and the workflow would never
load. `Skill` stays in `allowed-tools` because the skill body itself invokes
other skills.
