---
description: Convert a markdown file or plan to a rich, self-contained HTML document viewable in any browser
allowed-tools: Agent, Read, Glob, Grep, Bash(open *), Bash(realpath *), Write, TodoWrite, AskUserQuestion, Skill
argument-hint: "[file-path] [--theme=default|developer|document|minimal] [--mode=auto|plan|doc] [--background] [--no-open] [--async] [--list-themes]"
---

# Markdown to HTML

Convert any markdown file — plan or generic document — into a rich, self-contained
HTML page with a sticky sidebar, interactive navigation, inline markdown rendering,
and a selectable color theme. All styles and scripts are inline — no external dependencies.

## Instructions

Invoke the markdown-to-html skill, forwarding all arguments:

```
Skill(skill: "plan-interview:markdown-to-html", args: "$ARGUMENTS")
```

The skill handles all steps — file resolution, mode detection, theme selection,
HTML generation, and browser open offer. See `skills/markdown-to-html/SKILL.md`
for the full step-by-step workflow.

## When to use

Run after writing or updating a plan or markdown document when you want a browser-readable
version to share or reference. The skill auto-detects plan files and enables interactive
step completion, scroll-spy navigation, a CSS step timeline, status chips, and an SVG
section diagram. Works at any plan lifecycle stage (todo, in-progress, or completed).

## Usage

```bash
/plan-interview:markdown-to-html                                                      # auto-detects from IDE or settings
/plan-interview:markdown-to-html docs/plans/add-auth.md                              # specific plan file
/plan-interview:markdown-to-html README.md --mode=doc                                # force doc mode for any markdown
/plan-interview:markdown-to-html docs/plans/add-auth.md --theme=developer            # pre-select theme, still prompts for browser-open
/plan-interview:markdown-to-html docs/plans/add-auth.md --theme=developer --no-open  # batch-safe: no prompts
/plan-interview:markdown-to-html docs/plans/add-auth.md --background                  # fully non-interactive: default theme, auto-overwrite
/plan-interview:markdown-to-html docs/plans/add-auth.md --async --theme=developer    # background agent, no prompts
/plan-interview:markdown-to-html --list-themes                                        # print available themes and stop
```

## Arguments

`[file-path]` — path to a `.md` or `.markdown` file. Omit to auto-detect using the
same priority order as other plan-interview commands (IDE open file → settings
`plansDirectory` (project-local → project → global) → `${PWD}/docs/plans/`).

**Flags:**

- `--mode=auto|plan|doc` — override render mode detection. `auto` (default) detects
  plan files automatically. `plan` forces plan mode; `doc` forces doc mode.
- `--theme=<value>` — `default` | `developer` | `document` | `minimal`. Skips the
  theme-selection prompt.
- `--list-themes` — print available theme names and descriptions, then stop.
- `--background` — fully non-interactive: uses `default` theme (unless `--theme` set),
  auto-overwrites existing output, skips browser-open. Suitable for batch invocations.
- `--no-open` — skips the browser-open prompt after writing.
- `--async` — prompts for theme in foreground (unless `--theme` set), then spawns a
  background agent to generate HTML and returns immediately.

## Output

Writes `<basename>.html` to the same directory as the source file. Plan-mode output includes:

- Interactive step completion checkboxes (state persists in localStorage)
- Scroll-spy sidebar with active section highlighting and scroll-rail indicator
- CSS step timeline with connector lines and circle node per step
- Status chip per step (`todo` / `done`) updated on checkbox change
- Inline markdown rendering (bold, italic, code, links, fenced blocks, lists)
- Visual progress bar (updates dynamically as steps are checked)
- SVG section diagram (when ≥2 sections present)
- Print-friendly styles for PDF export

## Migration from plan-to-html

The `plan-to-html` skill has been renamed to `markdown-to-html`. The old
`/plan-interview:plan-to-html` command is deprecated and delegates here — it will be
removed in a future major release. Update invocations to use `markdown-to-html` directly.

## Follow the skill instructions

See `skills/markdown-to-html/SKILL.md` for the full step-by-step workflow.
See `skills/markdown-to-html/reference/html-spec.md` for the HTML layout contract,
theme definitions, security rules, and semantic requirements.
