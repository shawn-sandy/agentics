# Remove dead plugin directories and fix description budgets

> Deletes the six source trees for de-registered plugins, migrates the one command that referenced them, trims eight over-budget SKILL.md descriptions to fit the 200-character limit, and adds two tests that keep the repo clean going forward.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [remove-dead-plugins-and-fix-frontmatter](plans/remove-dead-plugins-and-fix-frontmatter.md)
**Type:** chore

## What shipped

- Deleted six de-registered plugin source directories: `kit/plugins/agent-creator/`, `kit/plugins/agent-reviewer/`, `kit/plugins/agentic-plugin-dev/`, `kit/plugins/code-simplifier/`, `kit/plugins/marketplace-builder/`, `kit/plugins/react-perf-analyzer/`
- Migrated `kit/plugins/code-review/commands/fix-branch.md` from `agent-reviewer` delegation to `skill-reviewer` delegation
- Ran `skill-reviewer:optimizing-skill-frontmatter` over eight over-budget `SKILL.md` files to trim `description:` values to ≤200 characters
- Created `tests/plugins/test-no-orphan-plugin-dirs.sh`: fails if any `kit/plugins/` directory exists that is not registered in `marketplace.json`
- Created `tests/plugins/test-description-budget.sh`: fails if any `SKILL.md` `description:` value exceeds 200 characters
- Corrected the `CLAUDE.local.md` loader to read from the plugin manifest rather than using `ls` on the directory

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/agent-creator/` | Dead plugin source | Deleted |
| `kit/plugins/agent-reviewer/` | Dead plugin source | Deleted |
| `kit/plugins/agentic-plugin-dev/` | Dead plugin source | Deleted |
| `kit/plugins/code-simplifier/` | Dead plugin source | Deleted |
| `kit/plugins/marketplace-builder/` | Dead plugin source | Deleted |
| `kit/plugins/react-perf-analyzer/` | Dead plugin source | Deleted |
| `kit/plugins/code-review/commands/fix-branch.md` | Command — updated delegation target | Modified |
| `tests/plugins/test-no-orphan-plugin-dirs.sh` | Smoke test — orphan detection | Created |
| `tests/plugins/test-description-budget.sh` | Smoke test — description length | Created |

## How it works

The six directories were already de-registered from `marketplace.json` and listed in `.claude/rules/removed-plugins.md` as deliberate removals. Their source trees had been left on disk, creating a mismatch between the marketplace registry and the filesystem — `kit/plugins/` contained directories with no corresponding marketplace entry. That mismatch is what `test-no-orphan-plugin-dirs.sh` now detects: it diffs the set of `kit/plugins/*/plugin.json` paths against the set of paths referenced in `marketplace.json` and fails if any directory exists that the registry does not list.

`fix-branch.md` in `code-review` was the only command across all active plugins that still delegated to `agent-reviewer`. The migration to `skill-reviewer` keeps the command functional while removing the last runtime reference to the deleted plugin.

The description-budget fix targets the Claude Code UI: descriptions longer than 200 characters are truncated in the command picker, cutting off the end of the description. `skill-reviewer:optimizing-skill-frontmatter` trims each over-budget value to the most informative 200-character prefix, preserving the action verb and main object. `test-description-budget.sh` shells out to `yq` to extract each `description:` value and counts characters, failing immediately on the first over-budget file.

The `CLAUDE.local.md` loader had been using `ls kit/plugins/` to enumerate plugins, which returned every directory including the now-deleted dead ones. Switching to the manifest read (`jq` over `marketplace.json`) ensures the loader sees only registered plugins and is robust to any future de-registrations that don't immediately delete the source.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [remove-dead-plugins-and-fix-frontmatter](plans/remove-dead-plugins-and-fix-frontmatter.md)
