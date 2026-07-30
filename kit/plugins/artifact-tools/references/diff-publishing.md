# Saving, publishing, and recording the diff page

Loaded by `diff-artifact` Steps 6 and 7.

## Step 6 — Save the durable copy

Write the page to the `.claude/artifacts/` inbox **before publishing** — the
scratchpad is temporary, so a page that only ever lived there is not a fallback.
The URL is recorded later, only if a publish actually succeeds.

Key the filename by what the diff *is*, never by date. A date in the key means
tomorrow's run of the same branch misses today's `artifact-url:` and silently
mints a second page:

```bash
mkdir -p .claude/artifacts
# Deterministic key: pr-42 | range-abc123-def456 | branch-<slug>
case "$MODE" in
  pr)     key="pr-${PR}" ;;
  range)  key="range-$(echo "$RANGE" | tr '.' '-')" ;;
  *)      key="branch-$(git rev-parse --abbrev-ref HEAD | tr '/' '-')" ;;
esac
target=".claude/artifacts/diff-${key}.html"
cp "$SCRATCH_HTML" "$target"
```

## Step 7 — Publish, then record the URL

Before publishing, read `$target`'s first line: if it carries an
`<!-- artifact-url: ... -->` comment from an earlier run, pass that URL to
`Artifact`'s `url` parameter so the same page updates. Without it every session
mints a new URL and the link you already shared goes stale.

Publish `$target` with a one-sentence `description` and the favicon `🔍`, kept
identical across republishes — users find the tab by its icon.

**On success**, record the URL into the durable copy so later sessions find it:

```bash
tmp=$(mktemp)
{ echo "<!-- artifact-url: $URL -->"; grep -v '^<!-- artifact-url:' "$target"; } > "$tmp"
mv "$tmp" "$target"
```

Report the claude.ai URL, the local path, and how many files were summarized or
demoted — a truncated review must never read as a complete one.

**On publish failure** (no claude.ai login, or publishing unavailable): this is
not an edge case — sharing beyond the author needs Team/Enterprise, so on Pro
and Max the fallback *is* how the page reaches teammates. `$target` already
holds the page, with no `artifact-url:` line since nothing was published. Say
plainly that publishing did not happen and why, give the path, and offer
`social-media-tools:save-artifact` to publish it into the repo's GitHub Pages
artifacts gallery instead. Never report a URL that a publish did not return.
