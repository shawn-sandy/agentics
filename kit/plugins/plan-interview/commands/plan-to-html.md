---
description: "Deprecated — use /plan-interview:markdown-to-html instead. Converts a plan markdown file to HTML; delegates to markdown-to-html with --mode=plan."
allowed-tools: Skill
argument-hint: "[plan-file-path] [flags] — same flags as markdown-to-html"
---

# plan-to-html (Deprecated)

This command has been renamed to `markdown-to-html`, which supports both plan files
and generic markdown documents. All flags are forwarded unchanged.

**Delegates immediately to `markdown-to-html` with `--mode=plan`.**

## Instructions

Call:

```
Skill(skill: "plan-interview:markdown-to-html", args: "$ARGUMENTS --mode=plan")
```

Do not emit any other output. The `markdown-to-html` skill handles all steps,
flags, and reporting.
