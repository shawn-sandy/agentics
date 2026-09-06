# Ship teach-artifact, the artifact-tools skill that teaches instead of recaps

> Adds a fifth skill to the `artifact-tools` plugin that publishes a shareable claude.ai page teaching how a system works, rather than recapping what changed — filling the one combination no existing skill produced.

<!-- generated:start -->

**Status:** Shipped 2026-08-15 **Plan:** [add-teach-artifact-skill.md](plans/add-teach-artifact-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/artifact-tools/references/teach-framing.md` with a fixed five-section teaching spine (mental model, how it works today, one end-to-end path walked as an ordered list naming real file/function/command at each point, why it is built this way rather than the obvious alternative, where to look next), diagram rules (mental-model section earns a diagram by default; every diagram carries both a caption and a prose sentence conveying the same relationship), the reviewer test that distinguishes this frame from `team-recap`, and an extension-seam note naming where a future source would attach.
- Created `kit/plugins/artifact-tools/skills/teach-artifact/SKILL.md` with the name and description frontmatter, the verbatim plan-mode guard line, delegation to `references/recap-core.md` for source resolution and publishing, opt-in to the 20-file diff-hunk budget for pull-request mode, and the five declarations every writer in the plugin makes — audience, sections, favicon, inbox stem `teach-artifact` (or `pr-<number>-teach` in PR mode), and republish key `teach-artifact-url:` with an explicit statement forbidding it from writing any sibling's four keys.
- Extended `tests/plugins/test-artifact-tools.sh` to cover the fifth skill: added `teach-artifact` to both the skill-frontmatter loop and the secret-scanning-gate loop, added an assertion that the skill claims `teach-artifact-url:` without claiming any sibling's key, and added a heading-comparison assertion that fails when `teach-framing.md`'s section list matches `team-recap.md`'s — turning the primary risk (a teaching page that silently becomes a second recap) into a build-time catch.
- Added a `teach-artifact` row to the Features table, a Usage line, and the one-line boundary statement (write-guide produces long-form Markdown you keep in the repository; teach-artifact produces a shareable page) to `kit/plugins/artifact-tools/README.md`.
- Added the 1.12.0 CHANGELOG entry in `kit/plugins/artifact-tools/CHANGELOG.md` and raised artifact-tools from 1.11.0 to 1.12.0 in `.claude-plugin/marketplace.json`.
- Added the matching boundary statement to `kit/plugins/social-media-tools/README.md`, added a 2.22.1 CHANGELOG entry, and raised social-media-tools from 2.22.0 to 2.22.1 in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/references/teach-framing.md` | Fixed teaching section spine, diagram and walkthrough rules, reviewer test, extension-seam note | Created |
| `kit/plugins/artifact-tools/skills/teach-artifact/SKILL.md` | The skill, its five declarations, delegation to recap-core | Created |
| `tests/plugins/test-artifact-tools.sh` | Extended validation loops for fifth skill; republish-key exclusivity and anti-overlap assertions | Modified |
| `kit/plugins/artifact-tools/README.md` | Features row, Usage line, boundary statement | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | 1.12.0 entry | Modified |
| `.claude-plugin/marketplace.json` | artifact-tools 1.11.0 → 1.12.0, social-media-tools 2.22.0 → 2.22.1 | Modified |
| `kit/plugins/social-media-tools/README.md` | Boundary statement pointing from write-guide toward teach-artifact | Modified |
| `kit/plugins/social-media-tools/CHANGELOG.md` | 2.22.1 entry | Modified |

## How it works

The `artifact-tools` plugin separates its publishing engine from its framing: the three recap commands (`eng-recap`, `team-recap`, `product-doc`) are 60–68-line files, while all the real machinery — source resolution, the blocking secret-scanning gate, page-build rules, and the republish record — lives in the shared 276-line `references/recap-core.md`. `teach-artifact` reuses `recap-core` unchanged and supplies a different frame, so version 1 ships zero new source-gathering code.

The teaching frame in `teach-framing.md` is what separates this skill from the three recap commands. The section spine is fixed for both sources (session and pull request) rather than picked per source, because a fixed heading list is what makes the anti-overlap assertion in `test-artifact-tools.sh` possible at all — a per-source branch would require two comparisons and could match in one branch while passing in the other. The spine runs: mental model, how it works today, one path walked end to end as an ordered list naming actual code paths, why it is built this way rather than the obvious alternative, where to look next.

The mental-model section earns a diagram by default, inverting `recap-core`'s rule that a diagram is earned only where something changed. A page teaching a system that did not change this week is exactly the page most in need of a diagram. Every diagram carries both a caption (what to look at) and a prose sentence (the same relationship in text), because `recap-core`'s documented fallback ships diagram blocks as plain text when the browser pane is unavailable — content that lives only inside an image disappears on that path.

The skill opts into `recap-core`'s 20-file diff-hunk budget in pull-request mode, as `eng-recap` does and the other two commands deliberately do not, because teaching how something works needs real function signatures and error paths that commit messages never carry.

The republish key `teach-artifact-url:` is declared explicitly, and the skill names the four sibling keys only in the sentence forbidding itself from writing them. This prevents a fifth writer from republishing over a sibling's page, since all five writers share one session record.

The guard in `test-artifact-tools.sh` parses the heading list from `teach-framing.md` and fails if it matches the section list in `team-recap.md`. The test was verified to fail when `team-recap`'s section list is pasted into `teach-framing.md`, proving the guard is executable rather than advisory.

## How to use it

Ask the plugin to publish a teaching page about the current session's work:

```
teach me how the work in this session fits together
```

Or about a pull request:

```
teach me how pull request 42 works
```

The skill activates `teach-artifact` rather than `session-artifact`, runs the blocking secret-scanning gate, then publishes a structured teaching page whose headings come from `teach-framing.md`. A second invocation republishes to the URL stored in `teach-artifact-url:` rather than minting a new link, while leaving `artifact-url:`, `eng-artifact-url:`, `team-artifact-url:`, and `product-artifact-url:` in the session record byte-for-byte unchanged.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `e1e8840` | 2026-08-15 | feat(git-agent): add post-merge-cleanup skill (4.19.0) (#565) |

<!-- generated:end -->

## References

- Plan: [add-teach-artifact-skill.md](plans/add-teach-artifact-skill.md)
