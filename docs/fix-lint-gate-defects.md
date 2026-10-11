# Fix lint gate defects in git-agent

> Fixes four confirmed defects in the lint gate: nearest-package resolution, Python/Go/Rust ecosystem support, baseline comparison, and plugin hook registration — including a critical fix where hooks never registered due to a missing key in plugin.json.

<!-- generated:start -->

**Status:** Shipped 2026-08-10 **Plan:** [fix-lint-gate-defects.md](plans/fix-lint-gate-defects.md)
**Type:** fix

## What shipped

- Fixed nearest-package resolution (walk up the tree to find the closest `package.json`).
- Added lint support for Python (ruff/pylint), Go (golangci-lint), and Rust (clippy) ecosystems.
- Fixed baseline comparison to compare against the default branch, not the current commit's parent.
- Fixed hook registration: added `"hooks": "./hooks.json"` to `git-agent/plugin.json` (hooks had never registered before this fix).
- Bumped git-agent to 4.14.0 in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/ship/references/` | Ship references | Modified |
| `kit/plugins/git-agent/plugin.json` | Plugin manifest | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Version history | Modified |

## How it works

The hook registration fix was the most impactful: `plugin.json` was missing the `"hooks": "./hooks.json"` key. Without this key, Claude Code's plugin loader never registers the hooks file, so every hook in `hooks.json` was silently ignored — the `UserPromptSubmit` hook for "merge?", the PostToolUse hook for prototype drift checking, etc. Adding the key restores all hook functionality immediately.

The nearest-package fix addresses monorepo structures where a file in `apps/web/src/components/Button.tsx` should be linted with `apps/web/package.json`'s scripts, not the root's. The new resolution walks up the directory tree from the changed file until it finds a `package.json` with a `lint` script, then runs that.

The baseline comparison fix changes from "compare against parent commit" to "compare against `origin/main`". The old approach meant a 10-commit feature branch would only baseline the most recent commit's changes; the new approach correctly compares the entire branch against the default branch.

The same hook registration issue also affects `plan-agent` and `skill-reviewer` — their `plugin.json` files require the same `"hooks"` key addition.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [fix-lint-gate-defects.md](plans/fix-lint-gate-defects.md)
