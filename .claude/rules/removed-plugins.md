# Removed Plugins — Do Not Re-Add

Always loaded (no `paths` scope) so the confirmation gate is present the moment a
user asks to re-add a removed plugin, before any plugin file is opened. The rest
of the marketplace mechanics live in the path-scoped `marketplace.md`.

The following plugins were deliberately removed from the marketplace. Do not re-register them unless the removal reason is explicitly resolved and the user approves.

| Plugin | Removed | Reason |
|--------|---------|--------|
| `agent-creator` | 2026-05-29 | Redundant with `agentic-plugin-dev` |
| `agent-reviewer` | 2026-05-29 | Overlaps with `skill-reviewer` |
| `marketplace-builder` | 2026-05-29 | Redundant with `agentic-plugin-dev` |
| `react-perf-analyzer` | 2026-05-29 | Too specialized; `code-review` covers general perf |
| `agentic-plugin-dev` | 2026-05-29 | Removed from marketplace; source deleted 2026-07-16, recoverable from git history |
| `code-simplifier` | 2026-05-29 | Removed from marketplace; structural analysis covered by `code-review`; source deleted 2026-07-16, recoverable from git history |
| `plan-interview` | 2026-07-17 | Merged into `plan-agent` 4.0.0 (documenting-plans, markdown-to-html, plan-status, plan-maintenance, deep-grill, and the ExitPlanMode nudge carried over); source recoverable from git history |

If a user asks to add any of these back, flag the removal reason and ask for explicit confirmation before proceeding.
