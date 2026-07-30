---
name: artifact-to-post
description: "Converts an HTML artifact or Markdown file into a draft post for a static site. Scopes CSS to keep interactive blocks alive and escapes prose for MDX. Use when asked to turn an artifact into a post."
allowed-tools: AskUserQuestion, Read, Write, Edit, Bash, Glob, Grep, Skill, ToolSearch, ExitPlanMode
---

# artifact-to-post

## Exit plan mode

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

## Phase 0 — Locate plugin assets

The skill launch message opens with `Base directory for this skill: <path>` —
call it `$SKILL_DIR`. All four references sit under `$SKILL_DIR/../../`:
`references/content-config.md`, `references/mdx-safety.md`,
`references/source-resolution.md`, `references/post-assembly.md`.

`Read` them directly. **Do not `find` or `Glob` for them**: the path is given, and
hunting wastes turns and hits sandbox denials. Read
`references/content-config.md` now, `references/mdx-safety.md` before Phase 4.

## Phase 1 — Resolve the source and branch on type

Follow `references/source-resolution.md`: local `.html`, pasted HTML, local `.md`
(skips **only** Phases 4 and 7), or a `claude.ai` URL (refused, handed to
`social-media-tools:save-artifact`). No source given: `Glob` and ask.

## Phase 2 — Security scrub (blocking gate)

Before **anything** is written, invoke `social-media-tools:security-scrub` on the
source content. Artifacts carry tokens and customer data that were fine in a
private session and are not fine on a public blog.

- Findings → report them and stop. Do not offer to publish around them.
- `social-media-tools` not installed, or the skill fails to run for any reason →
  **write nothing and end the turn.** Print exactly this and stop:

  > `social-media-tools:security-scrub` is not available, so I can't check this
  > artifact for secrets before publishing it. Install `social-media-tools`, or
  > re-run and tell me explicitly that you've reviewed the content yourself.

  Then stop; do not continue to Phase 3. Your own read is not a substitute —
  "it seems fine" is not the gate, and a self-review ending in a written post is
  the exact failure this prevents. Only an explicit user instruction given
  *after* that message authorizes proceeding unscanned.

## Phase 3 — Config and prerequisites

Load `CONTENT.md` per `references/content-config.md`; if absent, ask once and offer
to write one. Every site-specific value comes from that config: `posts_dir`,
`extension`, frontmatter keys, `draft_flag`, `images_dir`, `preview_url`,
`build_command`, `interactivity_ceiling`. Never write a literal path, key, or
command into the output.

Run both prerequisite checks from the reference; on failure report the exact fix
and stop. **Never auto-install `@astrojs/mdx` and never edit the target's content
config.**

## Phase 4 — Extract to Markdown (HTML sources only)

Read `references/post-assembly.md` now and follow its Phases 4–10 as written. The
summaries below are the load-bearing constraints only, not a second copy.

## Phase 5 — Prose rewrite

For a reader who arrived cold, in the author's voice.

## Phase 6 — MDX-safety pass

Runs **after** Phase 5, deliberately. The rewrite is what introduces the hazards,
so a pass before it would validate text that no longer exists. Do not reorder
these phases. Skip the pass entirely when `extension` is `.md`.

## Phase 7 — Rung-4 screenshots

Only for blocks that landed on rung 4.

## Phase 8 — Write the post

`draft_flag` lands on its **unpublished** value: a conversion is a draft until a
human says otherwise. Ask before overwriting.

## Phase 9 — Verify

The configured `build_command` is the authoritative gate. Never report success on
a failing build.

## Phase 10 — Publish gate

**Default to no.** Declining leaves `draft_flag` untouched; accepting flips only
that key.
