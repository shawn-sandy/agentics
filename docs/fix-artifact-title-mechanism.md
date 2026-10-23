# Fix the artifact title mechanism

> Replace a false claim in `references/titles.md` — that Markdown frontmatter sets an artifact title — with the truth, switch `session-artifact` from direct Markdown publish to HTML render, and pin both with a test so the defect cannot return.

<!-- generated:start -->

**Status:** Shipped 2026-07-15 **Plan:** [fix-artifact-title-mechanism.md](plans/fix-artifact-title-mechanism.md)
**Type:** fix

## What shipped

- Corrected `references/titles.md` to state that an HTML `<title>` is the only mechanism; a Markdown source cannot set its own title and falls back to its filename
- Rewrote `session-artifact`'s Overview premise to add an HTML render step that produces a self-contained file with `<title>` taken from the frontmatter `title:` key and the frontmatter block dropped
- Corrected the republish note to require `url` on every republish, not only across sessions
- Added `tests/plugins/test-artifact-titles.mjs` with 10 assertions pinning the invariant
- Wired the new test into `.github/workflows/publish-dist.yml`
- Bumped `artifact-tools` to 1.2.1 and added the CHANGELOG entry

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/references/titles.md` | Title rules (corrected) | Modified |
| `kit/plugins/artifact-tools/skills/session-artifact/SKILL.md` | HTML render + republish fix | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | 1.2.1 entry | Modified |
| `.claude-plugin/marketplace.json` | artifact-tools bumped to 1.2.1 | Modified |
| `tests/plugins/test-artifact-titles.mjs` | Title invariant smoke test | Created |
| `.github/workflows/publish-dist.yml` | Test wired | Modified |

## How it works

`artifact-tools` 1.1.0 added `references/titles.md` as the single source of artifact title rules and stated that Markdown sources could set their title via frontmatter `title:`. This was false. The Artifact renderer does not parse YAML frontmatter. Publishing a Markdown source causes the opening `---` to render as an `<hr>` and the YAML body to render as a setext `<h2>`; with no `<title>` in the document the artifact title falls back to the source filename, extension included. The defect surfaced when a `session-artifact` recap published as `add-plugin-version-guard-session.md` with its YAML visible on the page.

The fix has three parts. First, `titles.md` is corrected to name the HTML `<title>` as the only mechanism, state that a Markdown source cannot set its own title and falls back to its filename, and remove the frontmatter prescription. A `title:` frontmatter key is now described as a value to carry into a `<title>`, not a mechanism in its own right.

Second, `session-artifact` switches from publishing its `.md` directly to publishing an HTML render of it. The `.md` under `{plansDirectory}/sessions/` stays the committed record and the home of `artifact-url:`; a render step produces a separate self-contained HTML file with `<title>` set from the frontmatter `title:` and the frontmatter block stripped from the body. This mirrors how `plan-artifact` already keeps a `.md` spec beside published HTML.

Third, the republish note is corrected. The render lands on a new scratchpad path each run, so a differing `file_path` would mint a new artifact URL even within the same session. The old "a later session mints a new page" framing understated the risk. The note now requires `url` on every republish.

`diff-artifact`, `plan-artifact`, and `prompt-artifact` were never affected — they all publish HTML and set a real `<title>`. The fix is scoped exactly to the root cause in `titles.md` and the one downstream skill that published Markdown directly.

`tests/plugins/test-artifact-titles.mjs` has 10 assertions: that `titles.md` names the HTML `<title>` as the only mechanism; that `titles.md` contains no instruction to set a title via frontmatter; that every artifact skill points at the shared rules; that `session-artifact` publishes HTML and drops the Markdown-direct claim; and that the `url` required-on-every-republish note is present. Every assertion was confirmed to fail against `origin/main`, proving the tests discriminate.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |

<!-- generated:end -->

## References

- Plan: [fix-artifact-title-mechanism.md](plans/fix-artifact-title-mechanism.md)
