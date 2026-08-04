---
description: Author and implement a refactor plan — the /plan-agent:build chain, typed as a refactor
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, Skill, ToolSearch, ExitPlanMode
argument-hint: "<objective> [--dir <path>]"
---

# Refactor

Invoke `Skill(skill: "plan-agent:build", args: "--type refactor $ARGUMENTS")`.

A typed entry point, nothing more. Every step — the proposal gate, plan
authoring, review, implementation, the completion gates — belongs to `build`
and is not restated here.

**`--type refactor` is prepended, not appended.** `build` resolves a repeated
`--type` last-wins, so the default has to come *first* for a user's explicit
value to override it: `/plan-agent:refactor task --type docs` must expand to
`--type refactor task --type docs`, where `docs` is last and wins. Appending
would invert that and make the command's default silently beat the user.

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
/plan-agent:refactor extract the token parser out of auth middleware
/plan-agent:refactor --dir tmp/plans split the settings module into services
```

Given an existing plan path instead of an objective, `build` implements that
plan and ignores `--type` — the plan already carries its own.
