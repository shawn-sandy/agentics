# Add eng-recap command to artifact-tools

> Adds `/artifact-tools:eng-recap` for engineers, inverting team-recap's plain-language-first rule to lead with technical implementation details, diff stats, and file changes rather than product outcomes.

<!-- generated:start -->

**Status:** Shipped 2026-07-27 **Plan:** [add-eng-recap-command.md](plans/add-eng-recap-command.md)
**Type:** feature

## What shipped

- Created `kit/plugins/artifact-tools/skills/eng-recap/SKILL.md` with engineer-first section ordering.
- Added `eng-artifact-url:` frontmatter key for stable republishing (distinct from `team-artifact-url:` to avoid clobbering).
- Added a 20-file diff cap with `--name-only` fallback for large diffs.
- Bumped `artifact-tools` to 1.7.0 in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/skills/eng-recap/SKILL.md` | Eng recap skill | Created |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | Version history | Modified |

## How it works

`eng-recap` is designed for posting in engineering channels, PR descriptions, and technical design reviews. Unlike `team-recap` which opens with business impact, `eng-recap` leads with: the diff stat summary, key files changed, implementation decisions, and technical trade-offs — then optionally appends a brief product context for readers who need it.

The 20-file diff cap prevents runaway artifact sizes for large refactors. When a diff exceeds the cap, the skill falls back to `--name-only` output (filenames only, no content) to keep the artifact under the 16 MB limit while still conveying the scope of the change.

The `eng-artifact-url:` key records the published URL in the spec frontmatter — a separate key from `team-artifact-url:` — so eng-recap and team-recap can each maintain their own stable link when both are run on the same plan.

## How to use it

```
/artifact-tools:eng-recap
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [add-eng-recap-command.md](plans/add-eng-recap-command.md)
