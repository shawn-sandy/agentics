---
name: plan-to-html
description:
  "Deprecated alias for markdown-to-html. Delegates immediately to
  markdown-to-html with no additional processing. Use when the user asks to
  convert a plan to HTML."
allowed-tools: Skill
---

# plan-to-html (Deprecated Alias)

This skill has been renamed to `markdown-to-html`, which supports both plan
files and generic markdown documents.

**Redirects all invocations to `markdown-to-html` with `--mode=plan`.**

## Instructions

Strip any `--mode=...` flag from `$ARGUMENTS` (to avoid duplicate flags), then
call with `--mode=plan` prepended so plan mode is always enforced:

```
Skill(skill: "plan-interview:markdown-to-html", args: "--mode=plan {$ARGUMENTS minus any --mode=...}")
```

Do not emit any other output before or after the delegation. The
`markdown-to-html` skill handles all steps, flags, and reporting.
