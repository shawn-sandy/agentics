---
status: completed
type: refactor
created: 2026-05-27
modified: 2026-05-27
repo-name: agentics
---

# Plan: Extract shared card-pipeline logic into a plugin-root references/ folder

> **Filename note:** this file's slug (`all-skills-in-the-purrfect-perlis`) is an
> auto-generated placeholder. Per plan-mode §4, rename it to
> `extract-shared-references-social-media-tools.md` before commit (a Step below
> handles this).

## Context

The `social-media-tools` plugin (marketplace name `code-share`, currently **v0.6.0**)
has 5 card-generating skills — `code-share`, `project-share`, `github-code-share`,
`video-share`, `blog-share` — that share one pipeline: locate templates → draft
platform-aware copy → populate an HTML template → save persistent HTML to
`docs/media/social/` → render via local-HTTP-server + Playwright → deliver. Large
chunks of that pipeline are copy-pasted **byte-for-byte** across all 5 SKILL.md files.

This duplication has a measured cost: the recent "PNG beside HTML" change had to touch
7 files and the `gap: 3rem → 2rem` change touched 6 — the same edit repeated N times.
This is established, repeated duplication with a proven maintenance tax, not premature
abstraction.

The user wants the duplicated commands/code/rules pulled into a shared **reference
folder** so each skill shrinks and a single edit propagates everywhere. Scope is
confirmed **skills-only** (templates' CSS/JS duplication is explicitly out of scope this
round), and `project-share` — the only card skill lacking a reuse check — will **adopt**
the shared reuse check for consistency.

## Objective

Create a plugin-root `references/` folder holding the blocks duplicated across the 5
card skills, and rewrite each SKILL.md to set a few per-skill variables and **point** to
those references instead of inlining ~80–120 lines apiece. No change to rendered card
output; the only behavior change is `project-share` gaining the reuse check.

## What is duplicated (confirmed by inspection)

| Block | In which skills | Sameness |
|-------|-----------------|----------|
| Templates/plugin-dir probe | all 5 | command lines byte-identical |
| Render pipeline (find_free_port → http.server → Playwright → kill → fallback) | all 5 | constants byte-identical |
| Persistent-save block (`MEDIA_DIR`/`SLUG`/`DATE`/`SAVE_PATH`/`SAVE_PATH_PNG`) | all 5 | `SLUG` line byte-identical |
| Deliver phase (`SendUserFile` + `open`/`xdg-open` + saved-path note) | all 5 | `open` line byte-identical |
| `{{COPY_PANELS}}` markup + textarea escaping | all 5 | identical; already in `code-share/references/variables.md` |
| Reuse check (Phase 1c) | 4 of 5 (not `project-share`) | verbose vs compact variants |
| Platform char-limit/tone **table** | all 5 | numbers identical; surrounding copy formats differ per skill |

`variables.md` (the per-template variable maps) lives under `code-share/references/`
but documents **all 6 templates** — it is plugin-wide content mislocated in one skill's
folder, which is why the other four reach into `../code-share/references/`.

## Design

**New plugin-root folder:** `kit/plugins/social-media-tools/references/`

| File | Holds | Replaces inline copies in |
|------|-------|---------------------------|
| `rendering-pipeline.md` | server start → Playwright navigate + screenshot to `$SAVE_PATH_PNG` → kill → Playwright-unavailable fallback | all 5 |
| `reuse-check.md` | the Phase 1c "scan `docs/media/social/` for a matching slug, offer reuse" procedure | 4 skills + **new** for `project-share` |
| `saving-and-delivery.md` | persistent-save block + deliver phase | all 5 |
| `copy-panels.md` | `{{COPY_PANELS}}` single- vs 3-panel markup + textarea-safe escaping | all 5 (moved out of `variables.md`) |
| `variables.md` | per-template variable maps (relocated from `code-share/references/`, minus COPY_PANELS) | the 4 cross-skill pointers |
| `platforms.md` | shared char-limit/tone table + universal cross-platform rules (URL=23 chars, lead-with-insight, attribute on Bluesky) | the 3 inline tables (code/project/github) |

**Stays per-skill (genuinely skill-specific):** `github-code-share/references/language-map.md`,
`project-share/references/topics.md`, `security-scrub/references/scrub-rules.md`,
`scan-for-shares/references/interesting-patterns.md`. The existing
`blog-share/references/platforms.md` and `video-share/references/platforms.md` are
**trimmed** to their skill-specific copy formats/examples (and video's oEmbed API table),
pointing at the shared `references/platforms.md` for canonical limits — not deleted,
because their copy templates are content-specific and valuable.

**Stays inline in every SKILL.md (by necessity / judgement):**
- The templates/plugin-dir probe — it is the *bootstrap* that resolves `PLUGIN_DIR`,
  which is required to `Read` any reference. Promote it to a new **Phase 0: Locate plugin
  assets** so `TEMPLATES_DIR` and `PLUGIN_DIR` are available to every later phase.
- Each skill's unique logic (git detect, oEmbed fetch, GitHub URL parse, topic queries,
  manifest extraction, etc.) and the small per-skill variable assignments before each
  pointer (`$SLUG_INPUT`, `$CARD_TYPE`, `$TEMP_HTML`, `$SAVE_PATH_PNG`).
