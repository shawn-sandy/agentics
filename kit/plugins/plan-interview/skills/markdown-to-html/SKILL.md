---
name: markdown-to-html
description: "Converts a markdown file into a self-contained HTML page. Produces styled output with syntax highlighting and responsive layout. Use when the user asks to convert a markdown file or plan to HTML."
allowed-tools: Agent, AskUserQuestion, Bash(open *), Bash(realpath *), Glob, Grep, Read, TodoWrite, Write
---

# Markdown to HTML

Convert any markdown file — plan or generic document — into a rich, self-contained
HTML page that can be opened in any browser or shared via a file host.

The skill auto-detects the render mode:
- **Plan mode** — when the source is a plan file (has `## Steps` or `status:` + `Plan:` H1)
- **Doc mode** — for all other markdown files

## When not to use

Does not generate documentation from completed plans — use `documenting-plans` for that.
This skill converts the source markdown into a viewable HTML file at any lifecycle stage.

## Table of Contents

- [Step 0 — Create progress todos](#step-0--create-progress-todos)
- [Step 1 — Resolve the source file](#step-1--resolve-the-source-file)
- [Step 2 — Parse content and detect render mode](#step-2--parse-content-and-detect-render-mode)
- [Step 3 — Resolve theme](#step-3--resolve-theme)
- [Step 4 — Check for existing output file](#step-4--check-for-existing-output-file)
- [Step 5 — Synthesize and write HTML](#step-5--synthesize-and-write-html)
- [Step 6 — Offer to open in browser](#step-6--offer-to-open-in-browser)
- [Step 7 — Report](#step-7--report)

## Instructions

### Step 0 — Create progress todos

Scan `$ARGUMENTS` for `--setup`. If found, print:

```
--setup is deprecated. Theme CSS and JS are now bundled in the plugin.
Run the skill without --setup to generate HTML.
```

Then stop.

Otherwise, use `TodoWrite` to create todos:

- Step 1: Resolve source file
- Step 2: Parse content and detect render mode
- Step 3: Resolve theme
- Step 4: Check for existing output
- Step 5: Synthesize and write HTML
- Step 6: Offer to open in browser
- Step 7: Report

Mark each todo `status: "completed"` as you finish that step.

### Step 1 — Resolve the source file

**Path traversal defense (required before reading any file):**

If a file path appears in `$ARGUMENTS`:
1. Run `realpath "<path>"` to get the canonical absolute path.
2. Confirm the result is under `$PWD`. If not, print
   "Error: path is outside the workspace" and stop.
3. Confirm the extension is `.md` or `.markdown`. If not, print
   "Error: file must be a .md or .markdown file" and stop.
4. Confirm `realpath` resolved without following a symlink outside the workspace.

If any check fails, stop with a descriptive error.

**File resolution order (use first match):**

1. **Argument**: file path in `$ARGUMENTS` (after passing the checks above)
2. **Currently open file**: `.md` file open in IDE that contains `## Steps`,
   `## Context`, `## Objective`, `## Implementation`, or `## Plan`
3. **Settings `plansDirectory`**: project-local `.claude/settings.local.json` →
   project `.claude/settings.json` → global `~/.claude/settings.json` (first that
   sets it) → most recently modified `.md` file
4. **Fallback**: glob `${PWD}/docs/plans/*.md`, most recently modified

If no file found via any method, tell the user and stop.

**Flag parsing** — after resolving the file, scan `$ARGUMENTS` for:

- `--theme=<value>` — accepted: `default`, `developer`, `document`, `minimal`.
  Apply allow-list: if the value is not one of these four names, ignore and fall
  through to the Step 3 prompt. Store as pre-selected theme if valid.
- `--mode=<value>` — accepted: `auto`, `plan`, `doc`. Default: `auto`.
- `--list-themes` — if present, print the four theme names + descriptions and stop.
- `--no-open` — Step 6 skips the browser-open prompt.
- `--background` — fully non-interactive: auto-selects `default` theme (unless
  `--theme` also set), auto-overwrites existing output, implies `--no-open`.
- `--async` — prompts for theme in foreground, then spawns a background Agent and
  stops. Does not imply `--background` on the main thread.

Announce the resolved file: `"Converting: path/to/file.md"`

### Step 2 — Parse content and detect render mode

Read the resolved file and extract:

- **Raw H1**: first line matching `# …` — strip only the leading `# ` character.
  Keep the `Plan:` prefix intact at this stage; it is needed for mode detection below.
- **Display title**: derive from raw H1 by stripping any `Plan:` prefix (with or
  without trailing space). Use this for rendering only, not for detection.
- **Frontmatter**: YAML block between `---` delimiters. Capture `status`, `created`,
  `modified`, `type`. Treat all as absent if no frontmatter.
- **Sections**: every `## Heading` and content until the next `## Heading` or EOF.
  Include `## Interview Summary` if present.
- **Steps content** (if `## Steps` present): parse per-step action, why, and verify
  text. If plain list items (no why/verify), treat as action-only steps.

**Render mode detection** (when `--mode=auto` or flag absent):

Set mode to **plan** when any of:
- Source contains a `## Steps` section, OR
- Frontmatter has a `status:` key AND **raw H1** starts with `Plan:`

Otherwise set mode to **doc**.

When `--mode=plan` or `--mode=doc` is passed, skip detection and use the specified mode.

Apply graceful unknown state rules from `reference/html-spec.md` for absent fields.

### Step 3 — Resolve theme

If `--list-themes` was parsed, print and stop:

```
Available themes:
  default   — neutral grays, blue accent
  developer — dark charcoal, green accent (terminal-inspired)
  document  — warm off-white, sepia/brown accent
  minimal   — pure white, black text
```

If `--theme=<value>` was parsed and validated in Step 1, use it directly — skip prompt.

If `--background` was parsed and no valid `--theme`, use `default` without prompting.

Otherwise, ask via `AskUserQuestion` with four options:

- **Default** — neutral grays and white, blue accent
- **Developer** — dark charcoal header, green accent (terminal-inspired)
- **Document** — warm off-white background, sepia/brown accent
- **Minimal** — pure white background, black text, no accent color

Store selected theme name (lowercase, hyphenated) for Step 5.

**Async dispatch** (only when `--async` parsed AND `--background` NOT parsed):
Now that theme is known, spawn a background agent and stop:

- `subagent_type`: `"general-purpose"`
- `run_in_background`: `true`
- `description`: `"markdown-to-html background conversion"`
- `prompt`: `"Invoke Skill(skill: \"plan-interview:markdown-to-html\", args:
  \"/actual/path/to/file.md --theme=<theme> --no-open --background\") to convert
  the file to HTML non-interactively."` — substitute real path and theme.

Output: `"Background conversion started: /path/to/file.md (theme: <theme>)"` and stop.

### Step 4 — Check for existing output file

Derive output path: same directory as source file, same basename, `.html` extension.

Example: `docs/plans/add-auth.md` → `docs/plans/add-auth.html`

Use `Glob` to check whether the output file already exists.

If `--background` was parsed and file exists, overwrite automatically.

If the file exists and `--background` was not set, ask via `AskUserQuestion`:

> "Output file `<name>.html` already exists. Overwrite?"

Options: `Overwrite` / `Cancel`. Stop if user selects Cancel.

### Step 5 — Synthesize and write HTML

Read `reference/html-spec.md` to load the full layout contract, theme definitions,
and JavaScript features. This is the authoritative source — follow it exactly.

**Asset check (optimization):** Attempt to `Read assets/themes.css`. If it
succeeds, use its content verbatim as the theme block — skip re-deriving the four
`body.theme-*` rule sets from the spec. Similarly attempt `Read assets/scripts.js`;
if it succeeds, use it verbatim for the `<script>` block. If either read fails,
derive from the spec as usual.

Generate a complete, self-contained HTML document. Key requirements:

**Security (required — see spec "Security and Encoding" section):**
- Per-sink HTML encoding for all user-controlled content
- URL allow-list for all link `href` values (`http://`, `https://`, `mailto:`, `#` only)
- Theme allow-list: validate before interpolating into `<body class="theme-…">`

**Structure:**
- `<!DOCTYPE html>` first line
- `<html lang="en">`, `<title>`, `<meta charset>`, `<meta name="viewport">`
- `<a href="#main-content" class="skip-link">Skip to main content</a>` as first element in `<body>`
- `<header>`, `.layout` grid with `<nav>` + `<main id="main-content">`
- Save as PDF button (`.save-pdf-btn`) in header — calls `savePDF()` which triggers `window.print()`; hidden in `@media print`
- Each `<section>` has `aria-labelledby` → its `<h2 id>`

**Plan mode additions:**
- Progress bar (`role="progressbar"`, `aria-valuenow/min/max`, `aria-label`)
- Status badge
- Sidebar `<div class="scroll-rail" aria-hidden="true">`
- Steps as `<ol class="steps-list">` with `<li class="step-card">` per step
- Per-step: `<label class="step-label">` wrapping checkbox + `<span class="step-chip" aria-hidden="true">todo</span>` + `<h3 class="step-action">`
- `aria-describedby` on each checkbox pointing to `step-why-{index}`
- `<span class="step-status" aria-live="polite" aria-atomic="true">` live region per step
- CSS step timeline (vertical connector line + circle nodes via `::before` pseudo-elements — see spec)
- SVG section diagram when ≥2 sections present (see spec "SVG Section Diagram")

**Theme:**
Apply `<body class="theme-{validated-theme}">`. Use exact CSS custom property names
and values from spec "Color Palette Themes".

**Responsive + card styles:** Include full CSS from spec "Global Styles".

**Print styles:** Include `@media print` block from spec "Print Styles".

**Markdown rendering:** HTML-escape first, then apply inline patterns from spec
"Markdown Rendering". Apply URL allow-list to all `[label](url)` links. Do not
markdown-render `<h1>`, `<h2>`, or fenced code block content.

**JavaScript:** Single `<script>` block immediately before `</body>` with:
- Scroll-spy IIFE (IntersectionObserver + `aria-current="true"` + scroll-rail updater)
- Step-completion IIFE with chip text update + live-region announcement (plan mode only)
- SVG node click listeners (plan mode only, when diagram present)

Write the completed HTML to the derived output path via `Write`.

### Step 6 — Offer to open in browser

Skip entirely if `--no-open` or `--background` was set.

Ask via `AskUserQuestion`: "Open `<name>.html` in the browser?"

Options: `Open` / `Skip`.

If Open selected: run `open "<output-path>"` (macOS). On other platforms, inform
the user browser-open is not supported and skip the `open` call.

### Step 7 — Report

Output one line:

```
Written to docs/plans/add-auth.html (mode: plan, theme: developer)
```

## Examples

```text
/plan-interview:markdown-to-html                                                      # auto-detects from IDE or settings
/plan-interview:markdown-to-html docs/plans/add-auth.md                              # specific plan file
/plan-interview:markdown-to-html README.md --mode=doc                                # force doc mode
/plan-interview:markdown-to-html docs/plans/add-auth.md --theme=developer            # pre-select theme
/plan-interview:markdown-to-html docs/plans/add-auth.md --theme=developer --no-open  # batch-safe, no prompts
/plan-interview:markdown-to-html docs/plans/add-auth.md --background                 # fully non-interactive
/plan-interview:markdown-to-html docs/plans/add-auth.md --async --theme=developer    # background agent, no prompts
/plan-interview:markdown-to-html --list-themes                                        # print available themes and stop
```
