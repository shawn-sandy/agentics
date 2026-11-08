# Ship teach-artifact, the artifact-tools skill that teaches instead of recaps

> Add a fifth skill, `teach-artifact`, to the `artifact-tools` plugin that publishes a shareable claude.ai page teaching how the system works, distinct from the four existing recap commands.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [add-teach-artifact-skill.md](plans/add-teach-artifact-skill.md)
**Type:** feature

## What shipped

- Added `kit/plugins/artifact-tools/references/teach-framing.md` — a fixed five-section teaching spine: mental model first, how it works today, one path walked end-to-end naming real file/function/command at each step, why it's built this way rather than the obvious alternative, and where to look next; each diagram earns one by default (inverting the recap rule) and always carries a caption plus a prose sentence
- Added `kit/plugins/artifact-tools/skills/teach-artifact/SKILL.md` — delegates source resolution and publishing to `references/recap-core.md` unchanged, opts into the 20-file diff-hunk budget for PR mode, declares `teach-artifact-url:` as its sole republish key, and explicitly names the four sibling keys it must not write
- Extended `tests/plugins/test-artifact-tools.sh` to validate the fifth skill, assert the secret-scanning gate precedes publish, check `teach-artifact-url:` exclusivity, and confirm the teaching spine's headings do not match `team-recap`'s section list
- Updated `kit/plugins/artifact-tools/README.md` with a Features row, Usage line, and boundary statement distinguishing `teach-artifact` from `social-media-tools:write-guide`
- Updated `kit/plugins/social-media-tools/README.md` with the other half of the boundary statement
- Bumped artifact-tools to 1.12.0 and social-media-tools to 2.22.1 with CHANGELOG entries

> See [CHANGELOG v1.12.0](../kit/plugins/artifact-tools/CHANGELOG.md) for the authoritative feature list.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/references/teach-framing.md` | Teaching section spine and diagram rules | Created |
| `kit/plugins/artifact-tools/skills/teach-artifact/SKILL.md` | Skill instructions | Created |
| `tests/plugins/test-artifact-tools.sh` | Extended for fifth skill | Modified |
| `kit/plugins/artifact-tools/README.md` | Features, Usage, boundary statement | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | 1.12.0 entry | Modified |
| `kit/plugins/social-media-tools/README.md` | Boundary statement | Modified |
| `kit/plugins/social-media-tools/CHANGELOG.md` | 2.22.1 entry | Modified |
| `.claude-plugin/marketplace.json` | artifact-tools 1.12.0, social-media-tools 2.22.1 | Modified |

## How it works

`teach-artifact` reuses `references/recap-core.md` unchanged — the same 276-line shared engine that owns source resolution, the blocking secret-scanning gate, page-build rules, and the republish record for all four existing recap commands. Version 1 ships zero new source-gathering code.

What differs is the frame. While `eng-recap`, `team-recap`, and `product-doc` supply an audience and a section list oriented around "what changed", `teach-artifact` supplies `references/teach-framing.md` as its section reference. The fixed spine forces the mental-model section first, then a concrete walk-through naming the real file, function, or command at each point, then the design rationale. This structure is what prevents the skill from silently degrading into a second `team-recap`.

The mental-model section earns a diagram by default (inverting recap-core's stricter "diagram only where something changed" rule) because a teaching page about a stable system is precisely the page most in need of a diagram. Every diagram carries both a caption and a prose sentence conveying the same relationship, so the content survives `recap-core`'s documented fallback that ships diagram blocks as plain text when the browser pane is unavailable.

The skill opts into recap-core's 20-file diff-hunk budget for pull-request mode (as `eng-recap` does and the other commands deliberately do not) because teaching how something works requires the actual signatures and error paths that commit messages alone do not carry. The republish key is `teach-artifact-url:`, separate from all four sibling keys, so a re-run finds and reuses the stored URL rather than minting a new one.

The CI guard at `tests/plugins/test-artifact-tools.sh` was updated to cover the fifth skill in both validation loops and to assert that the teaching spine's section headings do not match `team-recap`'s list — turning the main overlap risk into something the build catches.

## How to use it

The skill activates when you ask to publish a page teaching how something works. Explicit invocation:

```
/artifact-tools:teach-artifact                                   # from current session
/artifact-tools:teach-artifact <PR-number>                       # from a pull request
```

On first run it publishes a new artifact and writes `teach-artifact-url:` to the session record. A second run republishes to the stored URL.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `02136c1` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [add-teach-artifact-skill.md](plans/add-teach-artifact-skill.md)
- Changelog: [artifact-tools CHANGELOG](../kit/plugins/artifact-tools/CHANGELOG.md)
- Related: [kit/plugins/artifact-tools/references/teach-framing.md](../kit/plugins/artifact-tools/references/teach-framing.md)
- Related: [kit/plugins/artifact-tools/references/recap-core.md](../kit/plugins/artifact-tools/references/recap-core.md)
