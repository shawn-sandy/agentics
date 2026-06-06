# SOCIAL.md — Project-Level Sharing Configuration

Skills that generate social content check for a `SOCIAL.md` file at the project
root — first at `$PWD`, then falling back to the git toplevel. When present, its
settings serve as defaults — the user can still override anything at share time.

## How Skills Use It

| Skill | What it reads |
|-------|---------------|
| `social-share` (router) | Loads config and passes relevant context to dispatched skill |
| `share-code` | Default platform, tone, hashtags; content focus for copy angle |
| `share-project` | Default platform, tone, topic priorities, project identity |
| `share-scan` | Focus areas boost candidate scores; exclude patterns filter candidates |

## Loading Convention

At the start of Phase 1 (or equivalent), check:

```bash
SOCIAL_CONFIG=""
GIT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -f "$PWD/SOCIAL.md" ]; then
  SOCIAL_CONFIG="$PWD/SOCIAL.md"
elif [ -n "$GIT_ROOT" ] && [ -f "$GIT_ROOT/SOCIAL.md" ]; then
  SOCIAL_CONFIG="$GIT_ROOT/SOCIAL.md"
fi
```

If `SOCIAL_CONFIG` is non-empty, `Read` it and parse sections into variables.
If absent, proceed normally (all values are optional).

## Parsed Sections

### `## Identity`

Override project name and tagline for cards.

- `Project:` → `PROJECT_NAME` override
- `Tagline:` → Used as subtitle on feature-cards

### `## Defaults`

- `Platform:` → Default `--platform` value (e.g. `all`, `LinkedIn`, `twitter`)
- `Tone:` → Default tone for copy drafting. Supported values: `Instructional / Educational`
  (recommended — teaches in a clear, structured register), `Professional`, `Technical`,
  `Conversational`, `Punchy`. The tone only adjusts register; the teaching-first voice
  (Instructional Voice doctrine in `$PLUGIN_DIR/references/platforms.md`) applies regardless.
- `Hashtags:` → Comma-separated default hashtags (appended per platform rules)

### `## Focus`

Bullet list of topics/areas to prioritize when scanning or choosing content
angles. Skills that draft copy use these as thematic guidance.

### `## Avoid`

Bullet list of paths, patterns, or topics to exclude from sharing.
`share-scan` filters candidates matching these patterns.

### `## Audience`

Free-text description of the target audience. Informs copy tone and
vocabulary choices.

### `## Examples`

Optional example posts the user likes. Skills use these as style references
when drafting copy.
