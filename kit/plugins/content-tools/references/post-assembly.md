# Post assembly (Phases 4–10)

Loaded after the Phase 2 scrub gate and the Phase 3 config checks have both
passed. Every site-specific value named here comes from `CONTENT.md` — see
`references/content-config.md`.

## Phase 4 — Extract to Markdown (HTML sources only)

Read the HTML yourself and write the Markdown. There is no converter script — a
parser's output would be rewritten by hand in the next phase anyway.

Classify each block against the ladder in `references/mdx-safety.md`, taking the
highest rung that holds.

Then apply `interactivity_ceiling`, which limits **how interactive an embed may
be** — it constrains rungs 2 and 3, and nothing else. A block whose natural rung
exceeds the ceiling falls to rung 4 (a screenshot), never to rung 2 with a dead
script.

Rung 4 is the fallback, not the top of the ladder — it is the *least*
interactive outcome, so the ceiling can never forbid it. `interactivity_ceiling:
3` permits scripts; it does not forbid images. **No block is ever dropped**: a
block that can't be ported becomes a screenshot, not a deletion.

Scoped blocks (rungs 2–3) get a wrapper container and the artifact's CSS
prefixed to that container's selector. Drop `html`, `body`, `:root`, and `*`
rules — they cannot be scoped and they are the ones that leak.

## Phase 5 — Prose rewrite

Rewrite the extracted prose as something a human would read: an opening that
says why this exists, transitions between blocks, and a close. An artifact's
text is written for the person who asked for it; a post is written for a reader
who arrived cold.

Keep the author's voice. Do not pad, and do not invent results the artifact does
not show.

## Phase 6 — MDX-safety pass

Apply section (b) of `references/mdx-safety.md`: escape `{` and `}` in prose,
neutralize `<word…>` sequences and bare autolinks, and leave fenced blocks and
inline code spans untouched.

For HTML emitted at rungs 2–3, apply the parser-level rules (self-closed void
tags, JSX comments, template-literal `<style>`/`<script>` bodies) — then the
attribute rules **for the runtime this site actually uses**. On Astro, keep
`class` and `for` as they are: `htmlFor` is not mapped and silently breaks the
label/input association. React-based pipelines need the opposite. The reference
has both lists; pick by what is in `package.json`.

Skip the whole pass when `extension` is `.md` — plain Markdown has no JSX parser
to offend, and escaping it would be a visible bug.

## Phase 7 — Rung-4 screenshots

Only for blocks that landed on rung 4. Reuse the serve-locally-then-Playwright
pattern documented in `social-media-tools/skills/share-code/SKILL.md` — serve
the artifact over a local HTTP server, screenshot the block's selector, write
into `images_dir`. No new script.

Every screenshot gets real alt text and a link to the live artifact beneath it.

## Phase 8 — Write the post

Write to `posts_dir` with the configured `extension` and a slug derived from the
title. Synthesize frontmatter using the configured key names only — title,
description, date (today), author — and set `draft_flag` to its **unpublished**
value. A conversion is a draft until a human says otherwise.

Close the post with a link back to the source artifact.

If the target file already exists, ask before overwriting.

## Phase 9 — Verify

Run the configured `build_command`. **This is the authoritative gate** — a
type-check cannot see an MDX escaping bug, but the build fails on it instantly.

On failure, read the error, fix the offending construct, and re-run. Do not
report success on a failing build.

Then report the `preview_url` for the slug so the reader can confirm rung-2 and
rung-3 blocks still respond to input. If a rung-3 script turns out to be inert on
this Astro version, demote that block to rung 4 and record the observation in the
version table at the bottom of `references/mdx-safety.md`.

## Phase 10 — Publish gate

Offer publication. Show the slug and the preview URL. **Default to no.**

Declining leaves `draft_flag` at its unpublished value, untouched. Accepting
flips only that one key — nothing else in the file changes.
