# Fix the artifact title mechanism

> Corrects how artifact-tools derives artifact titles: replaces the broken YAML-frontmatter approach with HTML `<title>` and switches session-artifact to publish an HTML render instead of raw Markdown.

<!-- generated:start -->

**Status:** Shipped 2026-07-15  **Plan:** [fix-artifact-title-mechanism.md](plans/fix-artifact-title-mechanism.md)
**Type:** fix

## What shipped

- Updated `kit/plugins/artifact-tools/references/titles.md` — removed the incorrect claim that YAML frontmatter sets artifact titles; stated that `<title>` in HTML is the only working mechanism and that `.md` publishes use the filename as the title with no override.
- Updated `kit/plugins/artifact-tools/skills/session-artifact/SKILL.md` — switched the publish step from uploading the `.md` source directly to publishing an HTML render of the session recap, so the skill can supply a proper `<title>`.
- Updated the republish note to require `url:` on every republish (the Artifact tool does not remember the URL between calls).
- Added `tests/plugins/test-artifact-titles.mjs` — 10 assertions covering: `titles.md` does not mention frontmatter, session-artifact SKILL.md references an HTML render path, the HTML template includes a `<title>` tag, and the republish protocol is documented.
- Wired `test-artifact-titles.mjs` into `publish-dist.yml`.
- Bumped `artifact-tools` to `1.2.1` in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/artifact-tools/references/titles.md` | Title mechanism reference | Modified |
| `kit/plugins/artifact-tools/skills/session-artifact/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | Release notes | Modified |
| `.claude-plugin/marketplace.json` | Marketplace version | Modified |
| `tests/plugins/test-artifact-titles.mjs` | Title mechanism test | Created |
| `.github/workflows/publish-dist.yml` | CI configuration | Modified |

## How it works

The root cause was a mismatch between documentation and the Artifact tool's actual behavior: the Artifact tool's renderer does not parse YAML frontmatter, so a `.md` file published with `---\ntitle: My Title\n---` renders the frontmatter as body text and uses the filename as the browser-tab title.

The fix separates two concerns. `titles.md` now states the canonical rule: only the HTML `<title>` element sets a title; `.md` publishes always use the filename. Skills that need a custom title must render to HTML first.

For `session-artifact`, this means the skill now writes a minimal HTML wrapper around the Markdown-rendered content before publishing. The wrapper injects a `<title>` derived from the session date and description, giving the artifact a human-readable name in the gallery.

The republish note change closes a second latent bug: the Artifact tool's `url:` parameter must be supplied on every republish call; the tool does not persist state between invocations. The old note implied the URL was remembered.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|

<!-- generated:end -->

## References

- Plan: [fix-artifact-title-mechanism.md](plans/fix-artifact-title-mechanism.md)
