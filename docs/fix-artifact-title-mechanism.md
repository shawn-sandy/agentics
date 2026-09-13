# Fix the artifact title mechanism

> Corrects a false claim in `references/titles.md` that Markdown frontmatter can set an artifact title, switches `session-artifact` to publish HTML, and pins both with a test so the defect cannot silently return.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [fix-artifact-title-mechanism.md](plans/fix-artifact-title-mechanism.md)
**Type:** fix

## What shipped

- Replaced the false frontmatter claim in `kit/plugins/artifact-tools/references/titles.md`: the file now states that an HTML `<title>` is the only mechanism, that a Markdown source cannot set its own title (the renderer emits YAML frontmatter as visible body text), and that a `title:` frontmatter key is a value to carry into a `<title>` — never a title in itself.
- Switched `session-artifact` from publishing a `.md` directly to publishing an HTML render: the skill now writes a self-contained HTML file with `<title>` taken from the frontmatter `title:` and the frontmatter block dropped, then publishes the HTML. The `.md` stays the committed record and the home of `artifact-url:`, mirroring how `plan-artifact` already keeps a `.md` spec beside published HTML.
- Corrected the `session-artifact` republish note: `url` is now required on every republish (not only across sessions), because the HTML render lands on a new scratchpad path each run and a differing `file_path` always claims a new URL.
- Added `tests/plugins/test-artifact-titles.mjs` asserting the plan's invariant directly — `titles.md` names the HTML `<title>` as the only mechanism, contains no frontmatter instruction, and every artifact skill points at the shared rules; `session-artifact` publishes HTML and requires `url` on every republish.
- Wired `test-artifact-titles.mjs` into `.github/workflows/publish-dist.yml`.
- Bumped `artifact-tools` from 1.2.0 to 1.2.1 in `.claude-plugin/marketplace.json` and added a CHANGELOG entry.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/references/titles.md` | Single source for artifact title rules — false frontmatter claim removed | Modified |
| `kit/plugins/artifact-tools/skills/session-artifact/SKILL.md` | Switched to HTML publish; republish note corrected | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | 1.2.1 entry | Modified |
| `.claude-plugin/marketplace.json` | artifact-tools bumped to 1.2.1 | Modified |
| `tests/plugins/test-artifact-titles.mjs` | Pins the title-mechanism invariant | Created |
| `.github/workflows/publish-dist.yml` | Wires the new test | Modified |

## How it works

The defect originated in artifact-tools 1.1.0, which added `references/titles.md` as the authoritative title guide and told authors to set titles "as the page's `<title>` for HTML sources, or as frontmatter `title:` for Markdown sources." The second half is false: the Artifact renderer does not parse YAML frontmatter. Publishing a Markdown source emits the opening `---` as an `<hr>`, the YAML as a setext `<h2>`, and, with no `<title>` in the document, the artifact title falls back to the source's filename including extension.

The failure was invisible from inside the rules. Every title rule in `titles.md` could be satisfied and the published title would still be wrong. It surfaced when a `session-artifact` recap published as `add-plugin-version-guard-session.md` with its YAML rendered on the page.

`session-artifact` was the only affected skill: `diff-artifact`, `plan-artifact`, and `prompt-artifact` all already published HTML with a real `<title>`. The fix switches `session-artifact` to publish an HTML render, taking `title:` from the frontmatter as the value for the `<title>` tag while dropping the frontmatter block from the rendered output. The `.md` stays the committed record for the same reason `plan-agent` keeps `.md` specs beside plan HTML: it is the diff-readable, frontmatter-bearing file that commits and that `artifact-url:` persists in.

The republish note correction addresses a live-session observation: the rendered HTML lands in the scratchpad on a new path each run, so a differing `file_path` always mints a new artifact URL. The old note said "a later session mints a new page," understating the problem. The corrected note says `url` is required on every republish.

The test (`test-artifact-titles.mjs`) uses grep-level assertions against fixed strings. Prose quality is hard to test; this invariant — a fixed string either present or absent — is precisely what grep tests well. Every assertion is also designed to fail against `origin/main`'s copy of the file, proving the tests discriminate rather than pass vacuously.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |

<!-- generated:end -->

## References

- Plan: [fix-artifact-title-mechanism.md](plans/fix-artifact-title-mechanism.md)
