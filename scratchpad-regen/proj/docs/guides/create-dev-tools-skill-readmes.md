# Add Detailed READMEs for Each Skill in dev-tools

> Creates individual README files for each of the three skills in `dev-tools` (`code-review`, `claude-md-optimizer`, `plan-interview`) and updates the plugin-level README to document all three.

<!-- generated:start -->

**Status:** Shipped 2026-02-23   **Plan:** [create-dev-tools-skill-readmes.md](plans/create-dev-tools-skill-readmes.md)   **Type:** artifact

## What shipped

Note: The `dev-tools` plugin was later refactored out (see `refactor-dev-tools-extract-standalone-plugins`). This plan documents work completed prior to that refactor.

- `plugins/dev-tools/skills/code-review/README.md` — activation triggers, 4 review dimensions, output format, scope, tips.
- `plugins/dev-tools/skills/claude-md-optimizer/README.md` — CLAUDE.md file resolution, 6-dimension scoring, grading scale, output format, opt-in actions, tips.
- `plugins/dev-tools/skills/plan-interview/README.md` — plan file resolution, interview rounds table, scope triggers, output format, opt-in, tips.
- `plugins/dev-tools/README.md` updated to add `claude-md-optimizer` and `plan-interview` to the Features list, Plugin Structure tree, and Components section.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `plugins/dev-tools/skills/code-review/README.md` | Skill-level README | Created |
| `plugins/dev-tools/skills/claude-md-optimizer/README.md` | Skill-level README | Created |
| `plugins/dev-tools/skills/plan-interview/README.md` | Skill-level README | Created |
| `plugins/dev-tools/README.md` | Plugin-level README | Modified |

## How it works

Each skill README documented the activation pattern (natural language triggers), what the skill does, its output format, and scope boundaries. The plugin-level README was also missing two of its three skills entirely — they were added to the Features list, the Plugin Structure directory tree, and the Components section to make the plugin self-documenting.

These READMEs became the basis for the standalone plugin READMEs when the dev-tools skills were extracted in a later refactor.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `6b9fab3` | 2026-03-26 | Merge pull request #51 from shawn-sandy/docs/plan-interview-upgrade |
| `9c70a52` | 2026-03-30 | chore(docs/plans): add YAML frontmatter status to 83 plan files |

<!-- generated:end -->

## References

- Plan: [create-dev-tools-skill-readmes.md](plans/create-dev-tools-skill-readmes.md)
- Related: [refactor-dev-tools-extract-standalone-plugins.md](plans/refactor-dev-tools-extract-standalone-plugins.md)
