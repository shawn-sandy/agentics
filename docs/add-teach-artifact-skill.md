# Ship teach-artifact, the artifact-tools skill that teaches instead of recaps

> Every existing way to share work in this kit either reports what changed or writes a Markdown file nobody links to. This fills the one empty slot — a shareable page whose job is understanding — and we will know it worked when the plugin's CI guard validates five skills instead of four and the version reaches 1.12.0.

<!-- generated:start -->

**Status:** Shipped 2026-08-07 **Plan:** [add-teach-artifact-skill.md](plans/add-teach-artifact-skill.md)
**Type:** feature

## What shipped

- Added `kit/plugins/artifact-tools/references/teach-framing.md`: fixed section spine for both sources (mental model → how it works today → one path walked end to end → why it is built this way → where to look next); diagram rule (mental-model section earns a diagram by default; every other section keeps recap-core's stricter bar); every diagram carries a caption and a prose sentence; reviewer test that a spine matching team-recap's section list fails; extension seam note for a future source.
- Added `kit/plugins/artifact-tools/skills/teach-artifact/SKILL.md`: delegates source resolution and publishing to `references/recap-core.md`; opts into the 20-file diff-hunk budget for PR mode; uses `teach-artifact-url:` republish key; never writes the four sibling keys.
- Extended `tests/plugins/test-artifact-tools.sh`: added `teach-artifact` to both validation loops; asserted republish-key exclusivity; added overlap guard comparing the spine against `team-recap`'s section list.
- Updated `kit/plugins/artifact-tools/README.md`: Features table (five rows), Usage line, boundary statement distinguishing `write-guide` from `teach-artifact`.
- Updated `kit/plugins/social-media-tools/README.md` with the other half of the boundary statement; bumped social-media-tools 2.22.0 → 2.22.1.
- Bumped artifact-tools 1.11.0 → 1.12.0.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/references/teach-framing.md` | Fixed teaching section spine | Created |
| `kit/plugins/artifact-tools/skills/teach-artifact/SKILL.md` | Skill with delegation | Created |
| `tests/plugins/test-artifact-tools.sh` | Extended validation loops | Modified |
| `kit/plugins/artifact-tools/README.md` | Features table, boundary statement | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | 1.12.0 entry | Modified |
| `kit/plugins/social-media-tools/README.md` | Boundary statement | Modified |
| `kit/plugins/social-media-tools/CHANGELOG.md` | 2.22.1 entry | Modified |
| `.claude-plugin/marketplace.json` | artifact-tools 1.12.0, social-media-tools 2.22.1 | Modified |

## How it works

`teach-artifact` reuses `references/recap-core.md` unchanged — the same source resolution (session or PR), secret-scanning gate, page-build rules, and republish record. It supplies a different frame: the fixed section spine from `teach-framing.md` replaces the recap section list.

The mental-model section earns a diagram by default (inverting recap-core's rule that diagrams are earned only where something changed). Every diagram carries both a caption and a prose sentence conveying the same relationship, because recap-core's fallback ships diagram blocks as plain text, so content living only inside an image disappears on that path.

In PR mode, the skill opts into the 20-file diff-hunk budget so the teaching page has access to actual signatures and error paths that commit messages do not carry.

The CI overlap guard parses the heading list from `teach-framing.md` and fails the build if it matches `team-recap`'s section list — keeping the distinction executable rather than advisory.

## How to use it

```
/artifact-tools:teach-artifact           # teaches the current session
/artifact-tools:teach-artifact pr 42     # teaches PR #42
```

The skill republishes to the same `teach-artifact-url:` on subsequent runs. `social-media-tools:write-guide` produces long-form Markdown you keep in the repository; `teach-artifact` produces a shareable page.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `710593df` | 2026-08-07 | feat(artifact-tools): teach-artifact skill — a shareable page that teaches (1.12.0) + social-media-tools boundary statement (2.22.1) |

<!-- generated:end -->

## References

- Plan: [add-teach-artifact-skill.md](plans/add-teach-artifact-skill.md)
