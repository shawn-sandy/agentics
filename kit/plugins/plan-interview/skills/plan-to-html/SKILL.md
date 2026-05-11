---
name: plan-to-html
description: "Use when the user asks to convert a plan to HTML, generate an HTML version of a plan, export a plan as a webpage, or make a plan viewable in a browser."
allowed-tools: AskUserQuestion, Bash(open *), Glob, Grep, Read, TodoWrite, Write
---

# plan-to-html

Convert a plan markdown file into a rich, self-contained HTML document that can
be opened in any browser or shared via a file host.

## When not to use

Does not generate documentation from completed plans — use `documenting-plans`
for that. This skill converts the plan itself into a readable HTML file at any
lifecycle stage (todo, in-progress, or completed).

## Table of Contents

- [Step 0 — Create progress todos](#step-0--create-progress-todos)
- [Step 1 — Resolve the plan file](#step-1--resolve-the-plan-file)
- [Step 2 — Parse plan content](#step-2--parse-plan-content)
- [Step 3 — Prompt for theme](#step-3--prompt-for-theme)
- [Step 4 — Check for existing output file](#step-4--check-for-existing-output-file)
- [Step 5 — Synthesize and write HTML](#step-5--synthesize-and-write-html)
- [Step 6 — Offer to open in browser](#step-6--offer-to-open-in-browser)
- [Step 7 — Report](#step-7--report)

## Instructions

### Step 0 — Create progress todos

Before doing anything else, use `TodoWrite` to create todos for each step:

- Step 1: Resolve plan file
- Step 2: Parse plan content
- Step 3: Prompt for theme
- Step 4: Check for existing output
- Step 5: Synthesize and write HTML
- Step 6: Offer to open in browser
- Step 7: Report

Mark each todo `status: "completed"` as you finish that step.

### Step 1 — Resolve the plan file

Use the first match from this priority order:

1. **Argument**: If a file path appears in `$ARGUMENTS` or the user's message,
   use it directly.
2. **Currently open file**: If no path was given, check whether a `.md` file is
   currently open in the IDE. If it looks like a plan (contains headings like
   `## Steps`, `## Context`, `## Objective`, `## Implementation`, or `## Plan`),
   use it.
3. **Project-level config**: Read `.claude/settings.json`. If a
   `"plansDirectory"` key exists, glob `*.md` files from that path and use the
   most recently modified file.
4. **Global config**: Read `~/.claude/settings.json`. Same logic as above.
5. **Default fallback**: Glob `~/.claude/plans/*.md`, sort by modification time,
   use the most recently modified file.

If no file is found via any method, tell the user and stop.

Announce the resolved file: `"Converting plan: path/to/plan.md"`

### Step 2 — Parse plan content

Read the plan file and extract:

- **H1 title**: first line matching `# ...` — strip leading `# ` and any `Plan:`
  or `Plan: ` prefix.
- **Frontmatter fields**: extract the YAML block between `---` delimiters.
  Capture `status`, `created`, `modified`, `type`. If the file has no
  frontmatter, treat all fields as absent.
- **Sections**: collect every `## Heading` and the content beneath it until the
  next `## Heading` or end of file. Collect all sections present, including
  `## Interview Summary` if it exists at the end of the plan.
- **Steps content**: if a `## Steps` section exists, parse its `<ol><li>`
  structure to extract per-step action, why, and verify text. If the steps use
  plain markdown list items instead of `<ol>`, extract them as action lines with
  no why/verify rows.

Apply graceful unknown state rules from `reference/html-spec.md` for any absent
fields.

### Step 3 — Prompt for theme

Ask the user which color palette to apply:

Ask via `AskUserQuestion` with four options:

- **Default** — neutral grays and white, blue accent
- **Developer** — dark charcoal header, green accent (terminal-inspired)
- **Document** — warm off-white background, sepia/brown accent
- **Minimal** — pure white background, black text, no accent color

Store the selected theme name (lowercase, hyphenated) for use in Step 5.

### Step 4 — Check for existing output file

Derive the output path: same directory as the resolved plan file, same basename,
`.html` extension replacing `.md`.

Example: `docs/plans/add-auth-flow.md` → `docs/plans/add-auth-flow.html`

Use `Glob` to check whether the output file already exists.

If it exists, ask via `AskUserQuestion`:

> "Output file `<name>.html` already exists. Overwrite?"

Options: `Overwrite` / `Cancel`.

Stop if the user selects Cancel. Proceed if they select Overwrite.

If the file does not exist, proceed directly to Step 5.

### Step 5 — Synthesize and write HTML

Generate a complete, self-contained HTML document following the layout contract
in `reference/html-spec.md`. Key requirements:

**Structure**: `<header>` with title + status badge + metadata row, then a
`.layout` grid with `<nav aria-label="Plan sections">` sidebar and `<main>`
content area containing one `<section>` per plan section.

**Theme**: Apply the CSS custom property values for the selected theme as a class
on `<body>` (e.g., `<body class="theme-developer">`). Use the exact variable
names and color values from the theme definitions in `reference/html-spec.md`.

**Steps**: Render using `<ol class="steps-list">` with `<li class="step-card">`
per step. Each card has `<h3 class="step-action">` for the action, `<p
class="step-why">` for the why rationale, and `<p class="step-verify">` for the
verify line (prefixed with ✓). If a step has no why/verify text, omit those
elements.

**Semantics**: Follow all rules in the "Semantic Rules" section of
`reference/html-spec.md` — heading hierarchy, landmark elements, contrast
requirements.

**Responsive**: Include the media query from `reference/html-spec.md` so the
layout collapses to single-column below 768px.

**Self-contained**: All CSS must be inline in a `<style>` block in `<head>`. No
external stylesheets, no CDN links, no `<script>` tags, no JavaScript.

Write the completed HTML to the output path via the `Write` tool.

### Step 6 — Offer to open in browser

After writing, ask via `AskUserQuestion`:

> "Open `<name>.html` in the browser?"

Options: `Open` / `Skip`.

If the user selects Open, run:

```bash
open "<output-path>"
```

(macOS). On other platforms, skip if `open` is not available.

### Step 7 — Report

Output a one-line summary:

```
Written to docs/plans/add-auth-flow.html (theme: developer)
```

## Examples

```
/plan-interview:plan-to-html                                    # auto-detects from IDE or settings
/plan-interview:plan-to-html docs/plans/add-auth-flow.md       # specific plan file
/plan-interview:plan-to-html ~/.claude/plans/my-feature.md     # absolute path
```