- The 7-line WebFetch `ToolSearch select:` bootstrap (github/video/blog) — left inline:
  too small to be worth a reference round-trip, and it is a repo-wide documented pattern.

**Addressing mechanism:** reuse the skills' existing try-paths resolver (which already
yields `TEMPLATES_DIR`, then `PLUGIN_DIR=$(dirname "$TEMPLATES_DIR")`) and `Read`
`$PLUGIN_DIR/references/<file>.md`. This is the proven-in-skill-bodies pattern here; do
**not** introduce `${CLAUDE_PLUGIN_ROOT}` into skill bodies (only proven in hooks/commands).
Precedent: `settings-sync` already shares a plugin-root `references/file-manifest.md`
across two skills; this plugin already shares `scripts/` and `templates/` at the root.

## Steps

1. **Create the 6 plugin-root reference files.** Author `references/{rendering-pipeline,
   reuse-check,saving-and-delivery,copy-panels,variables,platforms}.md`. Lift the exact
   current text from `code-share/SKILL.md` (the canonical source) for pipeline/save/deliver/
   reuse-check; move the `## COPY_PANELS` section out of `code-share/references/variables.md`
   into `copy-panels.md`; relocate the rest of `variables.md` to the plugin root; distil the
   shared platform table + universal rules into `platforms.md`. Each procedural file names
   the input vars it expects (e.g. rendering-pipeline expects `$TEMP_HTML`, `$SAVE_PATH_PNG`,
   `$PLUGIN_DIR`).
   - *Why:* One authoritative copy of each block; everything downstream points here.
   - *Verify:* `ls kit/plugins/social-media-tools/references/` shows all 6 files;
     `grep -c "find_free_port" references/rendering-pipeline.md` ≥ 1;
     `grep -n "COPY_PANELS" references/copy-panels.md` matches and the section is **gone**
     from `code-share/references/variables.md`.

2. **Rewrite `code-share/SKILL.md` to the pointer skeleton.** Add **Phase 0: Locate plugin
   assets** (the existing probe → `TEMPLATES_DIR`, `PLUGIN_DIR`). Replace the inline reuse
   check, platform table, COPY_PANELS markup, save block, render pipeline, and deliver phase
   with one-line pointers to the matching `$PLUGIN_DIR/references/*.md`, preceded by the
   per-phase variable assignments. Keep all `code-share`-unique logic (git auto-detect,
   diff/feature/quote template-pick).
   - *Why:* `code-share` is the canonical skill the others mirror; its skeleton becomes the
     template for Steps 3–6.
   - *Verify:* `wc -l code-share/SKILL.md` is materially lower (target ≤ ~150);
     `grep -n "references/" code-share/SKILL.md` shows pointers to all 6 files;
     the temp-HTML server source line is still present.

3. **Rewrite `project-share/SKILL.md`** to the same skeleton (Phase 0 probe + pointers),
   **and wire in the shared reuse check** it currently lacks (point Phase 1c at
   `references/reuse-check.md`). Preserve project-specific logic (topic parsing, manifest
   extraction, `security-scrub` invocation, feature/diff variable use).
   - *Why:* Removes the largest per-skill duplication and closes the reuse-check
     inconsistency the user approved fixing.
   - *Verify:* `grep -n "reuse-check" project-share/SKILL.md` matches (new);
     `grep -n "references/rendering-pipeline\|saving-and-delivery\|platforms" project-share/SKILL.md`
     all match; topic logic intact.

4. **Rewrite `github-code-share/SKILL.md`** to the skeleton. Keep its unique logic (GitHub
   URL parse + `#L` fragment, WebFetch raw fetch + 4xx private-repo handling, mandatory code
   HTML-escape incl. `&quot;`, `security-scrub` via temp file, `language-map.md` lookup).
   Point shared phases at the references; keep the WebFetch bootstrap inline.
   - *Why:* Same pipeline (`snippet-` prefix); only the fetch/escape front-end is unique.
   - *Verify:* pointers to the 6 references present; `language-map.md` still referenced;
     the 4-step code-escape block retained inline.

5. **Rewrite `video-share/SKILL.md`** and **`blog-share/SKILL.md`** to the skeleton. For
   each, trim its own `references/platforms.md` to skill-specific copy formats/examples
   (video keeps its oEmbed API table) and point the canonical limits at the shared
   `references/platforms.md`. Keep video's oEmbed fetch + `{{THUMBNAIL_ZONE}}`/`{{PLATFORM_COLOR}}`
   handling and blog's dual-source (URL vs local md) + OG/front-matter extraction +
   `{{READ_TIME_BADGE}}`/`{{TAGS_FOOTER}}`.
   - *Why:* Same pipeline (`video-`/`blog-` prefixes); their platform files become
     skill-specific overrides rather than full copies.
   - *Verify:* both SKILL.md show the 6 reference pointers; each trimmed `platforms.md`
     no longer restates the shared char-limit table but links to it; unique injection logic
     intact.

