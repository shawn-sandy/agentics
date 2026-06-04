# Add plan-to-html Skill to plan-interview Plugin

> Adds a `/plan-interview:plan-to-html` command and skill that converts any plan markdown file into a rich, self-contained HTML file with sticky sidebar, color-coded status badge, and themed layout.

<!-- generated:start -->

**Status:** Shipped 2026-05-11  **Plan:** [add-plan-to-html-skill-to-plan-interview.md](plans/add-plan-to-html-skill-to-plan-interview.md)
**Type:** artifact

## What shipped

- Added `skills/plan-to-html/SKILL.md` implementing a 7-step workflow: resolve plan file, parse frontmatter and sections, prompt for theme, check for existing output, synthesize and write HTML, offer browser open, and report path (keeping SKILL.md concise by offloading layout rules to the reference file).
- Added `skills/plan-to-html/reference/html-spec.md` as the single source of truth for the HTML layout contract — required sections, step card structure, status badge colors, four named themes, semantic element rules, and responsive breakpoint (mirrors the precedent of `plan-interview/reference/skill-checklist.md`).
- Added `commands/plan-to-html.md` as the explicit invocation surface (`/plan-interview:plan-to-html [path]`) with `allowed-tools` declaring `Read, Glob, Grep, Bash(open *), Write, TodoWrite, AskUserQuestion`.
- Updated `kit/plugins/plan-interview/CHANGELOG.md` with a MINOR bump entry for the new command, skill, and reference file.
- Bumped `plan-interview` version in `.claude-plugin/marketplace.json` by one MINOR increment (landed as v1.15.0).
- Updated `kit/plugins/plan-interview/README.md` with a row for `plan-to-html` in the features/commands table.
- Output is fully self-contained HTML: all CSS inline in `<style>`, no external dependencies, no JavaScript (clipboard button removed after interview review confirmed pure read→write conversion).

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/plan-interview/skills/plan-to-html/SKILL.md` | Skill instructions | Created |
| `kit/plugins/plan-interview/skills/plan-to-html/reference/html-spec.md` | Reference spec | Created |
| `kit/plugins/plan-interview/commands/plan-to-html.md` | Command wrapper | Created |
| `kit/plugins/plan-interview/CHANGELOG.md` | Changelog | Modified |
| `kit/plugins/plan-interview/README.md` | Plugin documentation | Modified |
| `.claude-plugin/marketplace.json` | Marketplace entry | Modified |

## How it works

The skill is activated by running `/plan-interview:plan-to-html [plan-file-path]` or automatically when the keyword phrase is matched. Step 0 writes progress todos so the user has visibility; Step 1 resolves the target plan file using the same 5-step priority order as all other plan-interview skills (explicit argument → most recent plan file → ask).

Step 2 parses frontmatter fields (`status`, `created`, `modified`) and all `##` section headings including `## Interview Summary` when present. Missing fields are treated as `unknown` or `n/a` rather than causing errors, allowing the skill to handle partial plans gracefully.

Step 3 prompts the user to choose from four named themes — Default, Developer, Document, Minimal — which differ only in color palette (header, sidebar, accent, link colors) while keeping the layout identical. Step 4 checks for a pre-existing `<plan-basename>.html` and asks before overwriting.

Step 5 synthesizes the HTML following `reference/html-spec.md`: a sticky `<nav>` sidebar with anchor links, `<ol><li>` step cards with three visual rows (action in `<h3>`, why in muted text, verify prefixed with a checkmark), a metadata row with status badge and creation date, and a responsive single-column layout below 768px. All styles are inlined; no `<link>` or `<script>` tags reference external resources.

Steps 6 and 7 offer to open the file in a browser (`open <file>` on macOS via `AskUserQuestion`) and print a one-line summary `"Written to <path> (theme: <name>)"`.

The layout contract lives in `reference/html-spec.md` rather than embedded in `SKILL.md`, following the same pattern as `plan-interview/reference/skill-checklist.md` and keeping the skill under the 500-line quality limit.

## How to use it

```
# Run with no arguments — auto-detects most recent plan file
/plan-interview:plan-to-html

# Run with an explicit path
/plan-interview:plan-to-html docs/plans/my-plan.md
```

After running, select a theme from the four options (Default / Developer / Document / Minimal). The HTML file is written to the same directory as the source plan with `.html` replacing `.md`. To regenerate with a different theme, run the command again and choose Overwrite when prompted.

To wire HTML generation into other plan-interview workflows, see the Next Steps section of the plan — integration points for Step 6 of `plan-interview` and Step 8 of `documenting-plans` are documented there.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `4d641ad` | 2026-05-11 | feat(plan-interview): add plan-to-html skill and command (v1.15.0) (#106) |
| `af01082` | 2026-05-13 | feat(plan-interview): upgrade plan-to-html with interactive JS, markdown rendering, and print styles (v1.17.0) |
| `bd738a9` | 2026-05-13 | feat(plugins/plan-interview): add html output to rename commands |
| `eadc0ab` | 2026-05-14 | feat(plugins/plan-interview): add --setup cache and --background mode to plan-to-html, bump to v1.20.0 (#115) |
| `e3fb689` | 2026-05-14 | feat(plugins/plan-interview): add --async flag to plan-to-html for background execution, bump to v1.22.0 (#117) |
| `d0a8fa7` | 2026-05-15 | fix(kit/plugins/product-plans): address Codex/Copilot PR #120 review comments |

<!-- generated:end -->

## References

- Plan: [add-plan-to-html-skill-to-plan-interview.md](plans/add-plan-to-html-skill-to-plan-interview.md)
