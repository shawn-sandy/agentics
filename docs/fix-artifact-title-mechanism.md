# Fix the artifact title mechanism

> Corrects a false claim in `references/titles.md` that YAML frontmatter can set an artifact title, switches `session-artifact` to publish an HTML render instead of Markdown, and adds a test that pins both invariants.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [fix-artifact-title-mechanism.md](plans/fix-artifact-title-mechanism.md)
**Type:** fix

## What shipped

- Replaced the false frontmatter claim in `kit/plugins/artifact-tools/references/titles.md`: the HTML `<title>` element is now stated as the only mechanism; Markdown sources cannot set their own title and fall back to the filename (extension included); a `title:` frontmatter key is a value to carry *into* a `<title>`, not a mechanism itself.
- Switched `session-artifact` from publishing Markdown directly to publishing a self-contained HTML render with `<title>` taken from the frontmatter `title:` and the frontmatter block dropped. The `.md` file remains the committed record and the home of `artifact-url:`, mirroring how `plan-artifact` already keeps a `.md` spec beside published HTML.
- Corrected the republish note in `session-artifact` to require `url` on every republish (not only across sessions), because the HTML scratchpad path changes each run and a differing `file_path` always mints a new URL.
- Added `tests/plugins/test-artifact-titles.mjs` with 10 assertions; every assertion was verified to fail against `origin/main`.
- Bumped `artifact-tools` to 1.2.1 in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/references/titles.md` | Artifact title rules (corrected) | Modified |
| `kit/plugins/artifact-tools/skills/session-artifact/SKILL.md` | Switched to HTML publish; fixed republish note | Modified |
| `tests/plugins/test-artifact-titles.mjs` | Pins the title-mechanism invariant | Created |
| `.claude-plugin/marketplace.json` | artifact-tools bumped to 1.2.1 | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | 1.2.1 entry | Modified |
| `.github/workflows/publish-dist.yml` | New test wired in | Modified |

## How it works

The root cause was a false claim that shipped in artifact-tools 1.1.0: `titles.md` told authors to set the artifact title "as the page's `<title>` for HTML sources, or as frontmatter `title:` for Markdown sources." The second half was wrong. The Artifact renderer does not parse YAML frontmatter; publishing a Markdown source emits the frontmatter block as visible body text (`---` becomes `<hr>`, the YAML becomes a setext `<h2>`), and with no `<title>` in the document the artifact title falls back to the filename with its extension.

The fix had two parts. First, `titles.md` was rewritten to state only the working mechanism: an HTML `<title>`. A Markdown source cannot set its own title; a `title:` frontmatter key is input data to place inside a `<title>` during an HTML render step. Second, `session-artifact` — the only skill in the plugin that published Markdown directly — was updated to perform an HTML render step, dropping the frontmatter block and carrying the `title:` value into `<title>`. The `.md` file is kept as the committed record because it carries `artifact-url:` in its frontmatter and is diffable; the HTML is produced in the scratchpad for each publish run.

The republish fix addresses a subtlety: because the HTML is generated into the scratchpad on each run, its path changes every time. The `Artifact` tool uses `file_path` to determine whether a publish creates a new artifact or updates an existing one — a differing path always creates a new one, regardless of session. The skill therefore requires `url` on every republish, reading it from the `.md`'s `artifact-url:` frontmatter.

`tests/plugins/test-artifact-titles.mjs` asserts that `titles.md` names HTML `<title>` as the only mechanism, prescribes no frontmatter title, that `session-artifact` publishes HTML and requires `url` on republish, and that every artifact skill references the shared title rules file. The test was run against `origin/main` to confirm every assertion failed before the fix.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `02136c1` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [fix-artifact-title-mechanism.md](plans/fix-artifact-title-mechanism.md)
- Related: [kit/plugins/artifact-tools/references/titles.md](../kit/plugins/artifact-tools/references/titles.md)
- Related: [kit/plugins/artifact-tools/CHANGELOG.md](../kit/plugins/artifact-tools/CHANGELOG.md)
