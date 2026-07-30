# Source resolution (Phase 1)

Loaded by `artifact-to-post` Phase 1, before anything is read or written.

## Branch on the source type

| Source | Path |
|--------|------|
| Local `.html` file | Full extraction path (Phases 4–7) |
| Pasted HTML | Write it to a scratch `.html`, then the full extraction path |
| Local `.md` file | **Skips Phase 4 and Phase 7 only** — see below |
| A `claude.ai` artifact URL | **Refuse** — see below |

## Markdown sources skip extraction, and nothing else

A `.md` source is already Markdown, so it skips **extraction** (Phase 4) and
**screenshots** (Phase 7): do not re-extract it, do not re-classify its blocks,
do not touch its fenced code.

It skips nothing else. Every source type still runs the security scrub
(Phase 2), the config and prerequisite checks (Phase 3), the prose rewrite
(Phase 5), the safety pass (Phase 6), and the write and gates (Phases 8–10) —
in that order. A Markdown file is just as likely to carry a pasted token as an
artifact is, and it needs `posts_dir` and the draft flag exactly as much.

## claude.ai URLs are refused

This skill takes a file, and a published artifact needs fetching, scrubbing, and
saving first — which is exactly what `social-media-tools:save-artifact` does, URL
and all. Hand it off rather than fetching here, so the scrub and the saved local
copy both happen. Reply with one line and stop:

> I work from a saved file. Give that URL to `social-media-tools:save-artifact`
> first — it fetches and scrubs the artifact — then point me at the `.html` it
> writes.

## No source given

`Glob` for candidates (`.claude/artifacts/*.html`, `*.html`, `*.md`) and ask via
`AskUserQuestion`. Never guess.
