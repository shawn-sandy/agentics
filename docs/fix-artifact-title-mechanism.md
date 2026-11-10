# Fix the artifact title mechanism

> The false claim that a Markdown source could set its artifact title via frontmatter was corrected, session-artifact was switched to publish HTML, and a test now pins the invariant.

<!-- generated:start -->

**Status:** Shipped 2026-08-03 **Plan:** [fix-artifact-title-mechanism.md](plans/fix-artifact-title-mechanism.md)
**Type:** fix

## What shipped

- Replaced the false frontmatter claim in `references/titles.md` with the truth: an HTML `<title>` is the only mechanism; a Markdown source cannot set its own title and falls back to its filename, extension included; a `title:` frontmatter key is a value to carry into a `<title>`, not a title in itself.
- Switched `session-artifact` from publishing the `.md` directly to publishing an HTML render — the frontmatter `title:` is carried into the `<title>`, the frontmatter block is dropped from the visible body, and the `.md` remains the committed record and the home of `artifact-url:`.
- Corrected `session-artifact`'s republish note to require the `url` parameter on every republish (not only across sessions), because each run lands on a new scratchpad path and a differing `file_path` always claims a new URL.
- Added `tests/plugins/test-artifact-titles.mjs` asserting the HTML-title-only rule and wired it into `publish-dist.yml`.
- Bumped `artifact-tools` to 1.2.1 in `.claude-plugin/marketplace.json` with a matching CHANGELOG entry (a fix is a PATCH bump per the repo's versioning rules).

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/references/titles.md` | Shared title rules — false frontmatter claim replaced with the HTML-only mechanism | Modified |
| `kit/plugins/artifact-tools/skills/session-artifact/SKILL.md` | Skill instructions — switched to HTML publish; republish note corrected | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | Release history — v1.2.1 entry | Modified |
| `.claude-plugin/marketplace.json` | Marketplace manifest — artifact-tools bumped to 1.2.1 | Modified |
| `tests/plugins/test-artifact-titles.mjs` | Smoke test — pins the HTML-title invariant and every assertion fails against origin/main | Created |
| `.github/workflows/publish-dist.yml` | CI workflow — new test step added beside existing plugin tests | Modified |

## How it works

The bug was a false claim in `references/titles.md`, the shared rules file all `artifact-tools` skills reference. Version 1.1.0 had added this file as the single source of artifact title rules and instructed authors to set the title "as the page's `<title>` for HTML sources, or as frontmatter `title:` for Markdown sources." The second half was wrong: the Artifact renderer does not parse YAML frontmatter. It emits the block as visible body text — the opening `---` becomes an `<hr>` and the YAML becomes a setext heading — and with no `<title>` in the document the title falls back to the source's filename, extension included.

The failure was invisible from inside the rules themselves: every title rule in `titles.md` could be satisfied and the published title would still be wrong. It surfaced when a `session-artifact` recap published as `add-plugin-version-guard-session.md` with its YAML visible as page text and a filename-derived tab title.

The root-cause fix was to `titles.md`. The corrected text now states plainly: "an HTML `<title>` is the only mechanism — a Markdown source cannot set its own title." A `title:` frontmatter key is redefined as a value to carry into a `<title>`, not a title in itself. This closes the gap for any future Markdown-publishing skill that reads the shared rules.

The downstream fix was to `session-artifact`. It was the only `artifact-tools` skill that published a Markdown source directly — `diff-artifact`, `plan-artifact`, and `prompt-artifact` all publish HTML and set a real `<title>`. The skill now adds a render step that produces one self-contained HTML file, takes the `title:` value from the frontmatter and places it in a `<title>`, and drops the frontmatter block from the visible body. The `.md` stays the committed record and the home of `artifact-url:` — exactly mirroring how `plan-artifact` already keeps a `.md` spec beside published HTML.

The republish note was also corrected. The original note said a new session mints a new page when no URL is provided. The subtler truth is that each run of `session-artifact` lands its HTML render in a new scratchpad path, so a different `file_path` always claims a new URL — even within the same session. The corrected note requires the `url` parameter on every republish.

The new test at `tests/plugins/test-artifact-titles.mjs` greps for specific strings in the affected files: the HTML-title-only rule in `titles.md`, the absence of any frontmatter-title instruction, confirmation that `session-artifact` publishes HTML and requires `url` on republish, and that every artifact skill references the shared `titles.md`. The test was designed so every assertion fails against `origin/main` — a check that passes vacuously on both sides of the change is not evidence of anything.

## How to use it

No invocation change. After this fix, `session-artifact` publishes HTML instead of Markdown. The artifact's browser tab and gallery name is derived from the recap's subject in sentence case rather than the source filename, and no YAML frontmatter appears as page text.

The `references/titles.md` rules apply to all current and future `artifact-tools` skills. The operative rule: **set the title as the page's `<title>` — that is the only mechanism.** A Markdown source cannot control its own title.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `fd41fec` | 2026-08-22 | feat: prove merge readiness locally with a verify gate and verified-change skill (#594) |
| `f25758e` | 2026-08-19 | feat(memory-tools): implementing-insights discovers repos, global-dir fallback (4.3.0) (#587) |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |
| `324cc3c` | 2026-08-19 | feat(git-agent): adversarial pre-PR review in PR-opening flows (4.19.3) (#585) |
| `0fd7b67` | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |
| `620ffa8` | 2026-08-19 | docs: sync READMEs with marketplace; fix the dead version-guard hook (#581) |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |
| `ac94d70` | 2026-08-17 | fix(settings-sync): add plan-mode guard to backup and restore skills (#572) |
| `d7598ad` | 2026-08-17 | fix: screenshot output verification and plan Context completeness (#571) |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |
| `ab2f769` | 2026-08-17 | chore: make verification gates a self-enforcing authoring standard (#569) |
| `2fd715f` | 2026-08-17 | fix: redefine done as artifact + verification in five high-impact skills (#568) |
| `875b4c1` | 2026-08-17 | fix: close security-scrub coverage holes in sharing and backup skills (#567) |
| `e1e8840` | 2026-08-15 | feat(git-agent): add post-merge-cleanup skill (4.19.0) (#565) |
| `dbf3844` | 2026-08-14 | fix(plan-agent): add plan-mode guard to plan-status (#562) |
| `744f6e1` | 2026-08-14 | feat(git-agent): add scope guard PreToolUse hook (#560) |
| `c4860d1` | 2026-08-14 | feat: add --check mode to plan renderer for verifying HTML consistency (#556) |
| `c1e6e34` | 2026-08-14 | Run every ship pre-flight guard before reporting, not just the first (#555) |
| `9871dd9` | 2026-08-14 | Add build-fleet: ship a plan backlog in parallel, one worktree agent per plan (#554) |
| `a21acfb` | 2026-08-14 | Verify before asserting: merge guards, measured contrast ratios, review-finding reproduction (#552) |

_Showing 20 of N commits — run `git log` for the full history._

<!-- generated:end -->

## References

- Plan: [fix-artifact-title-mechanism.md](plans/fix-artifact-title-mechanism.md)
- Related docs: `kit/plugins/artifact-tools/CHANGELOG.md`, `kit/plugins/artifact-tools/references/titles.md`
