# Add teach-artifact skill to artifact-tools

> Adds a fifth artifact-tools skill that turns a technical topic into a structured teaching artifact with fixed-spine sections, diagrams with captions, and a mental-model section — with an overlap guard to prevent duplicating team-recap content.

<!-- generated:start -->

**Status:** Shipped 2026-08-07 **Plan:** [add-teach-artifact-skill.md](plans/add-teach-artifact-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/artifact-tools/skills/teach-artifact/SKILL.md` as the fifth artifact-tools skill.
- Fixed teaching section spine (Why → What → How → Worked Example → Common Mistakes).
- Delegates to `recap-core.md` for the shared generation and publish workflow.
- Uses `teach-artifact-url:` as the republish key.
- Every mental-model section earns a diagram by default; every diagram must have a caption and a prose sentence.
- Added an overlap guard: `teach-artifact` sections must not match `team-recap` sections.
- Bumped `artifact-tools` to 1.12.0, `social-media-tools` to 2.22.1.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/skills/teach-artifact/SKILL.md` | Teach skill | Created |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | Version history | Modified |

## How it works

`teach-artifact` generates a standalone teaching page from a technical topic description. The spine is fixed because teaching pages that work share a common structure: starting with Why (motivation), then What (definition), then How (mechanism), then a Worked Example (concrete application), then Common Mistakes (what goes wrong).

The mental-model section triggers a diagram by default because mental models are inherently spatial — a text-only mental model description is harder to retain than a labeled diagram. The requirement for a caption and a prose sentence ensures the diagram is integrated into the text, not just decorative.

The overlap guard prevents `teach-artifact` from accidentally generating content that duplicates a `team-recap` artifact on the same topic. The two skill types serve different audiences (learners vs. stakeholders) and different purposes (teaching vs. status reporting), and overlap confuses both.

## How to use it

```
/artifact-tools:teach-artifact <topic description>
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [add-teach-artifact-skill.md](plans/add-teach-artifact-skill.md)
