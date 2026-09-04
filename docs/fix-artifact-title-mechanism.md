# Fix the artifact title mechanism

> The Artifact renderer does not parse YAML frontmatter — every skill must set its title via an HTML `<title>` tag, and `session-artifact` now publishes an HTML render.

<!-- generated:start -->

**Status:** Shipped 2026-08-12 **Plan:** [fix-artifact-title-mechanism](plans/fix-artifact-title-mechanism.md)
**Type:** fix

## What shipped

- Replaced the false frontmatter-title claim in `references/titles.md` with the correct rule: an HTML `<title>` is the only working title mechanism; Markdown sources fall back to their filename.
- Switched `session-artifact` from publishing a raw `.md` file to publishing a self-contained HTML render with a `<title>` derived from frontmatter and no visible YAML.
- Corrected the republish note to require `url` on every republish, not only across sessions.
- Added `tests/plugins/test-artifact-titles.mjs` to pin the invariant and wired it into `publish-dist.yml`.
- Bumped `artifact-tools` to 1.2.1 with a matching CHANGELOG entry.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/artifact-tools/references/titles.md` | Title mechanism rules | Modified |
| `kit/plugins/artifact-tools/skills/session-artifact/SKILL.md` | Session recap skill | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | Plugin changelog | Modified |
| `.claude-plugin/marketplace.json` | Version manifest | Modified |
| `tests/plugins/test-artifact-titles.mjs` | Regression test | Created |
| `.github/workflows/publish-dist.yml` | CI workflow | Modified |

## How it works

**Root cause fix in `titles.md`.** The file previously told authors to set a Markdown artifact's title via a `title:` frontmatter key. The Artifact renderer does not parse YAML frontmatter: the `---` becomes an `<hr>` and the YAML becomes body text. `titles.md` now states plainly that an HTML `<title>` is the only mechanism that works, that a Markdown source cannot set its own title and falls back to its filename (extension included), and that a `title:` frontmatter value is a datum to carry _into_ a `<title>` when generating HTML.

**`session-artifact` switched to HTML.** Previously `session-artifact` was the sole skill that published Markdown directly. It now produces a self-contained HTML file with `<title>` taken from the frontmatter `title:` key and the frontmatter block stripped from the visible body. The `.md` file stays the committed record and carries the `artifact-url:` frontmatter key, mirroring the pattern that `plan-artifact` already uses.

**Republish note corrected.** Because the HTML file lands on a new scratchpad path each run, a different `file_path` always claims a new URL. The old note framed the `url` requirement as a cross-session concern; the corrected note requires `url` on every republish regardless of session, since a same-session republish would mint a new page just as surely.

**Regression test added.** `tests/plugins/test-artifact-titles.mjs` is a grep-level smoke test that asserts: `titles.md` names the HTML `<title>` as the sole mechanism and contains no frontmatter instruction; every artifact skill points at the shared rules; `session-artifact` publishes HTML; and `url` is required on every republish. The plan verified that every assertion fails against `origin/main`, confirming the tests discriminate rather than pass vacuously.

**CI wiring.** The new test step was added to `publish-dist.yml` beside the existing plugin tests, so the false claim cannot silently return in a future edit.

## How to use it

No user-facing command changed. When `session-artifact` produces a recap, the artifact's tab and gallery name will be the session subject in sentence case rather than `<slug>.md`, and no YAML block will appear as page text.

Authors writing new Markdown-publishing skills should consult `kit/plugins/artifact-tools/references/titles.md`: generate an HTML file with a `<title>` tag and publish that, keeping the `.md` as the committed record.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `ded28e0` | 2026-07-15 | feat: add plugin version guard and fix artifact title mechanism (#410) |

<!-- generated:end -->

## References

- Plan: [fix-artifact-title-mechanism](plans/fix-artifact-title-mechanism.md)
- Changelog: `kit/plugins/artifact-tools/CHANGELOG.md` — 1.2.1 entry
