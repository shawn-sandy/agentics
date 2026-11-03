# Fix the artifact title mechanism

> Corrects artifact-tools' false claim that Markdown frontmatter can set an artifact title, switches `session-artifact` to publish an HTML render, and pins both with a new test.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [fix-artifact-title-mechanism](plans/fix-artifact-title-mechanism.md)
**Type:** fix

## What shipped

- Rewrote `references/titles.md` to state that an HTML `<title>` is the only mechanism — a Markdown source cannot set its own title and falls back to its filename
- Switched `session-artifact` from publishing Markdown directly to publishing an HTML render; the `.md` remains the committed record and holds `artifact-url:`
- Updated the republish note to require `url` on every republish, not only across sessions
- Created `tests/plugins/test-artifact-titles.mjs` asserting the corrected invariants across all four artifact skills
- Bumped `artifact-tools` to 1.2.1

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/references/titles.md` | Reference — artifact title rules | Modified |
| `kit/plugins/artifact-tools/skills/session-artifact/SKILL.md` | Skill — HTML render + republish note | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | Release history | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry — artifact-tools 1.2.1 | Modified |
| `tests/plugins/test-artifact-titles.mjs` | Smoke test — title mechanism invariants | Created |
| `.github/workflows/publish-dist.yml` | CI — new test step | Modified |

## How it works

`artifact-tools` 1.1.0 added `references/titles.md` and told authors to set the title "as the page's `<title>` for HTML sources, or as frontmatter `title:` for Markdown sources." The second half was false. The Artifact renderer does not parse YAML frontmatter — publishing a Markdown source renders the opening `---` as an `<hr>`, the YAML as visible body text, and falls back to the source filename as the tab title.

The failure was invisible from inside the rules: every title rule in `titles.md` could be satisfied and the published title was still wrong. It surfaced when a `session-artifact` recap published as `add-plugin-version-guard-session.md` with its YAML on the page.

`session-artifact` was the only affected skill — `diff-artifact`, `plan-artifact`, and `prompt-artifact` all publish HTML and set a real `<title>`. The fix makes `session-artifact` emit a self-contained HTML file with `<title>` taken from the frontmatter `title:` value and the frontmatter block dropped. The `.md` stays the committed record and holds `artifact-url:`, mirroring how `plan-artifact` already keeps a `.md` spec beside published HTML.

The republish note was tightened because the HTML render lands on a new scratchpad path on every run. A differing `file_path` always claims a new URL, so the old "a later session mints a new page" framing understated the problem — a same-session republish without an explicit `url` would also rot the link.

`test-artifact-titles.mjs` pins all ten invariants: `titles.md` names HTML `<title>` as the only mechanism, names the filename fallback for Markdown, and contains no frontmatter instruction; each skill points at the shared rules; `session-artifact` publishes HTML; and `url` is required on every republish.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [fix-artifact-title-mechanism](plans/fix-artifact-title-mechanism.md)
