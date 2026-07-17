---
description: Generate developer-friendly documentation at docs/<slug>.md from a completed plan file, synthesized from the plan body, live code inspection, and git history
allowed-tools: Skill
argument-hint: "[plan-file-path] - omit to auto-detect from IDE or settings"
---

# Documenting Plans

Delegates immediately to the `documenting-plans` skill; it handles all steps and
reporting. Do not emit any other output.

```
Skill(skill: "plan-agent:documenting-plans", args: "$ARGUMENTS")
```
