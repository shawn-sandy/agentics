# Publishing the prompt page and recording its URL

Loaded by `prompt-artifact` Steps 6 and 8.

## Step 6 — Publish, then record the URL

Publish with a one-sentence `description` and the favicon `📝` — keep the favicon
and `<title>` stable across republishes, since users find the tab by its icon.

Where the URL is recorded differs by mode:

| Mode | URL lives in | First publish | Republish |
|------|--------------|---------------|-----------|
| single | the prompt `.md`'s frontmatter | publish fresh, then `Edit` in `artifact-url:` | pass `artifact-url:` to `Artifact`'s `url` |
| library | `$PROMPTS_DIR/.artifact-url` | publish fresh, then write the file | pass its contents to `Artifact`'s `url` |

The gallery has no single source `.md` to hold frontmatter, hence the sidecar:

```bash
SIDECAR="$PROMPTS_DIR/.artifact-url"
[ -f "$SIDECAR" ] && LIBRARY_URL=$(cat "$SIDECAR")   # republish
# after a successful first publish:
printf '%s\n' "$URL" > "$SIDECAR"
```

**Commit the sidecar.** This repo already treats a recorded artifact URL as
shared state — `session-artifact` saves its recap under `{plansDirectory}` for
exactly this reason. Ignoring the sidecar would give every clone its own gallery
URL, which is the rot the stable-URL design exists to prevent. It is not covered
by any existing `.gitignore` rule, so no change is needed there.

Skipping the record step is the quiet failure mode in both modes: the publish
looks fine, and the *next* session mints a second page while the link you shared
goes stale.

## Step 8 — Fallback

If publishing fails (no claude.ai login, or publishing unavailable), the scratchpad
copy is not a deliverable — it is temporary. Write the page to `.claude/artifacts/`
so something durable survives, keyed by what the page *is*, never by date:

```bash
mkdir -p .claude/artifacts
# single: prompt-<basename>.html | library: prompt-library.html
cp "$SCRATCH_HTML" ".claude/artifacts/prompt-${key}.html"
```

Say plainly that publishing did not happen and why, report the local path, and
offer `social-media-tools:save-artifact` — it publishes into the repo's GitHub
Pages artifacts gallery.

Never report a URL that was not returned by a successful publish.
