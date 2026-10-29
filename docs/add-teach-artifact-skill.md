# Ship teach-artifact, the artifact-tools skill that teaches instead of recaps

> Adds a fifth skill, `teach-artifact`, to the `artifact-tools` plugin that reads the same sources as the existing recap commands but publishes a page that teaches a reader how the system works rather than reporting what changed.

<!-- generated:start -->

**Status:** Shipped 2026-08-07  **Plan:** [add-teach-artifact-skill.md](plans/add-teach-artifact-skill.md)
**Type:** feature

## What shipped

- Added `kit/plugins/artifact-tools/references/teach-framing.md` — the fixed teaching section spine: mental model first, how it works today, one path walked end-to-end as an ordered list, why it is built this way rather than the obvious alternative, where to look next. Mental model section earns a diagram by default; every diagram carries both a caption and a prose sentence; extension seam documented for future source modes.
- Added `kit/plugins/artifact-tools/skills/teach-artifact/SKILL.md` — delegates source resolution and publishing to `references/recap-core.md` (unchanged), opts into the 20-file diff-hunk budget for PR mode, declares `teach-artifact-url:` as its republish key and explicitly forbids writing the four sibling keys.
- Extended `tests/plugins/test-artifact-tools.sh`: added `teach-artifact` to the skill-validation loop, the secret-scanning gate assertion, a republish-key exclusivity check, and a heading comparison asserting the teach-framing spine does not match team-recap's section list.
- Updated `kit/plugins/artifact-tools/README.md` with a teach-artifact row and a boundary statement distinguishing it from `social-media-tools:write-guide`.
- Added the boundary statement to `kit/plugins/social-media-tools/README.md` pointing readers toward `teach-artifact` when they want a shareable page.
- Bumped `artifact-tools` to `1.12.0` and `social-media-tools` to `2.22.1` in `.claude-plugin/marketplace.json` with CHANGELOG entries for both.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/artifact-tools/references/teach-framing.md` | Teaching section spine | Created |
| `kit/plugins/artifact-tools/skills/teach-artifact/SKILL.md` | Skill instructions | Created |
| `tests/plugins/test-artifact-tools.sh` | Smoke test | Modified |
| `kit/plugins/artifact-tools/README.md` | Plugin documentation | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | Release notes | Modified |
| `kit/plugins/social-media-tools/README.md` | Plugin documentation | Modified |
| `kit/plugins/social-media-tools/CHANGELOG.md` | Release notes | Modified |
| `.claude-plugin/marketplace.json` | Marketplace version | Modified |

## How it works

`teach-artifact` reuses `recap-core.md` unchanged for source resolution and publishing, so version 1 ships zero new source-gathering code. What changes is the frame: instead of summarizing what changed, the skill publishes a page organized around understanding — explaining the mental model, tracing one path end-to-end through the real code, and explaining why the system is built this way.

The PR mode opts into `recap-core`'s 20-file diff-hunk budget (as `eng-recap` does) because teaching how something works requires the actual signatures and error paths that commit messages don't carry.

The CI guard in `test-artifact-tools.sh` includes a heading comparison that fails the build if the teach-framing spine ever drifts to match team-recap's section list, preventing the overlap risk of a teaching page silently becoming a second recap.

## How to use it

```
/artifact-tools:teach-artifact
```

Or invoke with a PR URL to publish a teaching page about the changes in that PR.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|

<!-- generated:end -->

## References

- Plan: [add-teach-artifact-skill.md](plans/add-teach-artifact-skill.md)
