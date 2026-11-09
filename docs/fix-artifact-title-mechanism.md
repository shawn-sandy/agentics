# Fix the artifact title mechanism

> Corrects a false claim in `artifact-tools` — Markdown frontmatter cannot set an artifact title — and switches `session-artifact` to publish HTML so all three skills produce readable titles.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [fix-artifact-title-mechanism.md](plans/fix-artifact-title-mechanism.md)
**Type:** fix

## What shipped

- Corrected `kit/plugins/artifact-tools/references/titles.md`: an HTML `<title>` is the only mechanism that works; a Markdown source cannot set its own title and falls back to its filename with extension.
- Switched `session-artifact` from publishing Markdown directly to publishing an HTML render that carries a `<title>` derived from the frontmatter `title:` key, with the frontmatter block dropped from the page body.
- Corrected the republish note to require the `url` parameter on _every_ republish (not only across sessions), because a new scratchpad path on each run means a differing `file_path` always claims a new URL.
- Shipped `tests/plugins/test-artifact-titles.mjs` with 10 assertions that verify the corrected claim is present and that all assertions fail against `origin/main`.
- Bumped artifact-tools to 1.2.1 in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/references/titles.md` | Title mechanism rules | Modified |
| `kit/plugins/artifact-tools/skills/session-artifact/SKILL.md` | Session recap skill | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | 1.2.1 entry | Modified |
| `.claude-plugin/marketplace.json` | Version bump | Modified |
| `tests/plugins/test-artifact-titles.mjs` | Title invariant test | Created |

## How it works

The root cause was a false instruction in `titles.md` telling authors to set artifact titles via YAML frontmatter for Markdown sources. The Artifact renderer does not parse YAML frontmatter — it emits the opening `---` as an `<hr>` and the YAML fields as a setext `<h2>`, and the artifact title falls back to the source filename (extension included) because no `<title>` element exists.

`session-artifact` was the only skill that published Markdown directly. The fix keeps the `.md` as the committed record and the home of `artifact-url:` frontmatter, then adds a render step that produces a self-contained HTML file with `<title>` taken from the frontmatter `title:` and the frontmatter block stripped from the body. The Artifact publish step targets the HTML path instead. This mirrors how `plan-artifact` already keeps a `.md` spec beside published HTML.

The republish correction is a consequence of the render step: the HTML lands on a new scratchpad path each run, so even a same-session republish would mint a new URL without an explicit `url` parameter. The old "a later session mints a new page" framing was too narrow.

`tests/plugins/test-artifact-titles.mjs` uses grep-level assertions against the actual shipped files. These are weak evidence of prose quality but strong evidence of the invariant — the corrected strings are either present or they are not — and every assertion was verified to fail against `origin/main`.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `02136c1d` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [fix-artifact-title-mechanism.md](plans/fix-artifact-title-mechanism.md)
- Related: [create-artifact-tools-plugin.md](create-artifact-tools-plugin.md)
