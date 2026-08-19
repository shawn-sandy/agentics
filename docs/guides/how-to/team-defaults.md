# How do I... team-defaults

Installs the team's shared global rule files so every project on your machine picks them up.

Install: `/plugin install team-defaults@agentics-kit`

## sync-rules

Copies the rule files bundled with this plugin into `~/.claude/rules/`.

- **Command** — `/team-defaults:sync-rules`
- **Say it instead** — "sync the team rules to my machine"
- **What happens** — Diffs each bundled rule (`plan-mode.md`, `reference/SKELETON.md`, `component-driven-ui.md`, `typescript-jsdoc.md`, `review-bot-loops.md`) against `~/.claude/rules/`, prints a new / up-to-date / conflict table, and asks per conflicting file before overwriting. Copies the approved files, then re-diffs to verify each one.
- **Watch out** — `plan-mode.md` references the `validate-plan-filename` hook, which ships with `plan-agent`, not this plugin. Rules the plugin does not ship are never touched, and copied rules load on the next session with no restart.
