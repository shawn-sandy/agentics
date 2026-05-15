---
name: plan-to-html
description: "Use when the user asks to convert a plan to HTML, generate an HTML version of a plan, export a plan as a webpage, or make a plan viewable in a browser."
allowed-tools: Agent, AskUserQuestion, Bash(open *), Bash(mkdir *), Glob, Grep, Read, TodoWrite, Write
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
- [Step 0.5 — Setup mode](#step-05--setup-mode)
- [Step 1 — Resolve the plan file](#step-1--resolve-the-plan-file)
- [Step 2 — Parse plan content](#step-2--parse-plan-content)
- [Step 3 — Prompt for theme](#step-3--prompt-for-theme)
- [Step 4 — Check for existing output file](#step-4--check-for-existing-output-file)
- [Step 5 — Synthesize and write HTML](#step-5--synthesize-and-write-html)
- [Step 6 — Offer to open in browser](#step-6--offer-to-open-in-browser)
- [Step 7 — Report](#step-7--report)

## Instructions

### Step 0 — Create progress todos

Flag detection note: scanning `$ARGUMENTS` here is a simple string-contains
check (e.g., does the arguments string include the literal text `--setup`?).
Full flag parsing with value extraction happens in Step 1; Step 0 only needs to
know whether `--setup` is present to decide whether to skip todo creation.

Before doing anything else, scan `$ARGUMENTS` for `--setup`. If `--setup` is
present, skip the todos and jump directly to Step 0.5.

Otherwise, use `TodoWrite` to create todos for each step:

- Step 1: Resolve plan file
- Step 2: Parse plan content
- Step 3: Prompt for theme
- Step 4: Check for existing output
- Step 5: Synthesize and write HTML
- Step 6: Offer to open in browser
- Step 7: Report

Mark each todo `status: "completed"` as you finish that step.

### Step 0.5 — Setup mode

**Only runs when `--setup` is in `$ARGUMENTS`.** This step writes the pre-built
theme CSS and JavaScript to disk so future invocations can read them directly
instead of re-deriving them from the spec, significantly reducing synthesis time.

1. Run `mkdir -p $HOME/.claude/plan-to-html` to ensure the directory exists
   (use the expanded `$HOME` form — tilde is not expanded by shell when passed
   through Bash restrictions).
2. Attempt to `Read $HOME/.claude/plan-to-html/themes.css`. If the read
   succeeds (content is returned), cache files already exist — ask via
   `AskUserQuestion`: "Cache files already exist in `~/.claude/plan-to-html/`.
   Re-run setup and overwrite them?" Options: `Overwrite` / `Cancel`. Stop if
   the user selects Cancel. Use `Read` rather than `Glob` here because `Glob`
   is scoped to the project workspace and may not match paths outside it.
3. Write `$HOME/.claude/plan-to-html/themes.css`. The first line must be a
   version comment: `/* plan-to-html-cache v1.20.0 */`. Then include the four
   complete theme CSS blocks exactly as defined in `reference/html-spec.md`
   under "Color Palette Themes" (all four `body.theme-*` rule sets).
4. Write `$HOME/.claude/plan-to-html/scripts.js`. The first line must be a
   version comment: `/* plan-to-html-cache v1.20.0 */`. Then include both
   JavaScript feature blocks exactly as defined in `reference/html-spec.md`
   under "JavaScript Features" (scroll-spy IIFE + step-completion IIFE,
   separated by a blank line).
5. Report:

   ```text
   Setup complete.
     $HOME/.claude/plan-to-html/themes.css  — four theme palettes
     $HOME/.claude/plan-to-html/scripts.js  — scroll-spy + step completion
   Re-run --setup after upgrading the plan-interview plugin to refresh cached files.
   ```

6. Stop — do not continue to Step 1.

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

**Flag parsing**: After resolving the file path, also scan `$ARGUMENTS` for
optional flags:

- `--theme=<value>` — accepted values: `default`, `developer`, `document`,
  `minimal`. If present, store as the pre-selected theme; Step 3 will skip its
  `AskUserQuestion` and use this value directly. If the value is not one of the
  four accepted names, ignore the flag and fall back to the Step 3 prompt.
- `--no-open` — if present, Step 6 will skip the browser-open prompt entirely.
- `--background` — enables fully non-interactive mode: auto-selects the
  `default` theme (unless `--theme` is also set), auto-overwrites any existing
  output file without prompting, and implies `--no-open`. Use for automated or
  batch runs where no user interaction is possible.
- `--async` — if present, spawns a background `Agent` after the theme is
  resolved in Step 3, then stops immediately. The main thread returns with a
  "Background conversion started" message; the agent completes HTML generation
  using `--background` mode. Does not imply `--background` on the main thread —
  if `--theme` is not also set, Step 3 still prompts for a theme in the
  foreground before spawning.
- `--setup` — handled in Step 0.5 before this step is reached; documented here
  for completeness.

These flags are intended for batch invocation from other commands. When invoked
interactively without flags, all behavior is unchanged.

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

If `--theme=<value>` was parsed in Step 1, skip the `AskUserQuestion` and use
that value as the selected theme. Proceed directly to the async check below.

If `--background` was parsed and no `--theme` was specified, use `default`
without prompting. Proceed directly to the async check below.

Otherwise, ask the user which color palette to apply via `AskUserQuestion` with
four options:

- **Default** — neutral grays and white, blue accent
- **Developer** — dark charcoal header, green accent (terminal-inspired)
- **Document** — warm off-white background, sepia/brown accent
- **Minimal** — pure white background, black text, no accent color

Store the selected theme name (lowercase, hyphenated) for use in Step 5.

**Async dispatch** (only if `--async` was parsed in Step 1 AND `--background`
was NOT also parsed): now that the theme is known, spawn a background agent and
stop. If both `--async` and `--background` are present, skip this block and
continue to Step 4 — `--background` takes precedence to keep the workflow
synchronous for batch callers.

Call the `Agent` tool, substituting the actual resolved file path and selected
theme name for the angle-bracket placeholders below:

- `subagent_type`: `"general-purpose"`
- `run_in_background`: `true`
- `description`: `"plan-to-html background conversion"`
- `prompt`: a self-contained string such as — `"Invoke
  Skill(skill: \"plan-interview:plan-to-html\", args: \"/actual/path/to/plan.md
  --theme=developer --no-open --background\") to convert the plan to HTML
  non-interactively."` — replace `/actual/path/to/plan.md` and `developer` with
  the real resolved path and selected theme. Quote the path in the `args` string
  if it contains spaces.

The agent re-invokes the skill in `--background` mode (non-interactive, no
`--async` in the args) so it runs the full HTML generation workflow without
spawning a further agent. Then output a confirmation using the actual values:

```
Background conversion started: /actual/path/to/plan.md (theme: developer)
```

Stop here — do not proceed to Steps 4–7. The background agent completes all
remaining work.

### Step 4 — Check for existing output file

Derive the output path: same directory as the resolved plan file, same basename,
`.html` extension replacing `.md`.

Example: `docs/plans/add-auth-flow.md` → `docs/plans/add-auth-flow.html`

Use `Glob` to check whether the output file already exists.

If `--background` was parsed and the file exists, overwrite it automatically
without prompting. Proceed directly to Step 5.

If the file exists and `--background` was not set, ask via `AskUserQuestion`:

> "Output file `<name>.html` already exists. Overwrite?"

Options: `Overwrite` / `Cancel`.

Stop if the user selects Cancel. Proceed if they select Overwrite.

If the file does not exist, proceed directly to Step 5.

### Step 5 — Synthesize and write HTML

**Theme CSS and JavaScript cache check (run before synthesizing):**
Always use the expanded `$HOME` form — tilde is not expanded by `Read` or
`Glob`, and `Glob` is scoped to the project workspace so it may not match paths
outside it. Use `Read` with error semantics for both checks: attempt the read
and branch on whether content is returned.

- Attempt to `Read $HOME/.claude/plan-to-html/themes.css`. If the read succeeds,
  embed its content verbatim as the **theme variables block** inside `<style>`
  — skip re-deriving the four `body.theme-*` rule sets from `reference/html-spec.md`.
  If the read fails (file not found), derive the theme blocks from the spec as usual.
- Attempt to `Read $HOME/.claude/plan-to-html/scripts.js`. If the read succeeds,
  embed it verbatim immediately before `</body>` — **skip the JavaScript section
  below entirely**. If the read fails, generate the JS from the spec as described
  in the JavaScript section below.

Note: the cache covers only theme variable blocks and JavaScript. Layout CSS,
responsive styles, and print styles are always derived from `reference/html-spec.md`
regardless of whether cache files are present.

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

**JavaScript**: Skip this section if `scripts.js` was read from cache (see cache
check above). Otherwise, include a single inline `<script>` block immediately
before `</body>` implementing the two features from `reference/html-spec.md`
("JavaScript Features" section):
1. Scroll spy — `IntersectionObserver` adds `class="active"` to the sidebar link
   for the currently visible section.
2. Step completion — checkboxes restore their `localStorage` state on load,
   toggle the `completed` class on the card, persist changes, and update the
   progress bar fill percentage.

Write the completed HTML to the output path via the `Write` tool.

### Step 6 — Offer to open in browser

If `--no-open` or `--background` was set in Step 1, skip this step entirely.

Otherwise, after writing, ask via `AskUserQuestion`:

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
/plan-interview:plan-to-html --setup                                                          # write theme CSS + JS to ~/.claude/plan-to-html/ (one-time setup)
/plan-interview:plan-to-html                                                                  # auto-detects from IDE or settings
/plan-interview:plan-to-html docs/plans/add-auth-flow.md                                      # specific plan file
/plan-interview:plan-to-html ~/.claude/plans/my-feature.md                                    # absolute path
/plan-interview:plan-to-html docs/plans/add-auth-flow.md --theme=developer                    # pre-select theme, still prompts for browser-open
/plan-interview:plan-to-html docs/plans/add-auth-flow.md --theme=developer --no-open          # batch-safe: no prompts fired
/plan-interview:plan-to-html docs/plans/add-auth-flow.md --background                         # fully non-interactive: default theme, auto-overwrite, no browser open
/plan-interview:plan-to-html docs/plans/add-auth-flow.md --background --theme=developer       # non-interactive with explicit theme
/plan-interview:plan-to-html docs/plans/add-auth-flow.md --async                              # prompts for theme, then spawns background agent and returns immediately
/plan-interview:plan-to-html docs/plans/add-auth-flow.md --async --theme=developer            # fully hands-off: no prompts, spawns background agent immediately
```
