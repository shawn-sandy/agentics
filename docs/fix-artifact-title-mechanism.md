# Fix the artifact title mechanism

> Make every artifact-tools skill produce a readable, meaningful title by stating the one mechanism that works (an HTML `<title>`), switching `session-artifact...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [fix-artifact-title-mechanism.md](plans/fix-artifact-title-mechanism.md)
**Type:** fix

## What shipped

- Replace the frontmatter claim in `titles.md` — with the truth: an HTML `<title>` is the only mechanism; a Markdown source cannot set its own title and falls back to its filename; a `title:` key is a value to carry into a `<title>`. -
- Switch `session-artifact` to publish an HTML render. — Rewrite the Overview premise ("publishes the Markdown directly ... at the lowest token cost"), add a render step producing one self-contained HTML file with `<title>` taken from the frontmatter `title:` and the frontmatter block dropped, and point the publish step at the HTML path. -
- Correct the republish note — to require `url` on every republish, not only across sessions. -
- Add `tests/plugins/test-artifact-titles.mjs` and wire it into `publish-dist.yml`. —
- Bump `artifact-tools` to 1.2.1 and add the CHANGELOG entry. —

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/skills/session-artifact/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/artifact-tools/references/titles.md` | Reference documentation | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | Changelog | Modified |
| `.claude-plugin/marketplace.json` | Marketplace entry | Modified |
| `tests/plugins/test-artifact-titles.mjs` | Test suite | Created |

## How it works

Make every artifact-tools skill produce a readable, meaningful title by stating the one mechanism that works (an HTML `<title>`), switching `session-artifact` to publish an HTML render, and pinning both with a test so the false claim cannot return.

[artifact-tools 1.1.0](../../kit/plugins/artifact-tools/CHANGELOG.md) added `references/titles.md` as the single source of artifact title rules, and told authors to set the title "as the page's `<title>` for HTML sources, or as frontmatter `title:` for Markdown sources." The second half is false. The Artifact renderer does not parse YAML frontmatter. Publishing a Markdown source emits the frontmatter block as visible body text — the opening `---` becomes an `<hr>` and the YAML becomes a setext `<h2>` — and, with no `<title>` in the document, the artifact title falls back to the source's filename, extension included. The failure is invisible from inside the rules: every title rule in `titles.md` can be satisfied and the published title is still wrong. It surfaced only when a `session-artifact` recap published as `add-plugin-version-guard-session.md` with its YAML on the page. `session-artifact` is the only skill affected — `diff-artifact`, `plan-artifact`, and `prompt-artifact` all publish HTML and set a real `<title>`.

The implementation proceeded through the following steps: Replace the frontmatter claim in `titles.md` — with the truth: an HTML `<title>` is the only mechanism; a Markdown source cannot set its own title and falls back to its filename; a `title:` key is a value to carry into a `<title>`. -; Switch `session-artifact` to publish an HTML render. — Rewrite the Overview premise ("publishes the Markdown directly ... at the lowest token cost"), add a render step producing one self-contained HTML file with `<title>` taken from the frontmatter `title:` and the frontmatter block dropped, and point the publish step at the HTML path. -; Correct the republish note — to require `url` on every republish, not only across sessions. -; Add `tests/plugins/test-artifact-titles.mjs` and wire it into `publish-dist.yml`. —; Bump `artifact-tools` to 1.2.1 and add the CHANGELOG entry. —.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| — | — | implementing commit not in plan file history |

<!-- generated:end -->

## References

- Plan: [fix-artifact-title-mechanism.md](plans/fix-artifact-title-mechanism.md)
