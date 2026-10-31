# Fix the artifact title mechanism

> Make every artifact-tools skill produce a readable, meaningful title by stating the one mechanism that works (an HTML `<title>`), switching `session-artifact` to publish an HTML render, and pinning both with a test so the false claim cannot return.

<!-- generated:start -->

**Status:** Shipped 2026-07-15  **Plan:** [fix-artifact-title-mechanism.md](plans/fix-artifact-title-mechanism.md)
**Type:** fix

## What shipped

- Corrected `references/titles.md` to state that an HTML `<title>` is the only mechanism that works; a Markdown source cannot set its own title and falls back to its filename; a `title:` frontmatter key is a value to carry *into* a `<title>`, not a mechanism on its own.
- Rewrote `session-artifact/SKILL.md` to produce an HTML render from the Markdown recap before publishing: the render step produces a self-contained HTML file with `<title>` taken from the frontmatter `title:` and the frontmatter block dropped from the body; the publish step targets the HTML path; the `.md` remains the committed record and the home of `artifact-url:`.
- Corrected the republish note in `session-artifact` to require `url` on every republish (not only across sessions), because the HTML render lands on a new scratchpad path each run and a differing `file_path` always claims a new URL.
- Added `tests/plugins/test-artifact-titles.mjs` with 10 assertions covering the corrected titles.md claims, the HTML publishing requirement, the dropped Markdown-direct claim, and the `url`-on-every-republish requirement.
- Wired `test-artifact-titles.mjs` into `publish-dist.yml`.
- Bumped `artifact-tools` to 1.2.1 in `.claude-plugin/marketplace.json` with a matching CHANGELOG entry.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/artifact-tools/references/titles.md` | Corrected title mechanism documentation | Modified |
| `kit/plugins/artifact-tools/skills/session-artifact/SKILL.md` | Publishes HTML render, corrected republish note | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | 1.2.1 fix entry | Modified |
| `.claude-plugin/marketplace.json` | artifact-tools bumped to 1.2.1 | Modified |
| `tests/plugins/test-artifact-titles.mjs` | 10-assertion retention test | Created |
| `.github/workflows/publish-dist.yml` | New test wired in | Modified |

## How it works

The bug was introduced in artifact-tools 1.1.0 when `titles.md` was added as the single source of artifact title rules. It told authors to set the title "as the page's `<title>` for HTML sources, or as frontmatter `title:` for Markdown sources." The second half is false: the Artifact renderer does not parse YAML frontmatter. Publishing a Markdown source emits the frontmatter block as visible body text — the opening `---` becomes an `<hr>`, the YAML becomes a setext `<h2>` — and with no `<title>` in the document, the artifact title falls back to the source's filename including the extension.

The defect was invisible from inside the rules: every check in `titles.md` could be satisfied and the published title was still wrong. It surfaced when a `session-artifact` recap published as `add-plugin-version-guard-session.md` with its YAML rendered as body text.

The fix had two parts. First, `titles.md` was corrected at the root-cause level: the false frontmatter claim was replaced with the true statement. This ensures the next Markdown-publishing skill won't rediscover the bug by following the documented guidance.

Second, `session-artifact` was switched to publish HTML. The skill now produces a render step that wraps the Markdown recap in a minimal HTML shell, sets `<title>` from the frontmatter `title:` value, drops the frontmatter block from the body, and publishes the HTML path. The `.md` file remains the committed record and continues to hold `artifact-url:`, mirroring how `plan-artifact` already keeps a `.md` spec beside published HTML.

The republish correction addresses a subtle consequence: the HTML render path changes on every session because it is written to a scratchpad directory. A differing `file_path` on the `Artifact` tool always claims a new URL. The old framing ("a later session mints a new page") understated the risk — a same-session republish without an explicit `url` also silently mints a new URL. The fix requires `url` on every republish and confirms this with a test assertion.

The 10-assertion test in `test-artifact-titles.mjs` was designed so that every assertion fails against `origin/main`'s copy of the files. This proves the tests discriminate rather than passing vacuously, and it makes the test serve as a regression guard for both the old false claim and the new correct behavior.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| 0fd7b67 | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |

<!-- generated:end -->

## References

- Plan: [fix-artifact-title-mechanism.md](plans/fix-artifact-title-mechanism.md)
