# Ship teach-artifact, the artifact-tools skill that teaches instead of recaps

> Adds a fifth skill, `teach-artifact`, to the `artifact-tools` plugin — reads the current session or a PR and publishes a claude.ai page that teaches a reader how the system works, not what changed.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [add-teach-artifact-skill](plans/add-teach-artifact-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/artifact-tools/skills/teach-artifact/SKILL.md` — reads session or PR, produces a teaching-oriented HTML artifact
- Teaching structure: Concept map, How it works (mechanism-first), Walk through an example, When to use it, Pitfalls and gotchas
- Uses the same `session-artifact` pipeline for transcript extraction and scrub gate
- Declares `teach-artifact-url:` republish key with a never-write warning naming all four sibling keys
- Bumped `artifact-tools` with CHANGELOG entry, README update, and `test-artifact-tools.sh` extension

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/skills/teach-artifact/SKILL.md` | Skill — teaching artifact framing | Created |
| `tests/plugins/test-artifact-tools.sh` | Smoke test — key map, section assertions | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry — artifact-tools bump | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | Release history | Modified |
| `kit/plugins/artifact-tools/README.md` | Plugin docs | Modified |

## How it works

The four existing `artifact-tools` commands — `product-doc`, `team-recap`, `eng-recap`, and `diff-artifact` — all describe what changed. None explains how the system now works to a reader who wasn't in the session. `teach-artifact` addresses this by publishing a different kind of document: one that teaches the mechanism to a reader who needs to understand and use what was built.

The skill reads the same sources: the current session transcript via `session-artifact`, or a PR via `gh pr diff` and `gh pr view`. But instead of a recap structure (what happened, who did what), it produces a teaching structure: a concept map showing the key entities and their relationships, a mechanism-first explanation of how the system works, a concrete walkthrough of a representative example, and a pitfalls section capturing the non-obvious failure modes.

Like its siblings, `teach-artifact` reuses the `session-artifact` pipeline for transcript extraction and the scrub gate before publishing. It declares its own `teach-artifact-url:` key in the shared session record to prevent republishing over a sibling's live page.

## How to use it

```
/artifact-tools:teach-artifact           # teach from the current session
/artifact-tools:teach-artifact #42       # teach from a specific PR
```

Activation: the skill is auto-activated when the user asks to explain, teach, or document how something works.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [add-teach-artifact-skill](plans/add-teach-artifact-skill.md)
