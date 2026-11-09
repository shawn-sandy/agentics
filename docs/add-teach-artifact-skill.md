# Ship teach-artifact, the artifact-tools skill that teaches instead of recaps

> Add a fifth skill to artifact-tools that publishes a claude.ai page teaching how a system works, rather than recapping what changed — filling the one slot nothing in the kit produced.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [add-teach-artifact-skill.md](plans/add-teach-artifact-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/artifact-tools/references/teach-framing.md` with a fixed teaching section spine: mental model first, then how the system works today, an end-to-end walkthrough, why it's built this way rather than the obvious alternative, and where to look next. Includes a diagram-by-default rule for the mental-model section and an extension-seam note for future sources.
- Created `kit/plugins/artifact-tools/skills/teach-artifact/SKILL.md` delegating source resolution and publishing to `recap-core.md`, opting into the 20-file diff-hunk budget for PR mode, and writing only `teach-artifact-url:` as its republish key (never the four sibling keys).
- Extended `tests/plugins/test-artifact-tools.sh` to validate teach-artifact's frontmatter, assert the secret-scanning gate is documented before publishing, and compare teach-framing.md's heading list against team-recap.md to catch overlap.
- Updated artifact-tools README with a fifth skill row, usage line, and boundary statement distinguishing teach-artifact from write-guide.
- Added the mirror boundary statement to social-media-tools README.
- Bumped artifact-tools to 1.12.0 and social-media-tools to 2.22.1 with CHANGELOG entries.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/references/teach-framing.md` | Teaching section spine and rules | Created |
| `kit/plugins/artifact-tools/skills/teach-artifact/SKILL.md` | Skill with five declarations | Created |
| `tests/plugins/test-artifact-tools.sh` | Extended to cover fifth skill | Modified |
| `kit/plugins/artifact-tools/README.md` | Features table and boundary statement | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | 1.12.0 entry | Modified |
| `.claude-plugin/marketplace.json` | artifact-tools 1.12.0, social-media-tools 2.22.1 | Modified |
| `kit/plugins/social-media-tools/README.md` | Mirror boundary statement | Modified |
| `kit/plugins/social-media-tools/CHANGELOG.md` | 2.22.1 entry | Modified |

## How it works

The skill reuses `references/recap-core.md` unchanged — the same source-resolution, secret-scanning gate, page-build rules, and republish record the other four artifact-tools skills use. `teach-artifact` supplies a different frame: the sections come from `teach-framing.md` rather than from each command's individual section list.

The teaching spine is fixed for both the session source and pull-request source so that the anti-overlap assertion in the test is possible: `test-artifact-tools.sh` parses the heading list from `teach-framing.md` and fails the build if it matches `team-recap.md`'s section list. This turns the main risk — a teaching page that silently degrades into a second team-recap — from something a reviewer has to notice into something CI catches.

The skill opts into recap-core's 20-file diff-hunk budget for PR mode (matching `eng-recap`) because teaching how something works requires real signatures and error paths, which commit messages don't carry. The other three recap commands deliberately skip this budget.

Diagrams earn a lower bar in the mental-model section: a page teaching a system that didn't change this week needs a diagram most. Every diagram carries both a caption and a prose sentence conveying the same relationship, because recap-core's fallback renders diagram blocks as plain text when the browser pane is unavailable.

The republish key `teach-artifact-url:` is the only key the skill writes. The SKILL.md explicitly names the four sibling keys (`artifact-url:`, `eng-artifact-url:`, `team-artifact-url:`, `product-artifact-url:`) in a sentence forbidding itself from writing them, so a fifth writer can't republish over a sibling's page.

## How to use it

Activated by asking to "teach", "explain how this works", or "publish a teaching page" about the current session or a pull request. The skill auto-activates via its description.

```
teach me how this session's work fits together
/plan-agent:teach-artifact
teach how PR #534 works
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `02136c1d` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [add-teach-artifact-skill.md](plans/add-teach-artifact-skill.md)
- Related: `kit/plugins/artifact-tools/references/recap-core.md` — the shared engine teach-artifact delegates to
- Related: `kit/plugins/artifact-tools/references/teach-framing.md` — the fixed teaching section spine
