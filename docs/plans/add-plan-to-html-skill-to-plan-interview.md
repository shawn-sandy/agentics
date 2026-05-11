---
status: completed
type: standard
created: 2026-05-11
---

# Plan: Add plan-to-html Skill to plan-interview Plugin

## Context

The `plan-interview` plugin currently outputs all artifacts as markdown files. Markdown plans longer than ~100 lines are hard to read and impossible to share as a browser link. Thariq's article "The Unreasonable Effectiveness of HTML" (X, May 2026) makes the case that HTML is a richer, more shareable, and more readable format for plans and specs — supporting tabs, color, visual step structure, and mobile responsiveness.

This plan adds a new `plan-to-html` skill and command to the `plan-interview` plugin. Given a plan markdown file, the skill generates a rich, self-contained HTML file (no external dependencies, no JavaScript) that can be opened in any browser or shared via a file host. The conversion is purely read→write: no clipboard interaction, no interactivity beyond standard browser navigation.

## Objective

Add a `plan-to-html` command and skill to `kit/plugins/plan-interview/` that reads any plan `.md` file and writes a rich, self-contained `.html` file to the same directory. The output uses a sticky sidebar, three-line step cards (action / why / verify), a color-coded status badge, and semantic HTML — all styles inline, no external dependencies.

## Steps

<ol>

<li>

**Create `skills/plan-to-html/reference/html-spec.md`** — write the companion reference file that contains the full HTML layout contract: required sections, semantic element rules, step card structure, status badge colors, responsive breakpoint, and graceful unknown-state behavior. This file is referenced by the SKILL.md rather than embedded in it, keeping the skill under 500 lines.

The spec must document:
- **Required sections**: Context, Objective, Steps, Verification, Next Steps, Unresolved Questions (if present), Interview Summary (if present in plan)
- **Navigation**: sticky sidebar using `<nav aria-label="Plan sections">`, anchor links to each section
- **Step card structure**: `<ol><li>` per step; each `<li>` has three visual rows — action (bold, `<h3>`), why (muted), verify (checkmark-prefixed)
- **Status badge**: `todo` → gray, `in-progress` → amber, `completed` → green, absent/unknown → gray with "unknown" text
- **Color palette themes** (4 named options, applied to header, sidebar, accent, and link colors only — layout is identical across themes):
  - `Default` — neutral grays and white, blue accent
  - `Developer` — dark charcoal header, green accent (terminal-inspired)
  - `Document` — warm off-white background, sepia/brown accent
  - `Minimal` — pure white background, black text, no accent color
- **Semantic rules**: `<h1>` plan title, `<h2>` section names, `<h3>` step actions; `<main>`, `<nav>`, `<header>` landmarks; color contrast ≥ 4.5:1 for all text; touch targets ≥ 44×44px for any interactive elements
- **Metadata row**: title, status badge, created/modified dates, and selected theme name — render `n/a` if frontmatter fields are absent
- **Responsive**: single-column below 768px (sidebar collapses above content), two-column above
- **Self-contained**: all CSS inline in `<style>`, no `<link>` or `<script src>` to external resources, no JavaScript

- *Why:* Keeping the layout contract in a reference file follows the same pattern as `plan-interview/reference/skill-checklist.md` and prevents the SKILL.md from exceeding the 500-line quality limit.
- *Verify:* Read the written file; confirm it covers all seven bullet groups above and is referenced by name in the SKILL.md written in Step 2.

</li>

<li>

**Create `skills/plan-to-html/SKILL.md`** — write the full skill instructions with these steps:

- **Step 0**: `TodoWrite` progress todos
- **Step 1**: Resolve plan file (same 5-step priority order as all other skills in this plugin)
- **Step 2**: Parse plan content — extract frontmatter (`status`, `created`, `modified`), H1 title, and all `##` sections including `## Interview Summary` if present; treat missing fields as `unknown`/`n/a`
- **Step 3**: Prompt for theme — ask via `AskUserQuestion`: "Which theme?" with four options matching those defined in `reference/html-spec.md` (Default, Developer, Document, Minimal). Store the selection for use in Step 4.
- **Step 4**: Check for existing output file — if `<plan-basename>.html` already exists in the same directory, ask via `AskUserQuestion`: "Overwrite existing `<name>.html`?" (Overwrite / Cancel). Stop if cancelled.
- **Step 5**: Synthesize and write HTML — apply the theme palette from Step 3; follow `reference/html-spec.md` for layout, semantics, and style rules; write via `Write` tool to `<same-dir>/<plan-basename>.html`
- **Step 6**: Offer to open in browser — ask via `AskUserQuestion`: "Open in browser?" and run `open <file>` (macOS) if confirmed
- **Step 7**: Report — output a one-line summary: `"Written to <path> (theme: <name>)"`

- *Why:* The skill body drives execution; the reference file keeps it concise.
- *Verify:* Read the written file; confirm YAML frontmatter has `name: plan-to-html` and `description:`, body is under 500 lines, Step 3 theme prompt is present with all 4 options, Step 4 collision check is present, `## Interview Summary` is mentioned in Step 2's parse list, and `reference/html-spec.md` is referenced in Step 5.

</li>

<li>

