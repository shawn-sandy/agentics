---
name: plan-to-html
description: "Deprecated alias for markdown-to-html. Use when the user asks to convert a plan to HTML or generate an HTML version of a plan. Delegates to markdown-to-html."
allowed-tools: Skill
---

# plan-to-html (Deprecated Alias)

This skill has been renamed to `markdown-to-html`, which supports both plan files
and generic markdown documents.

**Redirects all invocations to `markdown-to-html` with `--mode=plan`.**

## Instructions

Immediately call:

```
Skill(skill: "plan-interview:markdown-to-html", args: "$ARGUMENTS --mode=plan")
```

Do not emit any other output before or after the delegation. The `markdown-to-html`
skill handles all steps, flags, and reporting.
