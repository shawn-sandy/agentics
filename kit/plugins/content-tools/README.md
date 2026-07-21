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

Local testing:

```bash
claude --plugin-dir ./kit/plugins/content-tools
```

## Usage

The skill auto-activates on a natural request — there is no slash command.

```text
Turn this artifact into a blog post
Turn ./docs/notes.md into a draft post
Convert .claude/artifacts/dashboard-2026-07-20.html into a post for the site
```

First run in a repo with no `CONTENT.md` asks once, then offers to write the
config so later runs are silent. Output is always a draft — the publish gate at
the end defaults to no.

## Plugin Structure

```
content-tools/
├── .claude-plugin/
│   └── plugin.json
├── README.md
├── CHANGELOG.md
├── references/
│   ├── content-config.md     # CONTENT.md schema + prerequisite checks
│   └── mdx-safety.md         # fidelity ladder + MDX/JSX rules
└── skills/
    └── artifact-to-post/
        └── SKILL.md
```

## Components

### Skill: `artifact-to-post`

Auto-activating. Runs eleven phases: locate assets, resolve the source,
security scrub (blocking), config and prerequisites, extract, prose rewrite,
MDX-safety pass, screenshots, write, verify, publish gate.

A Markdown source skips extraction and screenshots only — the scrub, the config
checks, and the safety pass still run.

### Reference: `references/mdx-safety.md`

Loaded on demand. The four-rung fidelity ladder, and the escaping rules that
decide whether the post builds. Also carries a per-Astro-version table
recording whether inline `<script>` in MDX is actually bundled.

### Reference: `references/content-config.md`

The `CONTENT.md` schema — ten settings plus `interactivity_ceiling` — and the
two prerequisite checks the skill runs against the target repo without ever
auto-installing anything.