**Create `commands/plan-to-html.md`** — write the command wrapper with frontmatter (`description`, `allowed-tools: Read, Glob, Grep, Bash, Write, Edit, TodoWrite, AskUserQuestion`, `argument-hint: "[plan-file-path]"`), a short description, usage examples, and a reference to the skill file.

- *Why:* Commands are the explicit invocation surface (`/plan-interview:plan-to-html [path]`). Both the skill and the command should declare `allowed-tools` — the skill's declaration prevents mid-run permission prompts; the command's declaration documents the required capabilities for explicit invocation.
- *Verify:* Read the written file; confirm YAML frontmatter includes `allowed-tools` with `Write` listed, and at least 2 usage examples appear.

</li>

<li>

**Update `kit/plugins/plan-interview/CHANGELOG.md`** — add a MINOR bump entry (`feat`) documenting the new `plan-to-html` skill, command, and reference file.

- *Why:* Adding a new user-facing command/skill is a MINOR version bump per the marketplace versioning rules in `.claude/rules/marketplace.md`.
- *Verify:* Read CHANGELOG.md; confirm a new entry exists at the top matching the `feat(kit/plugins/plan-interview): bump version to X.Y.Z` convention and references both new files.

</li>

<li>

**Bump version in `.claude-plugin/marketplace.json`** — increment the `plan-interview` plugin version by one MINOR version (e.g., current → current+0.1.0).

- *Why:* The marketplace uses `marketplace.json` as the authoritative version source for relative-path plugins; `plugin.json` must NOT receive a version field.
- *Verify:* Read `.claude-plugin/marketplace.json`; confirm the `plan-interview` entry's `"version"` field was incremented and that `kit/plugins/plan-interview/.claude-plugin/plugin.json` has no `version` field.

</li>

<li>

**Update `kit/plugins/plan-interview/README.md`** — add a row to the features table for `plan-to-html` with invocation syntax and a brief description.

- *Why:* Plugin READMEs are the user-facing documentation; the new command is invisible until it appears there.
- *Verify:* Read README.md; confirm the new command appears in the features/commands table with the correct invocation format `/plan-interview:plan-to-html [path]`.

</li>

</ol>

## Verification

1. Load the plugin: `claude --plugin-dir ./kit/plugins/plan-interview`
2. Open or point at any existing plan `.md` file in the project.
3. Run `/plan-interview:plan-to-html` (no arguments — auto-detect).
4. Confirm a `.html` file is written to the same directory as the plan.
5. Open the `.html` file in a browser: verify the title renders, status badge appears with correct color, sticky sidebar shows section links, numbered steps are visible with three-line card structure (action / why / verify), and missing frontmatter fields show `unknown`/`n/a`.
6. Confirm the chosen theme palette is applied (e.g., selecting `Developer` produces a dark charcoal header; `Minimal` produces pure white/black).
7. Resize the browser to <768px; verify layout switches to single-column.
8. Run the command a second time; confirm the theme prompt appears again and the overwrite prompt follows.
9. Confirm the HTML file has no external `src` or `href` attributes pointing to CDNs or external hosts, and no `<script>` tags.

## Next Steps

- Wire HTML generation into `plan-interview` Step 6 ("Offer to save findings") as an additional offer.
- Wire HTML generation into `documenting-plans` Step 8 as an optional output format alongside the `.md` doc.
- Add dark mode via `prefers-color-scheme` media query once light-mode baseline is stable.

---

## Interview Summary

**Interviewed:** 2026-05-11 | **Mode:** plan-review

### Key Decisions Confirmed

- Template: named-section contract (specify required sections and constraints; leave visual implementation to Claude)
- Output path: same directory as source plan, `.html` extension replacing `.md`
- Navigation: sticky sidebar anchoring to named sections
- Step layout: three-line card — action (bold `h3`) / why (muted text) / verify (checkmark-prefixed row)
- Missing metadata: render gracefully with `unknown` / `n/a`
- Semantic requirements: `h1→h2→h3` hierarchy, `<nav>` landmark, `<ol><li>` for steps, contrast ≥ 4.5:1
- Dark mode: light-only for now
- Browser open: offer via `AskUserQuestion` after write
- No clipboard/copy button: pure read→write conversion, no JavaScript

### Open Risks & Concerns

- **Copy button contradiction resolved**: original plan included a JS clipboard button; user confirmed no interactivity — removed from spec.
- **500-line SKILL.md limit**: mitigated by adding `reference/html-spec.md` companion file (Step 1).
- **Overwrite behavior**: now addressed in Step 4 (collision check via `AskUserQuestion`).
- **Interview Summary section**: now explicitly included in Step 2 parse list.

### Recommended Next Steps

1. Remove SVG diagram generation entirely (done — never added to updated plan).
2. Keep `reference/html-spec.md` as the single source of truth for layout rules so the SKILL.md stays under 500 lines.
3. Confirm CHANGELOG and marketplace.json version bump at implementation time by checking current version in `marketplace.json`.

### Simplification Opportunities

- **No JavaScript**: removing the clipboard button makes the output a purely static HTML document — simpler, more portable, no script-blocking browser warnings.
- **No SVG diagrams**: three-line step cards achieve the visual goal without requiring diagram generation logic.
