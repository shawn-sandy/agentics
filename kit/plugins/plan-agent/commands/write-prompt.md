---
description: Build a structured AI prompt using Anthropic techniques and save it to the prompts directory
allowed-tools:
  Read, Glob, AskUserQuestion, ToolSearch, Write, Bash(git *), Bash(mkdir *), Bash(awk *), Bash(shasum *)
argument-hint: "[intent or topic] [--out <path>] [--answers-gathered]"
---

# Write Prompt

`Read` `${CLAUDE_PLUGIN_ROOT}/skills/write-prompt/SKILL.md` and follow it end to
end, treating `$ARGUMENTS` as its `$ARGUMENTS`. If that path does not resolve,
`Glob("**/plan-agent/skills/write-prompt/SKILL.md")` and read the match.

Load the file by path — do **not** call `Skill(skill: "plan-agent:write-prompt")`.
This command shadows the skill of that name, so the call would return this file
again and the seven phases would never load.
