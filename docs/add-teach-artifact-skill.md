# Ship teach-artifact, the artifact-tools Skill That Teaches Instead of Recaps

> Every existing way to share work in this kit either reports what changed or writes a Markdown file nobody links to. This fills the one empty slot — a shareable page whose job is understanding — and we will know it worked when the plugin's continuous-integration guard validates five skills instead of four and the version reaches 1.12.0.

<!-- generated:start -->

**Status:** Shipped 2026-08-19  **Plan:** [add-teach-artifact-skill.md](plans/add-teach-artifact-skill.md)
**Type:** feature

## What shipped

- Added `kit/plugins/artifact-tools/references/teach-framing.md`, a fixed teaching section spine used by both sources: mental model first, how it works today, one end-to-end path walked as an ordered list naming real file/function/command at each point, why it is built this way rather than the obvious alternative, and where to look next. The mental-model section earns a diagram by default (inverted from `recap-core`'s earned-diagram rule), and every diagram carries both a caption and a prose sentence conveying the same relationship (because `recap-core`'s fallback ships diagram blocks as plain text when the browser pane is unavailable).
- Added `kit/plugins/artifact-tools/skills/teach-artifact/SKILL.md` with the five declarations every writer in this plugin makes (audience, sections, favicon, inbox stem, republish key `teach-artifact-url:`), delegation to `recap-core` for source resolution and publishing, and an opt-in to the 20-file diff-hunk budget in pull-request mode.
- Extended `tests/plugins/test-artifact-tools.sh` to cover the fifth skill, added an assertion that `teach-framing.md`'s section headings do not match `team-recap`'s section list (the anti-overlap guard that catches a teaching page degrading into a second recap), and added the republish-key exclusivity assertion.
- Added `teach-artifact` to the `artifact-tools` README Features table and Usage block, with the one-line boundary statement distinguishing it from `social-media-tools:write-guide`. Added the reverse boundary statement and a 2.22.1 CHANGELOG entry to the `social-media-tools` plugin.
- Bumped artifact-tools to 1.12.0 and social-media-tools to 2.22.1 in marketplace.json.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/artifact-tools/references/teach-framing.md` | Reference — fixed teaching section spine, diagram rules, reviewer test, extension seam | Created |
| `kit/plugins/artifact-tools/skills/teach-artifact/SKILL.md` | Skill — five declarations, delegation to recap-core, 20-file budget opt-in | Created |
| `tests/plugins/test-artifact-tools.sh` | Test — extended for fifth skill, anti-overlap guard, key exclusivity | Modified |
| `kit/plugins/artifact-tools/README.md` | Plugin docs — Features row, Usage line, boundary statement | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | Changelog — 1.12.0 entry | Modified |
| `.claude-plugin/marketplace.json` | Marketplace — artifact-tools 1.12.0, social-media-tools 2.22.1 | Modified |
| `kit/plugins/social-media-tools/README.md` | Plugin docs — boundary statement from write-guide side | Modified |
| `kit/plugins/social-media-tools/CHANGELOG.md` | Changelog — 2.22.1 entry | Modified |

## How it works

The `artifact-tools` plugin separates its publishing engine from its framing: three recap commands (`eng-recap`, `team-recap`, `product-doc`) are short 60-68 line files whose real machinery lives in the shared `references/recap-core.md` (276 lines covering source resolution, the blocking secret-scanning gate, page-build rules, and republish record). Each command declares only five things: audience, section list, favicon, inbox stem, and republish key.

`teach-artifact` reuses `recap-core` unchanged and supplies a different frame. The frame is the only thing separating it from the three recap commands that read the same sources, so `teach-framing.md` gives it a file of its own that can be reviewed and argued with. The five-section spine is fixed for both sources (session and pull-request), because a fixed heading list is what makes the anti-overlap assertion executable: if the headings matched `team-recap`'s, the guard fails the build.

The skill opts into `recap-core`'s 20-file diff-hunk budget for pull-request mode (as `eng-recap` does and the other two deliberately do not), because teaching how something works needs the real function signatures and error paths that commit messages never carry. The mental-model section earns a diagram by default, inverting `recap-core`'s rule that a diagram is earned only where something changed — a page teaching a system that did not change this week is exactly the page most in need of one. Every diagram requires a prose sentence alongside its caption because `recap-core`'s plain-text fallback means content living only inside an image can disappear.

The republish key `teach-artifact-url:` is explicitly named in `SKILL.md` alongside a statement forbidding the four sibling keys (`artifact-url:`, `eng-artifact-url:`, `team-artifact-url:`, `product-artifact-url:`). All five writers share one record per session, so a fifth writer claiming a sibling's key would republish over that skill's page.

The CI guard in `test-artifact-tools.sh` previously hard-coded four skill names; without extending it, the fifth skill shipped with no test coverage while the suite still reported green. The anti-overlap assertion parses the heading list from `teach-framing.md` and fails if it matches `team-recap`'s section list — this turns the single largest risk (a teaching page that silently degrades into a second recap) into something the build catches.

Both plugin READMEs carry the boundary statement: artifact-tools says `teach-artifact` produces a shareable page (vs. `write-guide` producing long-form Markdown you keep in the repository), and social-media-tools points readers toward `teach-artifact` when they want a shareable page. The boundary only works if it is stated on both sides.

## How to use it

```bash
/artifact-tools:teach-artifact            # teaches from the current session
/artifact-tools:teach-artifact pr 42      # teaches from pull request #42
```

A second run on the same session or PR republishes to the same `teach-artifact-url:` URL. The resulting page is structured for a reader who wants to understand how the system works, not a summary of what changed.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `0fd7b67` | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |

<!-- generated:end -->

## References

- Plan: [add-teach-artifact-skill.md](plans/add-teach-artifact-skill.md)
