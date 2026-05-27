---
status: completed
type: enhancement
plugin: social-media-tools (kit/plugins/social-media-tools)
created: 2026-05-27
---

# Plan — "All sites" option + per-site embedded copy snippets

## Context

The `social-media-tools` plugin (`kit/plugins/social-media-tools`, v0.5.0) has five
card-generating skills that each ask the user to pick **one** social platform
(LinkedIn / Twitter/X / Bluesky), draft platform-aware copy, and render a dark-mode
HTML card. Each saved card embeds the post text in a single
`<textarea id="post-copy">` with a **Copy post** button.

The user wants a new **"All sites"** choice on that platform question. When picked,
the generated HTML should embed **a separate, individually copyable snippet for each
site** (LinkedIn, Twitter/X, Bluesky) instead of one combined textarea — so the user
can copy each platform's post on its own.

Decisions confirmed with the user:
- **Scope:** all card-generating skills (not just `code-share`).
- **Single-site behavior:** unchanged — purely additive. Picking one site still
  produces today's single combined copy panel.
- **All-sites layout:** replace the single panel with exactly three labeled per-site
  copy boxes (no combined blob).
- **All-sites tone:** honor the user's selected tone across all three drafts (each
  still respecting that platform's length/style limits).

> Note on `project-share`: it shares the `feature-card.html` / `diff-card.html`
> templates with `code-share`. Because we change those templates' copy panel, it
> **must** be updated alongside the four skills the user named, or its card output
> breaks. It is therefore included — this is a forced scope addition, not optional.

## Approach

All six templates currently use **byte-identical** copy-panel markup:
```html
<div class="copy-panel">
  <p class="copy-label">Social media post</p>
  <textarea readonly class="post-copy-text" id="post-copy">{{POST_COPY_TEXT}}</textarea>
  <button class="copy-btn" onclick="...inline JS targeting #post-copy...">Copy post</button>
</div>
```

Replace that block in every template with a single `{{COPY_PANELS}}` placeholder plus
one shared `copyPost(id, btn)` `<script>` defined once per template. The skill then
injects either **one panel** (single-site, unchanged) or **three panels** (All sites)
into `{{COPY_PANELS}}`. This mirrors the existing "inject full HTML element or empty
string" convention already used for `blog-card.html` conditional variables
(`variables.md` line 83), and keeps the clipboard JS DRY and fixed in the template
rather than re-emitted by the model.

### Template change (all 6 — `templates/`)

`blog-card.html`, `diff-card.html`, `feature-card.html`, `quote-card.html`,
`snippet-card.html`, `video-card.html`:

1. Replace the whole `<div class="copy-panel">…</div>` block with `{{COPY_PANELS}}`.
2. Add once, just before `</body>`:
   ```html
   <script>
     function copyPost(id, btn) {
       var t = document.getElementById(id), orig = btn.textContent;
       function done() { btn.textContent = 'Copied ✓';
         setTimeout(function () { btn.textContent = orig; }, 2000); }
       if (navigator.clipboard) { navigator.clipboard.writeText(t.value).then(done); }
       else { t.select(); document.execCommand('copy'); done(); }
     }
   </script>
   ```
3. Update each template's top variable-comment block: drop `{{POST_COPY_TEXT}}`, add
   `{{COPY_PANELS}}` (full HTML for the copy panel(s); see variables.md).

### Shared spec (`skills/code-share/references/variables.md`)

Replace the `## POST_COPY_TEXT (all card types)` section with `## COPY_PANELS (all
card types)` documenting the markup the skill must emit. Same `&`→`&amp;`,
`<`→`&lt;`, `>`→`&gt;` escaping (applied per variant). Two forms:

- **Single site** (unchanged output): one panel — label `Social media post`,
  `id="post-copy"`, content = all variants joined with `\n---\n` (today's behavior),
  button `onclick="copyPost('post-copy', this)"`.
- **All sites**: three stacked panels, one per platform —
  `id="post-copy-linkedin" | post-copy-twitter | post-copy-bluesky`, labels
  `LinkedIn` / `Twitter/X` / `Bluesky`, buttons
  `onclick="copyPost('post-copy-linkedin', this)"` (etc.) reading
  `Copy LinkedIn post` / `Copy Twitter/X post` / `Copy Bluesky post`. Each textarea
  holds only that platform's escaped copy.

All panels keep `class="post-copy-text"` so extraction can match by class.

### Per-skill changes (5 skills)

`code-share`, `blog-share`, `video-share`, `github-code-share`, `project-share`
each follow the same pattern, so apply the same four edits to each SKILL.md:

1. **Platform input / AskUserQuestion** (the "Required inputs" / Phase 1 list that
   currently reads `LinkedIn, Twitter/X, or Bluesky`): add a fourth option
   **`All sites`** — "draft and embed all three platforms".
2. **Draft phase** (the `POST_COPY_TEXT_RAW` step): skills already draft all three
   variants. Single-site → keep joining with `\n---\n` (unchanged). All sites → keep
   the three variants **separate** (per platform) for the panels, drafting each in the
   user's chosen tone (each variant still respecting that platform's length/style).
