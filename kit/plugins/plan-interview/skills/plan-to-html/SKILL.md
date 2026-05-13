---
name: plan-to-html
description: "Use when the user asks to convert a plan to HTML, generate an HTML version of a plan, export a plan as a webpage, or make a plan viewable in a browser."
allowed-tools: AskUserQuestion, Bash(open *), Glob, Grep, Read, TodoWrite, Write
---

# Plan to HTML

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
   validate it before proceeding: confirm the file exists, is readable, and has
   a `.md` extension. If any check fails, tell the user (including the path and
   reason — missing, unreadable, or not `.md`) and stop.
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

- **H1 title**: first line matching `# ...` — strip the leading `#` character
  and space, then strip any `Plan:` prefix (with or without a trailing space).
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

**Structure**: `<header>` with progress bar + title + status badge + metadata row,
then a `.layout` grid with `<nav aria-label="Plan sections">` sidebar and `<main>`
content area containing one `<section>` per plan section.

**Theme**: Apply the CSS custom property values for the selected theme as a class
on `<body>` (e.g., `<body class="theme-developer">`). Use the exact variable
names and color values from the theme definitions in `reference/html-spec.md`.
Include the new `--color-card-bg` and `--color-code-bg` variables.

**Steps**: Render using `<ol class="steps-list">` with `<li class="step-card"
data-step-id="{plan-slug}-{index}">` per step. Wrap the `<h3 class="step-action">`
in a `<label class="step-check">` alongside an `<input type="checkbox"
class="step-checkbox">`. Include `<p class="step-why">` and `<p
class="step-verify">` (prefixed with ✓) when those lines exist. If a step has no
why/verify text, omit those elements.

**Progress indicator**: Include `<div class="progress-bar"><div
class="progress-fill"></div></div>` at the top of `<header>`. Set the initial
fill width and color from the plan's status field per the table in
`reference/html-spec.md` ("Progress Indicator" section).

**Semantics**: Follow all rules in the "Semantic Rules" section of
`reference/html-spec.md` — `lang="en"` on `<html>`, heading hierarchy, landmark
elements, `role="progressbar"` and `aria-label` on the progress bar, contrast
requirements, touch targets.

**Responsive + step hover**: Include the full CSS from `reference/html-spec.md`
— `scroll-behavior: smooth`, step card `box-shadow` and `hover` transition,
`completed` class strikethrough, inline `<code>` and `<pre>` block styles, and
the `@media (max-width: 768px)` collapse.

**Print styles**: Include the `@media print` block from `reference/html-spec.md`
so the output is clean when printed or exported to PDF.

**Content sanitization + markdown rendering**: HTML-escape all text sourced from
the plan file first. Then apply the inline markdown rendering rules from
`reference/html-spec.md` ("Markdown Rendering" section) to convert `**bold**`,
`*italic*`, `` `code` ``, `[links](url)`, `~~strikethrough~~`, fenced code blocks,
lists, and paragraph breaks into proper HTML elements. Do not apply markdown
rendering to the `<h1>` title or `<h2>` section headings (those are already
handled structurally). Any raw HTML tags in the plan source that survive escaping
are rendered as escaped text — no live HTML injection.

**JavaScript**: Include a single inline `<script>` block immediately before
`</body>` implementing the two features from `reference/html-spec.md`
("JavaScript Features" section):
1. Scroll spy — `IntersectionObserver` adds `class="active"` to the sidebar link
   for the currently visible section.
2. Step completion — checkboxes restore their `localStorage` state on load,
   toggle the `completed` class on the card, persist changes, and update the
   progress bar fill percentage.

Write the completed HTML to the output path via the `Write` tool.

### Step 6 — Offer to open in browser

After writing, ask via `AskUserQuestion`:

> "Open `<name>.html` in the browser?"

Options: `Open` / `Skip`.

If the user selects Open, run `open "<output-path>"` (macOS only). This skill
is macOS-targeted; on other platforms, inform the user that browser-open is not
supported and skip the `open` call.

### Step 7 — Report

Output a one-line summary:

```text
Written to docs/plans/add-auth-flow.html (theme: developer)
```

## Examples

```text
/plan-interview:plan-to-html                                    # auto-detects from IDE or settings
/plan-interview:plan-to-html docs/plans/add-auth-flow.md       # specific plan file
/plan-interview:plan-to-html ~/.claude/plans/my-feature.md     # absolute path
```
