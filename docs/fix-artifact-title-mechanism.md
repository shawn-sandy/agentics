# Fix the artifact title mechanism

> Corrects a false claim in `artifact-tools` that Markdown frontmatter can set an artifact title; switches `session-artifact` to publish an HTML render with a proper `<title>`; pins the invariant with a test.

<!-- generated:start -->

**Status:** Shipped 2026-07-15 **Plan:** [fix-artifact-title-mechanism.md](plans/fix-artifact-title-mechanism.md)
**Type:** fix

## What shipped

- Replaced the false frontmatter claim in `references/titles.md` with the truth: an HTML `<title>` is the only mechanism; a Markdown source cannot set its own title and falls back to its filename; a `title:` key is a value to carry into a `<title>`.
- Rewrote `session-artifact/SKILL.md` to publish an HTML render (instead of raw Markdown), with `<title>` taken from the frontmatter `title:` field and the frontmatter block dropped from the page body. The `.md` file remains the committed record and the home of `artifact-url:`.
- Corrected the republish note to require `url` on every republish (not only across sessions), since the render lands on a new scratchpad path each run.
- Added `tests/plugins/test-artifact-titles.mjs` and wired it into `publish-dist.yml`.
- Bumped `artifact-tools` to `1.2.1`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/references/titles.md` | Title rules | Modified |
| `kit/plugins/artifact-tools/skills/session-artifact/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | Version history | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |
| `tests/plugins/test-artifact-titles.mjs` | Regression test | Created |
| `.github/workflows/publish-dist.yml` | CI configuration | Modified |

## How it works

The Artifact renderer does not parse YAML frontmatter. Publishing a Markdown source with a `title:` key caused the frontmatter block to appear as visible body text — the opening `---` became an `<hr>` and the YAML became a `<h2>` — while the artifact title fell back to the source filename, extension included.

The root fix is in `titles.md`: by stating the truth plainly ("an HTML `<title>` is the only mechanism"), future skill authors can't repeat the mistake. `session-artifact` was the only skill affected (the other three skills already published HTML), so its fix was to render the Markdown to an HTML file with `<title>` taken from `title:` frontmatter before publishing.

The test `test-artifact-titles.mjs` asserts every affected invariant with grep-level checks, verifying each assertion fails against `origin/main` to prove the tests are discriminating rather than vacuously green.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [fix-artifact-title-mechanism.md](plans/fix-artifact-title-mechanism.md)
- Changelog: [artifact-tools CHANGELOG v1.2.1](../kit/plugins/artifact-tools/CHANGELOG.md)
