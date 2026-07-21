# CONTENT.md — Project-Level Content Configuration

`artifact-to-post` ships to arbitrary repos. Nothing about the target site may
be hardcoded — a literal `src/content/posts/` or `publish:` works on one site
and silently corrupts every other. Every site-specific value comes from a
project-root `CONTENT.md`.

Modelled on the `SOCIAL.md` convention from `social-media-tools:share-init`, but
with its own schema. The two do not overlap: `SOCIAL.md` holds platforms, tone,
and hashtags; `CONTENT.md` holds where posts live and how they build.

## Loading

```bash
CONTENT_CONFIG=""
GIT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -f "$PWD/CONTENT.md" ]; then
  CONTENT_CONFIG="$PWD/CONTENT.md"
elif [ -n "$GIT_ROOT" ] && [ -f "$GIT_ROOT/CONTENT.md" ]; then
  CONTENT_CONFIG="$GIT_ROOT/CONTENT.md"
fi
```

When no config exists, **ask once** (a single batched `AskUserQuestion` covering
the fields that have no safe default), then offer to write `CONTENT.md` so the
next run is silent. Never guess a posts directory.

## Fields

| Field | Meaning | Example |
|-------|---------|---------|
| `posts_dir` | Where post files are written | `src/content/blog` |
| `extension` | Output extension | `.mdx` or `.md` |
| `frontmatter.title` | Frontmatter key for the title | `title` |
| `frontmatter.description` | Key for the description/summary | `description` |
| `frontmatter.date` | Key for the publish date | `pubDate` |
| `frontmatter.author` | Key for the author | `author` |
| `draft_flag` | Key and unpublished value for the draft state | `draft: true` |
| `images_dir` | Where rung-4 screenshots are written | `public/images/posts` |
| `preview_url` | Dev preview URL pattern for a slug | `http://localhost:4321/blog/{slug}` |
| `build_command` | The authoritative build gate | `npm run build` |
| `interactivity_ceiling` | Highest ladder rung allowed (1–4) | `3` |

Nine settings plus the ceiling. `extension` and `interactivity_ceiling` interact:
a `.md` site cannot host rung 2–3 JSX, so `.md` implies a ceiling of 1 unless the
site documents otherwise.

`draft_flag` carries both the key and the unpublished value, because sites
disagree on the sense of it — `draft: true` and `published: false` mean the same
thing. Write the unpublished value; never invert it by guessing.

## Example

```markdown
# CONTENT.md

## Output
- posts_dir: src/content/blog
- extension: .mdx
- images_dir: public/images/posts

## Frontmatter
- title: title
- description: description
- date: pubDate
- author: author
- draft_flag: draft: true

## Build
- preview_url: http://localhost:4321/blog/{slug}
- build_command: npm run build
- interactivity_ceiling: 3
```

## Prerequisite checks

Run both against the **target repo** before writing anything. Report the exact
fix and stop on failure. **Never auto-install and never edit the target's config**
— a content skill that mutates a build setup is a content skill that broke a
build.

### 1. `@astrojs/mdx` present

```bash
grep -q '"@astrojs/mdx"' package.json
```

On failure, report verbatim:

> `@astrojs/mdx` is not in `package.json`. Install it and register it before
> converting: `npx astro add mdx`. Stopping — nothing was written.

### 2. Content-collection glob includes `.mdx`

Check the collection loader in `src/content.config.ts` (or `src/content/config.ts`)
for a pattern that admits `.mdx` — typically `"**/*.{md,mdx}"`.

On failure, report verbatim:

> The content collection for `<posts_dir>` does not match `.mdx` files. Widen the
> loader glob to `"**/*.{md,mdx}"`. Stopping — nothing was written.

Skip both checks when `extension` is `.md` — they only guard the MDX path.
