# Fix artifact title mechanism

> The skills falsely claimed that Markdown frontmatter `title:` sets an artifact's browser-tab title; the only mechanism that works is an HTML `<title>` tag, so session-artifact was rewritten to publish HTML and the reference was corrected.

<!-- generated:start -->

**Status:** Shipped 2026-07-15 **Plan:** [fix-artifact-title-mechanism.md](plans/fix-artifact-title-mechanism.md)
**Type:** feature

## What shipped

- Added `kit/plugins/artifact-tools/references/titles.md`: canonical reference stating that HTML `<title>` is the only mechanism that sets an artifact's browser-tab title; Markdown frontmatter `title:` is ignored by the Artifact tool.
- Rewrote `skills/session-artifact/SKILL.md`: session-artifact now publishes an HTML render (`.html`) as the artifact; the Markdown session record (`.md`) is still committed to the project as a durable log, but the artifact URL points to the HTML version. The `url` parameter is now required on every republish call — missing it creates a duplicate artifact silently.
- Added `tests/plugins/test-artifact-titles.mjs`: 10 assertions covering (1) `titles.md` existence and content, (2) session-artifact SKILL.md references HTML publish, (3) `url` required on republish, (4) no skill claims frontmatter sets the title.
- Updated `.github/workflows/publish-dist.yml` to include `test-artifact-titles.mjs` in CI.
- Bumped artifact-tools to 1.2.1 and updated `CHANGELOG.md`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/references/titles.md` | Title mechanism reference | Created |
| `kit/plugins/artifact-tools/skills/session-artifact/SKILL.md` | HTML publish + url required | Modified |
| `tests/plugins/test-artifact-titles.mjs` | 10 title assertions | Created |
| `.github/workflows/publish-dist.yml` | CI step added | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | 1.2.1 entry | Modified |
| `.claude-plugin/marketplace.json` | artifact-tools → 1.2.1 | Modified |

## How it works

The Artifact tool ignores Markdown frontmatter entirely. The only way to give an artifact a named browser tab is to publish HTML with a `<title>` element. Session-artifact now generates an HTML document from the session JSON and publishes it; the Markdown transcript is written separately as the committed record. Because the two files share the same `artifact-url:` key, the session URL always points to the readable HTML version.

The `url` required rule prevents silent duplication: if `url` is omitted on a second publish, the Artifact tool creates a new artifact at a new URL, leaving the old URL stale. The skill now fails fast if `artifact-url:` is missing from the frontmatter instead of silently creating a second artifact.

## How to use it

No invocation change needed. `/artifact-tools:session-artifact` now publishes HTML automatically and enforces the `url` on republish.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| — | 2026-07-15 | fix(artifact-tools): HTML title mechanism — session-artifact to HTML, url required on republish (1.2.1) |

<!-- generated:end -->

## References

- Plan: [fix-artifact-title-mechanism.md](plans/fix-artifact-title-mechanism.md)
