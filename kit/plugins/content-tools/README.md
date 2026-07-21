# content-tools

Turning work products into publishable site content.

An HTML artifact or a Markdown file normally dies in the session that made it.
This plugin moves it into a real static site as a draft post — without
flattening the interactive parts to screenshots.

## Skills

| Skill | What it does |
|-------|--------------|
| `artifact-to-post` | Converts a local `.html` artifact, pasted HTML, or a `.md` file into a draft post (`.md`/`.mdx`) for a static site generator (Astro first) |

## How it works

Each content block is placed on the highest rung of a fidelity ladder that
holds: native Markdown, then scoped inline HTML, then scoped HTML plus the
artifact's own script, and only as a last resort a screenshot. Scoping the
artifact's CSS to a wrapper container is what stops it colliding with the site's
design tokens — and what keeps `<details>`, `<dialog>`, and range inputs working.

Because MDX parses Markdown as JSX, a safety pass escapes bare `{`/`}` and
`<word…>` in prose and rewrites HTML attributes (`class` → `className`) before
anything is written. See `references/mdx-safety.md`.

Nothing site-specific is hardcoded. Output directory, extension, frontmatter
keys, draft flag, images directory, preview URL, build command, and the
interactivity ceiling all come from a project-root `CONTENT.md`. See
`references/content-config.md`.

## Not in v1

Published claude.ai artifact URLs. `WebFetch` cannot read authenticated or
private URLs, so the skill refuses them and points at
`social-media-tools:save-artifact`, which produces exactly the local `.html`
this skill consumes.

## Install

```bash
/plugin marketplace add shawn-sandy/agentics
/plugin install content-tools@agentics-kit
```
