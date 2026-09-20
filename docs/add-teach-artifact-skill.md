# Ship teach-artifact, the artifact-tools skill that teaches instead of recaps

> Every existing way to share work in this kit either reports what changed or writes a Markdown file nobody links to. This fills the one empty slot — a shareab...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-teach-artifact-skill.md](plans/add-teach-artifact-skill.md)
**Type:** feature

## What shipped

- Write the teaching-frame reference at kit/plugins/artifact-tools/references/teach-framing.md, giving it one fixed sec...
- Create kit/plugins/artifact-tools/skills/teach-artifact/SKILL.md carrying the name and description frontmatter, the p...
- Extend tests/plugins/test-artifact-tools.sh to cover the new skill: add `teach-artifact` to the loop that validates s...
- Update kit/plugins/artifact-tools/README.md with a teach-artifact row in the Features table, a matching line in the U...
- Add the CHANGELOG entry for 1.12.0 in kit/plugins/artifact-tools/CHANGELOG.md describing the new skill, and raise the...
- Add the same one-line boundary statement to kit/plugins/social-media-tools/README.md pointing readers from write-guid...

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/references/teach-framing.md` | the fixed teaching section spine, the diagram and walkthr... | Created |
| `kit/plugins/artifact-tools/skills/teach-artifact/SKILL.md` | the skill, its five declarations, and its delegation to r... | Created |
| `tests/plugins/test-artifact-tools.sh` | extend both validation loops to cover a fifth skill and a... | Modified |
| `kit/plugins/artifact-tools/README.md` | Features row, Usage line, and the boundary statement | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | the 1.12.0 entry | Modified |
| `.claude-plugin/marketplace.json` | artifact-tools to 1.12.0 and social-media-tools to 2.22.1 | Modified |
| `kit/plugins/social-media-tools/README.md` | the other half of the boundary statement | Modified |
| `kit/plugins/social-media-tools/CHANGELOG.md` | the 2.22.1 entry the version bump requires | Modified |

## How it works

Add a fifth skill, `teach-artifact`, to the `artifact-tools` plugin. It reads the same two sources the existing recap commands already read — the current working session, or a pull request — and publishes a claude.ai page that teaches a reader how the system works, rather than reporting what changed.

The `artifact-tools` plugin already separates its publishing engine from its framing. The three recap commands (`eng-recap`, `team-recap`, `product-doc`) are short files of 60 to 68 lines each; all the real machinery lives in one shared 276-line reference, `references/recap-core.md`, which owns source resolution, the blocking secret-scanning gate, the page-build rules, and the record that lets a re-run republish to the same link. Each command declares only five things: its audience, its section ...

The implementation proceeded through these steps: Write the teaching-frame reference at kit/plugins/artifact-tools/references/teach-framing.md, giving it one fixed sec...; Create kit/plugins/artifact-tools/skills/teach-artifact/SKILL.md carrying the name and description frontmatter, the p...; Extend tests/plugins/test-artifact-tools.sh to cover the new skill: add `teach-artifact` to the loop that validates s...; Update kit/plugins/artifact-tools/README.md with a teach-artifact row in the Features table, a matching line in the U...; Add the CHANGELOG entry for 1.12.0 in kit/plugins/artifact-tools/CHANGELOG.md describing the new skill, and raise the....

- Verification paragraphs 1 and 2 (`claude --plugin-dir ./kit/plugins/artifact-tools`, publish a teaching page, then republish and diff the session record) — verified structurally, not by a live run. This session is non-interactive and a real publish is an outward-facing action, so the three behavio

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates ( |

<!-- generated:end -->

## References

- Plan: [add-teach-artifact-skill.md](plans/add-teach-artifact-skill.md)
- Issue: https://github.com/shawn-sandy/agentics/issues/534
