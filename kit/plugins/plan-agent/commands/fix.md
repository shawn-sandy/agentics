---
description: Author and implement a fix plan — the /plan-agent:build chain, typed as a fix
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, Skill, ToolSearch, ExitPlanMode
argument-hint: "<objective> [--dir <path>]"
---

# Fix

Invoke `Skill(skill: "plan-agent:build", args: "$ARGUMENTS --type fix")`.

A typed entry point, nothing more. Every step — the proposal gate, plan
authoring, review, implementation, the completion gates — belongs to `build`
and is not restated here. `--type fix` is appended rather than prepended so a
user-supplied `--type` lands later in the string and wins under last-wins
parsing.

`allowed-tools` mirrors `build`'s exactly. `Skill()` runs the skill body
**inline under this command's permissions**, so a short list here would not fail
at load — it would stall on whichever branch first reached a missing tool. Keep
the two lists in sync when `build`'s changes.

The plan-mode guard line itself stays out: `build` carries it as its Step 0, and
a dispatcher that repeated it would exit plan mode a step before the workflow
that actually mutates state. `ExitPlanMode` and `ToolSearch` are still listed —
that is build's Step 0 needing them, not this file.

## Usage

```bash
/plan-agent:fix the login redirect loops when the session cookie is stale
/plan-agent:fix --dir tmp/plans checkout total ignores the discount code
```

Given an existing plan path instead of an objective, `build` implements that
plan and ignores `--type` — the plan already carries its own.
