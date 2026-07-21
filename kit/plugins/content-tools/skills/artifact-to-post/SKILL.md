---
name: artifact-to-post
description: "Converts an HTML artifact or Markdown file into a draft post for a static site. Scopes CSS to keep interactive blocks alive and escapes prose for MDX. Use when asked to turn an artifact into a post."
allowed-tools: AskUserQuestion, Read, Write, Edit, Bash, Glob, Grep, Skill, ToolSearch, ExitPlanMode
---

# artifact-to-post

Turn an HTML artifact or a Markdown file into a **draft** post for a static site
generator, keeping interactive blocks interactive instead of flattening them to
images.

## Exit plan mode

`ExitPlanMode` is a deferred tool. **Only call it if currently in plan mode** —
skip this step entirely when not in plan mode. When calling: use `ToolSearch`
with `select:ExitPlanMode` first, then call `ExitPlanMode` silently.

## Phase 0 — Locate plugin assets

The skill launch message opens with `Base directory for this skill: <path>`.
Call that path `$SKILL_DIR`. The two references are two levels up from it:

- `$SKILL_DIR/../../references/content-config.md` — the `CONTENT.md` schema and prerequisites
- `$SKILL_DIR/../../references/mdx-safety.md` — the fidelity ladder and the MDX/JSX rules

`Read` those paths directly. **Do not `find` or `Glob` for them** — the base
directory is already given, and searching the filesystem for a file you have
the path to wastes turns and hits sandbox denials.

Read `content-config.md` now; read `mdx-safety.md` before Phase 4.

## Phase 1 — Resolve the source and branch on type

| Source | Path |
|--------|------|
| Local `.html` file | Full extraction path (Phases 4–7) |
| Pasted HTML | Write it to a scratch `.html`, then the full extraction path |
| Local `.md` file | **Skips Phase 4 and Phase 7 only** — see below |
| A `claude.ai` artifact URL | **Refuse** — see below |

A `.md` source is already Markdown, so it skips **extraction** (Phase 4) and
**screenshots** (Phase 7): do not re-extract it, do not re-classify its blocks,
do not touch its fenced code.

It skips nothing else. Every source type still runs the security scrub
(Phase 2), the config and prerequisite checks (Phase 3), the prose rewrite
(Phase 5), the safety pass (Phase 6), and the write and gates (Phases 8–10) —
in that order. A Markdown file is just as likely to carry a pasted token as an
artifact is, and it needs `posts_dir` and the draft flag exactly as much.

**claude.ai URLs are refused.** `WebFetch` cannot read authenticated or private
URLs, so attempting one produces a confident wrong result. Reply with one line
and stop:

> I can't fetch a published claude.ai artifact — that URL needs your session.
> Save it locally first with `social-media-tools:save-artifact`, then point me
> at the `.html`.

If no source was given, `Glob` for candidates (`.claude/artifacts/*.html`,
`*.html`, `*.md`) and ask via `AskUserQuestion`. Never guess.

## Phase 2 — Security scrub (blocking gate)

Before **anything** is written, invoke the `social-media-tools:security-scrub`
skill on the source content. An artifact often carries API responses, tokens, or
customer data that were fine in a private session and are not fine on a public
blog.

- Findings → report them and stop. Do not offer to publish around them.
- `social-media-tools` not installed, or the skill fails to run for any reason →
  **write nothing and end the turn.** Print exactly this and stop:

  > `social-media-tools:security-scrub` is not available, so I can't check this
  > artifact for secrets before publishing it. Install `social-media-tools`, or
  > re-run and tell me explicitly that you've reviewed the content yourself.

  Then stop. Do not continue to Phase 3. Do not substitute your own read of the
  file for the scan — "I looked at it and it seems fine" is not the gate, and a
  self-review that ends in a written post is the exact failure this prevents.
  Only an explicit instruction from the user in this session — given *after*
  the message above — authorizes proceeding without the scan.

## Phase 3 — Config and prerequisites

Load `CONTENT.md` per `references/content-config.md`. If absent, ask once and
offer to write one.

Every site-specific value — `posts_dir`, `extension`, frontmatter keys,
`draft_flag`, `images_dir`, `preview_url`, `build_command`,
`interactivity_ceiling` — comes from that config. Never write a literal path,
key, or build command into the output.

Then run both prerequisite checks from the reference. On failure, report the
exact fix and stop. **Never auto-install `@astrojs/mdx` and never edit the
target's content config.**

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

Runs **after** Phase 5, deliberately. The prose rewrite is what introduces the
hazards — writing about a generic naturally produces `Array<string>` in prose —
so a pass that ran before the rewrite would validate text that no longer exists.
Do not reorder these phases.

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
