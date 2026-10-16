# Ship teach-artifact, the artifact-tools skill that teaches instead of recaps

> Added a fifth skill, `teach-artifact`, to the `artifact-tools` plugin. It publishes a claude.ai page that teaches how a system works rather than recapping what changed, reusing `recap-core.md`'s source resolution and publishing engine unchanged.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-teach-artifact-skill.md](plans/add-teach-artifact-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/artifact-tools/references/teach-framing.md`, the fixed teaching section spine (mental model → how it works today → one path walked end to end → why it's built this way → where to look next) plus diagram rules, the reviewer test distinguishing it from `team-recap`, and an extension-seam note naming where a future third source would attach.
- Created `kit/plugins/artifact-tools/skills/teach-artifact/SKILL.md` with the five declarations every artifact-tools writer makes (audience, sections, favicon, inbox stem `teach-artifact`/`pr-<number>-teach`, republish key `teach-artifact-url:`), opt-in to the 20-file diff-hunk budget for pull-request mode, delegation to `references/recap-core.md`, and an explicit statement forbidding use of the four sibling republish keys.
- Extended `tests/plugins/test-artifact-tools.sh` to add `teach-artifact` to both validation loops, assert secret-scanning gate precedence, assert `teach-artifact-url:` ownership and sibling-key exclusivity, and add a heading-comparison check that fails if `teach-framing.md`'s section list matches `team-recap.md`'s.
- Updated `kit/plugins/artifact-tools/README.md` with a `teach-artifact` row in the Features table, a Usage line, and the boundary statement distinguishing it from `write-guide`.
- Added the `artifact-tools` 1.12.0 CHANGELOG entry and bumped the version in `.claude-plugin/marketplace.json`.
- Added the boundary statement to `kit/plugins/social-media-tools/README.md` (pointing readers from `write-guide` toward `teach-artifact` for shareable pages), added a `social-media-tools` 2.22.1 CHANGELOG entry, and bumped `social-media-tools` from 2.22.0 to 2.22.1 in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/references/teach-framing.md` | Fixed teaching section spine, diagram rules, reviewer test, extension-seam note | Created |
| `kit/plugins/artifact-tools/skills/teach-artifact/SKILL.md` | The skill — five declarations, delegation to `recap-core`, diff-budget opt-in | Created |
| `tests/plugins/test-artifact-tools.sh` | Extended to cover fifth skill, heading-comparison overlap guard | Modified |
| `kit/plugins/artifact-tools/README.md` | Features row, Usage line, boundary statement | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | 1.12.0 entry | Modified |
| `.claude-plugin/marketplace.json` | artifact-tools 1.11.0 → 1.12.0, social-media-tools 2.22.0 → 2.22.1 | Modified |
| `kit/plugins/social-media-tools/README.md` | Other half of the boundary statement | Modified |
| `kit/plugins/social-media-tools/CHANGELOG.md` | 2.22.1 entry | Modified |

## How it works

`artifact-tools` separates its publishing engine from its framing. Three recap commands (`eng-recap`, `team-recap`, `product-doc`) are short 60–68-line files; all source resolution, secret-scanning gate, page-build rules, and republish record logic live in `references/recap-core.md`. Each command declares only five things: audience, section list, favicon, inbox filename stem, and republish key.

`teach-artifact` follows the same pattern. It delegates source resolution and publishing to `recap-core.md` unchanged and supplies a different frame via `teach-framing.md`. No new source-gathering code was written.

The section spine in `teach-framing.md` is fixed for both sources (session and pull request): mental model first, then how the system works today, then one path walked end to end as an ordered list naming the real file, function, or command at each point, then why it is built this way rather than the obvious alternative, then where to look next. The fixed list enables the anti-overlap assertion in the test: if `teach-framing.md`'s heading list matches `team-recap`'s, the build fails.

Three deliberate choices shape the skill's behavior. The 20-file diff-hunk budget (matching `eng-recap`) is opted into for pull-request mode because teaching how something works needs the actual signatures and error paths that commit messages do not carry. The mental-model section earns a diagram by default, inverting `recap-core`'s rule that a diagram is earned only where something changed — a teaching page about a system that did not change this week is exactly where a diagram is most needed. Every diagram carries both a caption and a prose sentence carrying the same relationship, because `recap-core`'s documented fallback ships diagram blocks as plain text when the browser pane is unavailable.

The republish key is `teach-artifact-url:`. The skill explicitly names the four sibling keys and forbids writing them, preventing a fifth writer from republishing over a sibling's page (all five writers share one session record under `docs/plans/sessions/`).

The Completion Report noted that the live-run verification steps (load plugin, publish a teaching page, re-run and diff the session record) were verified structurally against file contents rather than by execution, since the session is non-interactive and a real publish is an outward-facing action.

## How to use it

Load the plugin and ask it to publish a teaching page:

```
/artifact-tools:teach-artifact
```

From a pull request:

```
/artifact-tools:teach-artifact pr/123
```

The skill activates on requests phrased as "teach", "explain how this works", "publish a page explaining", or similar. It reads the session or pull request, applies the `teach-framing.md` spine, and publishes to a claude.ai artifact stored in `teach-artifact-url:` in the session record. A second run republishes to the same URL.

**Boundary with `write-guide`:** `social-media-tools:write-guide` produces long-form Markdown you keep in the repository. `teach-artifact` produces a shareable claude.ai page. Use `write-guide` when you want a file; use `teach-artifact` when you want a link to share.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |

<!-- generated:end -->

## References

- Plan: [add-teach-artifact-skill.md](plans/add-teach-artifact-skill.md)