3. **Populate phase**: replace the `{{POST_COPY_TEXT}}` substitution instruction with
   a `{{COPY_PANELS}}` build — one panel for a single site, three for All sites. Carry
   the panel-markup skeleton **inline in each SKILL.md** (with variables.md as the
   authoritative reference); do not rely solely on a cross-skill pointer to
   variables.md, since other skills may not read it.
4. **Deliver phase**: single-site unchanged. All sites → present three labeled fenced
   blocks, each with its own `[NNN / max]` count (1,500 / 280 / 300) and per-platform
   over-limit warning, under one `## Copy — all sites` heading.

### Reuse extraction (`media-library` + each skill's Phase 1c reuse check)

Today these extract `<textarea class="post-copy-text" id="post-copy">…`. Change them
to match **by class** (`class="post-copy-text"`), returning 1 (single) or 3 (All
sites) textareas, and present each labeled by its preceding `copy-label`. This keeps
old single-site files working and reads the new per-site files correctly.

### Docs + version (MINOR: 0.5.0 → 0.6.0)

- `.claude-plugin/marketplace.json`: bump `social-media-tools` `version` to `0.6.0`
  (the auto-validate hook will check JSON syntax on save).
- `kit/plugins/social-media-tools/CHANGELOG.md`: add a `## v0.6.0` entry describing
  the All-sites option, `{{COPY_PANELS}}` template variable + shared `copyPost()`,
  and per-site copy snippets.
- `kit/plugins/social-media-tools/README.md`: note the All-sites choice in the
  relevant skill/usage sections.
- Rename this plan file to a descriptive name (run `/plan-hygiene`) and commit it with
  the change (per CLAUDE.md plan-hygiene rule).

## Files to modify

- Templates (6): `templates/{blog,diff,feature,quote,snippet,video}-card.html`
- Shared spec: `skills/code-share/references/variables.md`
- Skills (5): `skills/{code-share,blog-share,video-share,github-code-share,project-share}/SKILL.md`
- Reuse: `skills/media-library/SKILL.md` (+ the Phase 1c block in each of the 5 skills)
- `.claude-plugin/marketplace.json`, `kit/plugins/social-media-tools/CHANGELOG.md`,
  `kit/plugins/social-media-tools/README.md`

## Risks & safeguards

- **Orphaned placeholder (top risk):** changing the template contract means any skill
  left on `{{POST_COPY_TEXT}}` renders a literal broken `{{COPY_PANELS}}`. After all
  edits, grep-sweep the repo: there must be **zero** `{{POST_COPY_TEXT}}` references
  remaining, and `{{COPY_PANELS}}` must appear in all 6 templates. variables.md says
  "six card-generating skills" but only **5** generators exist (`code-share`,
  `blog-share`, `video-share`, `github-code-share`, `project-share`); confirm no
  generator is missed and fix the doc's count.
- **Tall card / screenshot:** three stacked panels lengthen the page. Confirm the card
  PNG still renders the card cleanly; add a small top margin between stacked
  `.copy-panel` divs if they touch.
- **Old saved files:** matching by `class="post-copy-text"` (not `id`) keeps pre-0.6.0
  single-textarea files extractable by `media-library` and reuse.

## Verification

1. **JSON + sweep:** confirm `marketplace.json` parses (`python3 -m json.tool` / hook
   passes); grep the repo for `{{POST_COPY_TEXT}}` (expect none) and confirm
   `{{COPY_PANELS}}` is present in all 6 templates and substituted by all 5 skills.
2. **All sites, end-to-end:** load the plugin
   (`claude --plugin-dir ./kit/plugins/social-media-tools`), run `code-share`, choose
   **All sites**. Confirm: three fenced copy blocks delivered with per-site counts;
   saved `docs/media/social/…html` contains three `<textarea class="post-copy-text">`
   with ids `post-copy-linkedin|twitter|bluesky` and three working **Copy …** buttons.
3. **Browser check:** open the saved HTML; click each per-site button and confirm it
   copies only that platform's text (clipboard + execCommand fallback), and that the
   three `.copy-panel` boxes are visually separated with sane spacing.
   Confirm the generated PNG still shows the card cleanly (panels below it).
4. **Single-site regression:** run again choosing only **LinkedIn**; confirm output is
   identical to today — one `id="post-copy"` panel, combined copy, one fenced block.
5. **Shared-template regression:** run `project-share` (uses feature/diff-card) for
   both a single site and All sites to confirm the template swap didn't break it.
6. **Reuse:** run a skill again so Phase 1c finds the new All-sites file, and run
   `media-library`; confirm both extract and label all three per-site snippets.
7. **Plan hygiene:** confirm this plan file has a descriptive (non-timestamp) name
   and YAML frontmatter, and that the pre-commit plan-rename check in
   `.claude/rules/plan-hygiene.md` reports no violations before committing.
