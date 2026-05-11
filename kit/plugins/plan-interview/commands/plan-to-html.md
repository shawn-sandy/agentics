---
description: Convert a plan markdown file into a rich, self-contained HTML document viewable in any browser
allowed-tools: Read, Glob, Grep, Bash(open *), Write, TodoWrite, AskUserQuestion
argument-hint: "[plan-file-path] - omit to auto-detect from IDE or settings"
---

# Plan to HTML

Convert a plan markdown file into a rich, self-contained HTML document with a
sticky sidebar, color-coded status badge, three-line step cards (action / why /
verify), and a selectable color theme. All styles are inline — no external
dependencies.

Delegates to the full skill instructions in `skills/plan-to-html/SKILL.md`.

## When to use

Run this after writing or updating a plan when you want a browser-readable
version to share with teammates or reference during implementation. Works at any
plan lifecycle stage (todo, in-progress, or completed).

## Usage

```bash
/plan-interview:plan-to-html                                    # auto-detects from IDE or settings
/plan-interview:plan-to-html docs/plans/add-auth-flow.md       # specific plan file
/plan-interview:plan-to-html ~/.claude/plans/my-feature.md     # absolute path
```

## Arguments

`[plan-file-path]` — path to the plan `.md` file. Omit to auto-detect using the
same 5-step priority order as all other plan-interview commands (IDE open file →
project settings → global settings → `~/.claude/plans/`).

## Output

Writes `<plan-basename>.html` to the same directory as the source plan. The user
is prompted to select a color theme before the file is written, and offered the
option to open the result in the browser afterward.

## Follow the skill instructions

See `skills/plan-to-html/SKILL.md` for the full step-by-step workflow.
See `skills/plan-to-html/reference/html-spec.md` for the HTML layout contract,
theme palette definitions, and semantic requirements.
