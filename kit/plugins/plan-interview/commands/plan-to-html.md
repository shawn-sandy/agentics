---
description: Convert a plan markdown file into a rich, self-contained HTML document viewable in any browser
allowed-tools: Agent, Read, Glob, Grep, Bash(open *), Bash(mkdir *), Write, TodoWrite, AskUserQuestion
argument-hint: "[plan-file-path] - omit to auto-detect from IDE or settings"
---

# Plan to HTML

Convert a plan markdown file into a rich, self-contained HTML document with a
sticky sidebar, color-coded status badge, interactive step completion checkboxes,
scroll-spy navigation, inline markdown rendering, and a selectable color theme.
All styles and scripts are inline — no external dependencies.

Delegates to the full skill instructions in `skills/plan-to-html/SKILL.md`.

## When to use

Run this after writing or updating a plan when you want a browser-readable
version to share with teammates or reference during implementation. Works at any
plan lifecycle stage (todo, in-progress, or completed).

## Usage

```bash
/plan-interview:plan-to-html --setup                                   # one-time setup: cache theme CSS + JS to disk
/plan-interview:plan-to-html                                           # auto-detects from IDE or settings
/plan-interview:plan-to-html docs/plans/add-auth-flow.md              # specific plan file
/plan-interview:plan-to-html ~/.claude/plans/my-feature.md            # absolute path
/plan-interview:plan-to-html docs/plans/add-auth-flow.md --background          # non-interactive, no prompts
/plan-interview:plan-to-html docs/plans/add-auth-flow.md --async               # prompts for theme, then runs in background
/plan-interview:plan-to-html docs/plans/add-auth-flow.md --async --theme=developer # fully hands-off background
```

## Arguments

`[plan-file-path]` — path to the plan `.md` file. Omit to auto-detect using the
same 5-step priority order as all other plan-interview commands (IDE open file →
project settings → global settings → `~/.claude/plans/`).

**Flags:**

- `--setup` — writes pre-built theme CSS and JavaScript to
  `~/.claude/plan-to-html/`. No plan file required. Run once to speed up all
  future conversions (the skill reads cached files instead of re-synthesizing).
- `--theme=<value>` — `default` | `developer` | `document` | `minimal`. Skips
  the theme-selection prompt.
- `--background` — fully non-interactive: uses `default` theme (unless
  `--theme` is set), auto-overwrites existing output, skips browser-open prompt.
  Suitable for automated or batch invocations.
- `--no-open` — skips the browser-open prompt after writing.
- `--async` — prompts for a theme in the foreground (unless `--theme` is also
  set), then spawns a background agent to generate the HTML and returns
  immediately. Use when you want to keep the main thread free. Combine with
  `--theme` for a fully hands-off fire-and-forget invocation.

## Output

Writes `<plan-basename>.html` to the same directory as the source plan. The user
is prompted to select a color theme before the file is written, and offered the
option to open the result in the browser afterward. The output includes:

- Interactive step completion checkboxes (state persists in localStorage)
- Scroll-spy sidebar navigation with active section highlighting
- Inline markdown rendering (bold, italic, code, links, fenced blocks, lists)
- Visual progress bar (updates as steps are checked off)
- Print-friendly styles for PDF export (`Ctrl+P` / `Cmd+P`)

## Follow the skill instructions

See `skills/plan-to-html/SKILL.md` for the full step-by-step workflow.
See `skills/plan-to-html/reference/html-spec.md` for the HTML layout contract,
theme palette definitions, and semantic requirements.
