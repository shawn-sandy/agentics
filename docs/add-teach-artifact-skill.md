# Ship teach-artifact, the artifact-tools skill that teaches instead of recaps

> Adds a fifth skill, `teach-artifact`, to the artifact-tools plugin: reads the same sources as the recap commands but publishes a page that teaches how the system works rather than reporting what changed.

<!-- generated:start -->

**Status:** Shipped 2026-08-18 **Plan:** [add-teach-artifact-skill.md](plans/add-teach-artifact-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/artifact-tools/references/teach-framing.md` — the fixed five-part teaching spine (mental model, how it works today, one path end to end, why it is built this way, where to look next), two diagram rules, and the reviewer test keeping it distinct from `team-recap`
- Created `kit/plugins/artifact-tools/skills/teach-artifact/SKILL.md` — the skill with plan-mode guard, delegation to `recap-core.md` and `teach-framing.md`, 20-file diff budget opt-in, audience definition, and `teach-artifact-url:` republish key
- Extended `tests/plugins/test-artifact-tools.sh` to cover a fifth skill: added `teach-artifact` to both validation loops, asserted republish-key exclusivity, and added the heading-comparison check that fails if `teach-framing.md`'s spine matches `team-recap`'s section list
- Updated `kit/plugins/artifact-tools/README.md` with a Features table row, Usage line, and the boundary statement distinguishing `teach-artifact` from `write-guide`
- Added the 1.12.0 CHANGELOG entry; bumped artifact-tools from 1.11.0 to 1.12.0 in `.claude-plugin/marketplace.json`
- Added the complementary boundary statement to `kit/plugins/social-media-tools/README.md`; bumped social-media-tools from 2.22.0 to 2.22.1 with a matching CHANGELOG entry

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/references/teach-framing.md` | Fixed teaching section spine, diagram rules, extension seam | Created |
| `kit/plugins/artifact-tools/skills/teach-artifact/SKILL.md` | The skill: five declarations, delegation to recap-core, framing overrides | Created |
| `tests/plugins/test-artifact-tools.sh` | Extended for fifth skill and heading-comparison anti-overlap check | Modified |
| `kit/plugins/artifact-tools/README.md` | Features row, Usage line, boundary statement | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | 1.12.0 entry | Modified |
| `.claude-plugin/marketplace.json` | artifact-tools 1.11.0 → 1.12.0, social-media-tools 2.22.0 → 2.22.1 | Modified |
| `kit/plugins/social-media-tools/README.md` | Boundary statement pointing readers toward teach-artifact | Modified |
| `kit/plugins/social-media-tools/CHANGELOG.md` | 2.22.1 entry | Modified |

## How it works

The `artifact-tools` plugin already separates gathering from framing. Three recap commands (`eng-recap`, `team-recap`, `product-doc`) are 60–68 lines each; all shared machinery — source resolution, secret-scanning gate, page build, republish record — lives in `references/recap-core.md`. Each command supplies only its audience, section list, favicon, inbox stem, and republish key.

`teach-artifact` follows the same structure: it delegates everything to `recap-core.md` and supplies a different frame. The only new source file is `references/teach-framing.md`, which defines the fixed five-part teaching spine:

1. **Mental model** — earns a diagram by default (inverts recap-core's stricter earned-diagram rule)
2. **How it works today** — present tense, moving parts
3. **One path end to end** — ordered list naming real files, functions, and commands
4. **Why it is built this way** — the obvious alternative and why it lost
5. **Where to look next** — two or three files and the question each answers

All five sections are always kept. `recap-core.md` allows a caller to declare sections as omit-if-empty; `teach-framing.md` overrides that entirely — a source that cannot fill a section signals the subject is too thin to teach. Every diagram must carry both a caption and a prose sentence conveying the same relationship, because `recap-core`'s documented fallback ships diagram blocks as plain text when the browser pane is unavailable.

The skill opts into `recap-core`'s 20-file diff-hunk budget for pull-request mode (the same opt-in `eng-recap` uses) because teaching how something works requires real signatures and error paths, which commit bodies do not carry. It records its URL under `teach-artifact-url:` and explicitly names the four sibling keys it is forbidden to write, preventing a fifth writer from clobbering a sibling's published page.

The anti-overlap guard in `tests/plugins/test-artifact-tools.sh` parses the heading list out of `teach-framing.md` and fails if it matches the section list in `commands/team-recap.md`. This is the build-level check that keeps a teaching page from quietly becoming a fourth recap: if the spines converge, the suite fails before the PR merges.

## How to use it

```bash
# Load the plugin locally
claude --plugin-dir ./kit/plugins/artifact-tools

# Publish a teaching page from the current session
# (skill auto-activates on "teach", "explain how this works", etc.)
> Publish a page teaching how this session's changes work

# Publish a teaching page from a pull request
> Teach me how PR #142 works
```

The skill reports the page URL after publishing. On a second run it republishes to the same `teach-artifact-url:` rather than minting a new link. `artifact-url:`, `eng-artifact-url:`, `team-artifact-url:`, and `product-artifact-url:` in the session record are never touched.

**Boundary with `social-media-tools:write-guide`**: `write-guide` produces long-form Markdown kept in the repository. `teach-artifact` produces a shareable claude.ai page. Both are now documented on both plugin READMEs.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |

<!-- generated:end -->

## References

- Plan: [add-teach-artifact-skill.md](plans/add-teach-artifact-skill.md)
- `kit/plugins/artifact-tools/references/teach-framing.md` — the fixed teaching spine
- `kit/plugins/artifact-tools/skills/teach-artifact/SKILL.md` — the skill
- `kit/plugins/artifact-tools/references/recap-core.md` — the shared engine this skill delegates to
- `tests/plugins/test-artifact-tools.sh` — the CI guard including the anti-overlap heading check