6. **Rename the plan file + docs/version bump.** Rename this plan to
   `extract-shared-references-social-media-tools.md`. Bump `social-media-tools` to **v0.7.0**
   in `.claude-plugin/marketplace.json`; add a v0.7.0 `CHANGELOG.md` entry (shared
   `references/` extraction + `project-share` reuse check); update `README.md` **Plugin
   Structure** tree to show the new `references/` folder, and any Components line that points
   at a relocated reference path.
   - *Why:* Convention requires version + CHANGELOG + README sync for structural changes
     (`.claude/rules/marketplace.md`); plan-mode §4 requires a meaningful filename.
   - *Verify:* `marketplace.json` shows `"version": "0.7.0"` and stays valid JSON (settings
     hook auto-validates); CHANGELOG top entry is v0.7.0; README tree lists `references/`;
     the plan filename matches `verb-target` form.

## Acceptance Criteria

- [ ] `kit/plugins/social-media-tools/references/` contains `rendering-pipeline.md`, `reuse-check.md`, `saving-and-delivery.md`, `copy-panels.md`, `variables.md`, `platforms.md`.
- [ ] All 5 card SKILL.md files start with **Phase 0: Locate plugin assets** and replace the duplicated pipeline/save/deliver/reuse/COPY_PANELS/platform-table blocks with one-level-deep pointers to `$PLUGIN_DIR/references/*.md`.
- [ ] `project-share` now runs the shared reuse check; the other 4 keep theirs via the shared file.
- [ ] The `## COPY_PANELS` section is gone from `code-share/references/variables.md` and lives in `references/copy-panels.md`; the per-template variable maps live in `references/variables.md`.
- [ ] `blog-share`/`video-share` `references/platforms.md` retain only skill-specific copy formats (video keeps oEmbed table) and defer canonical limits to `references/platforms.md`.
- [ ] No rendered-card output change; each SKILL.md is materially shorter (target ≤ ~150 lines).
- [ ] `marketplace.json` lists `social-media-tools` at v0.7.0 (valid JSON); CHANGELOG + README reflect the extraction; plan renamed to `extract-shared-references-social-media-tools.md`.
- [ ] No skill points into another skill's `references/` (no `../code-share/references/` cross-pointers remain).

## Verification

With the plugin loaded (`claude --plugin-dir kit/plugins/social-media-tools`):

1. **Static** — `grep -rn "\.\./code-share/references" kit/plugins/social-media-tools/skills/`
   returns nothing (no cross-skill pointers); `grep -rln "references/rendering-pipeline.md"
   skills/` lists all 5 card skills; `python3 -c "import json,sys;
   json.load(open('.claude-plugin/marketplace.json'))"` exits 0.
2. **code-share end-to-end** — run it on a recent diff; confirm the saved HTML+PNG pair
   still lands in `docs/media/social/` exactly as before (output unchanged), proving the
   referenced pipeline executes correctly.
3. **project-share reuse check** — run it twice for the same topic; the second run must
   detect the already-saved post and offer reuse (the newly wired behavior).
4. **One more skill** — run `video-share` (or `blog-share`); confirm the card renders
   identically to pre-refactor and platform copy still respects 1500/280/300 limits sourced
   from the shared `platforms.md`.
5. **Maintenance proof** — make a trivial edit to `references/saving-and-delivery.md` (e.g.
   reword the saved-path note) and confirm all 5 skills would reflect it without further
   edits — the core goal of the refactor.

## Next Steps *(optional)*

- Consolidate the duplicated template CSS/JS (the deferred second axis):
  ```text
  In kit/plugins/social-media-tools/templates/, the 6 card HTML files duplicate an
  identical copyPost(id, btn) JS function, the body flex-column rule (gap: 2rem), the CSS
  reset, and the entire .copy-panel/.copy-label/.post-copy-text/.copy-btn cluster. Extract
  the shared CSS into templates/_shared.css (using a --card-width CSS var set inline per
  template) and the JS into templates/_copy-panel.js, and have each card link them with
  relative <link>/<script src> tags (they are served from templates/ over the local HTTP
  server, so relative paths resolve). Keep per-template runtime CSS injection inline
  (snippet LANGUAGE_COLOR, video PLATFORM_COLOR; quote's serif body font). Re-screenshot all
  6 cards via the find_free_port → http.server → Playwright pipeline to confirm
  pixel-identical rendering before and after. Bump the plugin version + CHANGELOG.
  ```

- Align the two adjacent folder-reading skills on the shared filename convention:
  ```text
  scan-for-shares (Step 4b) and media-library both hardcode MEDIA_DIR="${PWD}/docs/media/social"
  and the {type}-{slug}-{date} filename convention that is now canonically defined in
  kit/plugins/social-media-tools/references/saving-and-delivery.md. Update both skills to
  reference that canonical definition for the naming/slug convention instead of restating it,
  without changing their read/scan behavior. Verify both still list/flag saved posts correctly.
  ```
