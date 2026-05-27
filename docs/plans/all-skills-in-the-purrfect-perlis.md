
---

status: todo
type: feature
created: 2026-05-27
repo-name: agentics
---

# Plan: Save card PNG alongside its HTML in docs/media/social/

## Context

Every card-generating skill in `kit/plugins/social-media-tools/` runs the same
pipeline: write a **temp HTML** to `~/.claude/tmp/{skill}-card.html` (served over a
local HTTP server so Playwright can render it), save a **persistent HTML** to
`docs/media/social/{type}-{slug}-{date}.html`, then screenshot to a **temp PNG** at
`~/.claude/tmp/{skill}-card.png`.

The result: the HTML lands in `docs/media/social/` with a unique, date-stamped name,
but the PNG lands in a temp directory under a generic fixed name. The two artifacts of
the same post don't travel together — the image is effectively orphaned and overwritten
on the next run.

The user wants the image stored **in the same folder as the HTML output, with the same
name** — i.e. `docs/media/social/{type}-{slug}-{date}.png` sitting next to
`docs/media/social/{type}-{slug}-{date}.html`. (The working tree already shows a manually
produced example pair: `project-agentics-kit-features-2026-05-27.{html,png}`.)

## Objective

Redirect the Playwright screenshot in all 5 card-generating skills to write the PNG to
the persistent media folder using the HTML's base name (`.html` → `.png`), update the
2 adjacent skills that read that folder for the new sibling-PNG reality, and refresh the
plugin docs + version.

## Approach

The temp HTML in `~/.claude/tmp/` stays — it is what the local HTTP server serves and
what Playwright navigates to. **Only the screenshot's output `path` and the delivery
`SendUserFile` path change.** The fix per skill is mechanical:

1. In the persistent-save phase (where `SAVE_PATH` is defined), add a sibling PNG path
   and echo it so the concrete absolute string is available for the tool call:

   ```bash
   SAVE_PATH_PNG="${SAVE_PATH%.html}.png"
   echo "$SAVE_PATH_PNG"
   ```

2. In the screenshot phase, change `browser_take_screenshot`'s `path:` from
   `~/.claude/tmp/{skill}-card.png` to the absolute `$SAVE_PATH_PNG` value
   (e.g. `docs/media/social/{type}-{slug}-{date}.png`). `mkdir -p "$MEDIA_DIR"` already
   runs in the save phase (which precedes the screenshot), so the directory exists.
3. In the deliver phase, attach the PNG from `$SAVE_PATH_PNG` via `SendUserFile`, and
   update the saved-path note to surface both the HTML and the PNG.
4. Update the skill's Quick-Reference table row that mentions the screenshot/PNG.
5. Update the Playwright-fallback line to keep pointing at the temp HTML for manual
   screenshotting (unchanged), since the temp HTML is still produced.

## Steps

1. **code-share** (`skills/code-share/SKILL.md`) — In Phase 4b add `SAVE_PATH_PNG` + echo;
   in Phase 5c change screenshot `path` from `~/.claude/tmp/code-share-card.png` to
   `$SAVE_PATH_PNG`; in Phase 6 attach `$SAVE_PATH_PNG` and note both saved paths; update
   the Quick-Reference rows for phases 5–6.
   - *Why:* This is the canonical skill the other four mirror; getting its wording right
     sets the template for the rest.
   - *Verify:* `grep -n "tmp/code-share-card.png" SKILL.md` returns nothing; the screenshot
     and deliver steps reference `$SAVE_PATH_PNG`; the temp **HTML** reference at
     `~/.claude/tmp/code-share-card.html` is still present (server source).

2. **project-share** (`skills/project-share/SKILL.md`) — Apply the same change in 6c
   (add `SAVE_PATH_PNG`), 6d (screenshot to `$SAVE_PATH_PNG`), and Phase 7 (attach +
   note); update Quick-Reference rows 6–7.
   - *Why:* Same pipeline; the worked example pair already in the tree came from this skill.
   - *Verify:* `grep -n "tmp/project-share-card.png" SKILL.md` returns nothing; deliver
     step attaches `$SAVE_PATH_PNG`.

3. **github-code-share** (`skills/github-code-share/SKILL.md`) — Add `SAVE_PATH_PNG` in the
   "Persistent save" block, screenshot to it in "Screenshot pipeline", attach it in Phase 6;
   update the Quick-Reference deliver row.
   - *Why:* Same pipeline (`snippet-` prefix).
   - *Verify:* `grep -n "tmp/github-code-share-card.png"` returns nothing.

4. **video-share** (`skills/video-share/SKILL.md`) — Add `SAVE_PATH_PNG` in Phase 4b,
   screenshot to it in Phase 5, attach it in Phase 6; update Quick-Reference rows 5–6.
   - *Why:* Same pipeline (`video-` prefix).
   - *Verify:* `grep -n "tmp/video-share-card.png"` returns nothing.

5. **blog-share** (`skills/blog-share/SKILL.md`) — Add `SAVE_PATH_PNG` in Phase 4b,
   screenshot to it in Phase 5c, attach it in Phase 6; update Quick-Reference rows 5–6.
   - *Why:* Same pipeline (`blog-` prefix).
   - *Verify:* `grep -n "tmp/blog-share-card.png"` returns nothing.

