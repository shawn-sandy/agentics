# Code Review: fix/agent-name branch

> Renames the code-review plugin agent from `code-reviewer` to `agent-code-reviewer` (v2.3.0 → v3.0.0) to avoid conflict with a built-in agent name.

<!-- generated:start -->

**Status:** Shipped 2026-03-08   **Plan:** [code-review-fix-agent-name.md](plans/code-review-fix-agent-name.md)   **Type:** standard

## What shipped

- `kit/plugins/code-review/agents/code-reviewer.md` renamed to `agent-code-reviewer.md` via `git mv` (history preserved).
- `name:` frontmatter in the agent file updated to `agent-code-reviewer`.
- `plugin.json`, `marketplace.json`, `CHANGELOG.md`, and `README.md` updated consistently.
- `code-review` plugin bumped from `2.3.0` → `3.0.0` (MAJOR — breaking rename).
- CHANGELOG entry includes `BREAKING CHANGE:` label and migration path.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/code-review/agents/agent-code-reviewer.md` | Agent definition (renamed from code-reviewer.md) | Modified |
| `kit/plugins/code-review/.claude-plugin/plugin.json` | Plugin manifest — version bump 2.3.0 → 3.0.0 | Modified |
| `kit/plugins/code-review/CHANGELOG.md` | Plugin changelog — BREAKING CHANGE entry | Modified |
| `kit/plugins/code-review/README.md` | Plugin documentation — name and memory path | Modified |
| `.claude-plugin/marketplace.json` | Marketplace registry — version bump 2.3.0 → 3.0.0 | Modified |

## How it works

The agent name `code-reviewer` conflicted with a built-in Claude Code agent identifier. The rename to `agent-code-reviewer` follows the project convention of prefixing agent files with `agent-` when the name collides.

The rename is a MAJOR version bump because any workflow that delegates to `agent-code-reviewer` by name (using `subagent_type: "code-reviewer"`) will break. The migration path is: update references to use `subagent_type: "agent-code-reviewer"` and reinstall the plugin from the marketplace.

Defense-in-depth safety constraints were preserved unchanged: `permissionMode`, `disallowedTools`, and `maxTurns` settings on the agent remain intact.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `6b9fab3` | 2026-03-26 | Merge pull request #51 from shawn-sandy/docs/plan-interview-upgrade |
| `9c70a52` | 2026-03-30 | chore(docs/plans): add YAML frontmatter status to 83 plan files |
| `e15fba2` | 2026-04-04 | refactor: rename agentics/ marketplace subtree to kit/ |

<!-- generated:end -->

## References

- Plan: [code-review-fix-agent-name.md](plans/code-review-fix-agent-name.md)
