---
status: todo
type: standard
created: 2026-05-13
---

# Plan: Enhance plan-to-html with Unreasonable Effectiveness of HTML

## Context

The existing `plan-to-html` skill (v1.15.0) generates correct but conservative HTML — no JavaScript, raw markdown text dumped into paragraphs, and minimal visual interactivity. Thariq's "The Unreasonable Effectiveness of HTML" (X, May 2026) demonstrates that single-file HTML with embedded CSS and JS is a powerful, shareable artifact format that far exceeds what static-only output can achieve.

The current skill explicitly bans JavaScript and does no markdown rendering, meaning:
- Sidebar nav has no active-section highlighting as the user scrolls
- Step completion cannot be tracked interactively
- Bold, italic, inline code, and links in plan content are rendered as raw symbols
- Fenced code blocks appear as plain text
- No print styles for printing or PDF export

## Objective

Upgrade `skills/plan-to-html/` so the generated HTML is a genuinely rich, interactive artifact:
1. Allow inline `<script>` blocks for progressive enhancement (scroll spy, step completion)
2. Add inline markdown rendering rules so `**bold**`, `*italic*`, `` `code` ``, and `[links](url)` are converted to proper HTML before embedding
3. Add fenced code block rendering with `<pre><code>` structure
4. Add a visual progress indicator derived from plan status
5. Add print styles for clean PDF export
6. Add `scroll-behavior: smooth` and hover effects to step cards
7. Document all changes in `reference/html-spec.md` and update `SKILL.md`

## Steps

1. **Create this plan file** — commit to branch `claude/plans-to-html-XIxHd`

2. **Update `reference/html-spec.md`**
   - Remove "No JavaScript of any kind" restriction
   - Add "JavaScript Features" section: scroll spy (IntersectionObserver), step completion checkboxes (localStorage), smooth scroll
   - Add "Markdown Rendering" section: conversion rules for bold, italic, inline code, links, fenced code blocks
   - Add "Progress Indicator" section: visual bar derived from status badge value
   - Add "Print Styles" section: `@media print` rules for clean output
   - Update CSS to include `scroll-behavior: smooth`, step card hover states, `<code>` inline styling
   - Keep all four theme palettes unchanged

3. **Update `skills/plan-to-html/SKILL.md`**
   - Step 5 (Synthesize and write HTML): replace "no JS" restriction with "inline `<script>` block from spec"
   - Step 5: add markdown rendering requirement referencing the new spec section
   - Step 5: mention progress indicator and print styles

4. **Update `commands/plan-to-html.md`**
   - Mention interactive features (step completion, scroll spy) in the description
   - Update output section to note JS is included

5. **Update `CHANGELOG.md`** — v1.17.0 entry

6. **Bump version in `marketplace.json`** — 1.16.0 → 1.17.0

7. **Commit and push** to `claude/plans-to-html-XIxHd`

## Verification

- `html-spec.md` includes JavaScript Features, Markdown Rendering, Print Styles, and Progress Indicator sections
- `SKILL.md` Step 5 references inline JS and markdown rendering
- No external CDN links or `<script src>` in any spec output
- CHANGELOG has v1.17.0 entry dated 2026-05-13
- `marketplace.json` version is `1.17.0`
- Plan file committed alongside plugin changes

## Unresolved Questions

- Should scroll spy use IntersectionObserver or scroll event listeners? → IntersectionObserver is preferred (performant, no layout thrash)
- Should dark mode (prefers-color-scheme) be added or is theme selection sufficient? → Keep manual theme selection for now; system dark mode adds complexity without clear benefit given themes already cover it