6. **scan-for-shares** (`skills/scan-for-shares/SKILL.md`, Step 4b) — Restrict the
   existence check so it matches only HTML: change the `ls "$MEDIA_DIR" | grep -i ...`
   lines to `ls "$MEDIA_DIR"/*.html | grep -i ...` (or append a `grep '\.html$'`), so a
   candidate's sibling `.png` no longer produces a second/ambiguous match for `SAVED_PATH`.
   - *Why:* Adding PNGs with the same slug would otherwise make the slug grep return two
     lines per candidate, muddying `SAVED_PATH`. HTML remains the source of truth.
   - *Verify:* Mentally run the grep against a folder containing both
     `feature-x-2026-05-27.html` and `.png` — only the `.html` matches.

7. **media-library** (`skills/media-library/SKILL.md`) — In "View a post" and "Open in
   browser", after resolving the chosen `.html`, surface the sibling
   `${file%.html}.png` when it exists (e.g. "Card image: `docs/media/social/{base}.png`").
   Keep Step 1's listing on `*.html` only (one row per post, PNG shown as the post's image).
   - *Why:* The library is the browse/reuse surface; now that a matching PNG exists it
     should point users to the rendered card, not just the HTML.
   - *Verify:* Reading the skill, the view/open paths mention the sibling PNG conditionally;
     the Step-1 `ls` still globs `*.html` (no double-counting).

8. **Docs + version** — Bump `social-media-tools` to **v0.6.0** in
   `.claude-plugin/marketplace.json`; add a v0.6.0 CHANGELOG entry describing the PNG-beside-HTML
   change; update `README.md` lines that say the screenshot goes to
   `~/.claude/tmp/code-share-card.png` (Phase 5 of the Workflow section, ~line 274) to the
   `docs/media/social/{type}-{slug}-{date}.png` destination, and the per-skill "deliver copy
   - PNG" workflow lines if they imply a temp path.
   - *Why:* Project convention requires a version bump + CHANGELOG + README sync for any
     documented output-behavior change (see `.claude/rules/marketplace.md`).
   - *Verify:* `marketplace.json` shows `"version": "0.6.0"` for the plugin and remains valid
     JSON (the settings hook auto-validates on save); CHANGELOG top entry is v0.6.0;
     `grep -n "tmp/code-share-card.png" README.md` returns nothing.

## Acceptance Criteria

- [ ] All 5 card-generating skills screenshot the PNG to `docs/media/social/{type}-{slug}-{date}.png` (same dir and base name as the saved HTML), not to `~/.claude/tmp/`.
- [ ] Each skill's deliver phase attaches that PNG via `SendUserFile` and reports both the saved HTML and PNG paths.
- [ ] The temp HTML at `~/.claude/tmp/{skill}-card.html` is still written and served (Playwright source unchanged); the Playwright-unavailable fallback still points there.
- [ ] No SKILL.md references a temp `*-card.png` path any longer (`grep -rn "tmp/.*-card.png" skills/` is empty).
- [ ] `scan-for-shares` matches only `.html` when flagging SAVED candidates.
- [ ] `media-library` surfaces the sibling `.png` when viewing/opening a post.
- [ ] `marketplace.json` lists `social-media-tools` at v0.6.0 (valid JSON); CHANGELOG and README reflect the new PNG destination.

## Verification

End-to-end, with the plugin loaded (`claude --plugin-dir kit/plugins/social-media-tools`):

1. Run `code-share` on a recent diff. Confirm two files appear together in
   `docs/media/social/` with the same base name — `{type}-{slug}-{date}.html` and
   `{type}-{slug}-{date}.png` — and that `~/.claude/tmp/` holds only the served HTML, no
   stray `code-share-card.png`.
2. Confirm the delivered message attaches the `docs/media/social/...png` (not a temp path)
   and lists both saved paths.
3. Run `media-library` → "View a post" on that entry; confirm it shows the sibling PNG path.
4. Run `scan-for-shares` and confirm a candidate matching the saved post is flagged `[SAVED]`
   exactly once (HTML match), with no `.png`-driven duplication.
5. Repeat step 1 spot-check for one other skill (e.g. `video-share` or `blog-share`) to
   confirm the pattern holds across skills.
6. Static check: `grep -rn "tmp/.*-card.png" kit/plugins/social-media-tools/skills/`
   returns nothing; `grep -rn "tmp/.*-card.html"` still returns the per-skill server source.

## Next Steps *(optional)*

- Backfill PNGs for already-saved HTML posts that lack a sibling image:

  ```text
  In kit/plugins/social-media-tools, scan docs/media/social/ for any *.html post that has
  no matching *.png sibling (same base name). For each, render the saved HTML with the
  plugin's local-HTTP-server + Playwright screenshot pipeline (find_free_port.py → python3
  -m http.server → browser_take_screenshot) and write the PNG next to the HTML using the
  same base name. Report which files were backfilled and which were skipped.
  ```
