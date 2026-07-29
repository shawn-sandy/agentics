---
description: Walk each decision branch in an implementation plan with focused questions and codebase exploration
allowed-tools: Read, Glob, Grep, AskUserQuestion, TodoWrite
argument-hint: "[plan-file-path] - omit to auto-detect from IDE or docs/plans/"
---

# Deep Grill

Read `${CLAUDE_PLUGIN_ROOT}/skills/deep-grill/SKILL.md` and follow it exactly,
treating `$ARGUMENTS` as its input. If that path does not resolve, `Glob` for
`**/plan-agent/skills/deep-grill/SKILL.md` and read the match instead.

Do **not** reach for the `Skill` tool here. A command shadows a skill of the
same name, so asking it for `plan-agent:deep-grill` returns this file — the
skill body never loads and the workflow silently no-ops.
