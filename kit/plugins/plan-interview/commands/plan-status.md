---
description: Check and update the lifecycle status of a plan file (todo, in-progress, completed) with type classification (feature, fix, refactor, docs, chore)
allowed-tools: Skill
argument-hint: "[plan-file-path] - omit to auto-detect from IDE or settings"
---

# Plan Status

Delegates immediately to the `plan-status` skill; it handles all steps and
reporting. Do not emit any other output.

```
Skill(skill: "plan-interview:plan-status", args: "$ARGUMENTS")
```
