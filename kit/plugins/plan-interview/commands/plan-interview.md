---
description: Stress-test a plan with a structured interview across technical, UX, edge case, and out-of-scope domains
allowed-tools: Skill
argument-hint: "[plan-file-path] - omit to auto-detect from IDE or docs/plans/"
---

# Plan Interview

Delegates immediately to the `plan-interview` skill; it handles all steps and
reporting. All flags, including `--quick`, are forwarded unchanged. Do not emit any other output.

```
Skill(skill: "plan-interview:plan-interview", args: "$ARGUMENTS")
```
