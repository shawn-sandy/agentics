# Fix the artifact title mechanism

> Corrects the false claim that Markdown frontmatter can set an artifact title, switches session-artifact to publish HTML, and pins the correct mechanism with a test so the defect cannot return.

<!-- generated:start -->

**Status:** Shipped 2026-07-15 **Plan:** [fix-artifact-title-mechanism.md](plans/fix-artifact-title-mechanism.md)
**Type:** fix

## What shipped

- Replaced the false frontmatter claim in `references/titles.md` with the truth: an HTML `<title>` is the only mechanism; a Markdown source cannot set its own title and falls back to its filename; a `title:` key is a value to carry into a `<title>` (removes the silent defect source that let every author satisfy the rule while publishing a wrong title).
- Switched `session-artifact` from publishing Markdown directly to publishing a self-contained HTML render, with `<title>` taken from the frontmatter `title:` field and the YAML frontmatter block omitted from page body (the `.md` file remains the committed record and the holder of `artifact-url:`).
- Corrected the republish note to require `url` on every republish, not only across sessions, because a scratchpad-pathed HTML render always claims a new URL when `file_path` changes.
- Added `tests/plugins/test-artifact-titles.mjs` asserting the invariant at grep level — `titles.md` names HTML `<title>` as sole mechanism, `session-artifact` publishes HTML, `url` is required on every republish — and wired it into `.github/workflows/publish-dist.yml`.
- Bumped `artifact-tools` to 1.2.1 (patch: bug fix with no component added or removed).

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/references/titles.md` | Artifact title rules — frontmatter claim replaced | Modified |
| `kit/plugins/artifact-tools/skills/session-artifact/SKILL.md` | Switches to HTML render; fixes republish note | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | 1.2.1 entry | Modified |
| `.claude-plugin/marketplace.json` | artifact-tools bumped to 1.2.1 | Modified |
| `tests/plugins/test-artifact-titles.mjs` | Pins the invariant; 10 assertions | Created |
| `.github/workflows/publish-dist.yml` | Runs the new test | Modified |

## How it works

The root defect lived in `references/titles.md`, the shared title-rules file loaded by all artifact-tools skills. It told authors to set the artifact title "as the page's `<title>` for HTML sources, or as frontmatter `title:` for Markdown sources." The second half is false: the Artifact renderer does not parse YAML frontmatter. Publishing a Markdown source emits the `---` block as an `<hr>` and the YAML key-value pairs as setext headings, and — with no `<title>` in the document — the artifact title falls back to the source filename, extension included. A session recap published as `add-plugin-version-guard-session.md` exposed the bug live.

Fixing only `session-artifact` without correcting `titles.md` would leave the next Markdown-publishing skill to rediscover the same defect. So the root-cause fix is the `titles.md` rewrite: a Markdown source cannot set its own title; authors who need a title must produce HTML.

`session-artifact` was the only skill that published Markdown directly. Switching it to publish HTML requires a render step: the skill now produces one self-contained HTML file with `<title>` populated from the frontmatter `title:` key and the frontmatter block itself dropped from the page body. The `.md` file remains the committed record and continues to hold the `artifact-url:` key, mirroring how `plan-artifact` already keeps a Markdown spec alongside published HTML.

The republish note required a separate correction. The old framing said a "later session mints a new page" — understating the problem. Because the HTML file is written to a scratchpad path that changes each run, a differing `file_path` always claims a new URL even within the same session. The corrected note requires passing `url` on every republish, not just cross-session ones.

The test (`test-artifact-titles.mjs`) pins the invariant at grep level — fixed strings that are either present or absent. This is weak evidence of prose quality but strong evidence of this specific contract, which is what matters for a regression guard.

## How to use it

`/artifact-tools:session-artifact` — no invocation change. The skill now internally builds and publishes an HTML render rather than the raw Markdown. The `.md` recap file still appears under the configured plans/sessions directory and still carries the `artifact-url:` republish key.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `ded28e0` | 2026-07-15 | feat: add plugin version guard and fix artifact title mechanism (#410) |
| `4d0d46a` | 2026-07-15 | feat(artifact-tools): generate readable titles for published artifacts (#406) |

<!-- generated:end -->

## References

- Plan: [fix-artifact-title-mechanism.md](plans/fix-artifact-title-mechanism.md)
