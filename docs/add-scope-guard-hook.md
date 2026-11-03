# Add a scope-guard hook for repo-wide formatters and bare stash pops

> Ships `scope-guard.py`, a PreToolUse hook in git-agent that blocks repo-wide formatter runs (including those hidden behind npm scripts) and index-less `git stash pop` before they execute.

<!-- generated:start -->

**Status:** Shipped 2026-08-18 **Plan:** [add-scope-guard-hook.md](plans/add-scope-guard-hook.md)
**Type:** feature

## What shipped

- Created `kit/plugins/git-agent/hooks/scope-guard.py` — a PreToolUse hook that resolves npm/pnpm/yarn/bun script invocations before matching, blocks `--write`/`--fix` without a scoped path, and blocks bare `git stash pop`/`apply`
- Registered the hook as a second command in the existing `PreToolUse` Bash matcher in `kit/plugins/git-agent/hooks.json` with a short timeout
- Added `tests/plugins/test-scope-guard.sh` covering block/pass/fast-bail/script-resolution/opt-out cases
- Documented both rules, the `.claude/no-scope-guard` opt-out, the desktop-app caveat, and a `.claude/lint-gate.json` test-command example in the plugin README
- Bumped git-agent in `.claude-plugin/marketplace.json` and added the CHANGELOG entry

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/hooks/scope-guard.py` | PreToolUse guard — formatter and stash rules | Created |
| `kit/plugins/git-agent/hooks.json` | Second command in the existing Bash PreToolUse matcher | Modified |
| `kit/plugins/git-agent/README.md` | Both rules, opt-out, desktop caveat, lint-gate test-command example | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Version entry | Modified |
| `.claude-plugin/marketplace.json` | git-agent version bump | Modified |
| `tests/plugins/test-scope-guard.sh` | Block, pass, and fast-bail assertions | Created |

## How it works

The 2026-08-14 usage report recorded two high-cost incidents: `npm run fix:all` reformatted ~190 untouched files and needed a guarded revert; a bare `git stash pop` restored an unrelated stash and created conflicts. Both constraints existed in the user's personal `CLAUDE.md`, but a model rule can be weighed, not enforced. `scope-guard.py` is the enforcement layer.

The hook reads the PreToolUse JSON payload from stdin and exits 0 immediately for any non-Bash tool call, and for any Bash command whose raw text contains none of the trigger tokens (`--write`, `--fix`, `stash`, or a package-runner prefix). The fast-bail path is a correctness constraint, not just an optimization: the hook runs on every Bash call in every repo that installs git-agent, and it must never block a command that merely mentions a blocked pattern in a `git commit -m` message, an `echo`, or a `grep` argument. The first-token rule handles this: only a command whose first real token is a runner, formatter, or `git` is a candidate.

**Package-script resolution** is what makes the hook catch the actual incident. `npm run fix:all` carries none of the dangerous text itself — the hook must walk up from the payload's `cwd` to the git root, find the nearest `package.json` declaring the script, and match against the script's value. An optional `run` token is stripped before the script-name lookup so `yarn fix:all` and `yarn run fix:all` both resolve identically. Missing manifest, unreadable JSON, and absent script all resolve to the typed text and never block on their own.

**Rule 1 — Formatter scope**: block when the resolved command invokes `prettier`, `biome`, or `eslint` with `--write` or `--fix` and either no path operand or `.`/`./` as the operand. A command naming any other path (`prettier --write src/`, `eslint --fix kit/plugins/git-agent`) passes unconditionally. The intent is blast radius, not the tool.

**Rule 2 — Stash safety**: block `git stash pop` and `git stash apply` with no stash reference. The block message quotes `git stash list` as the first step because the safe form must be named explicitly — a block that only refuses is a block that gets disabled.

Both rules emit exit 2 with a stderr message naming the command, the rule, and the safe alternative. Exit 2 is the PreToolUse contract that returns the message to the model as actionable feedback. Creating `.claude/no-scope-guard` at the repo root disables both rules silently.

The hook is registered as a second command in the existing `PreToolUse` Bash matcher in `hooks.json`, with a short timeout that does not inherit `lint-before-commit.py`'s 480-second budget. Plugin `hooks.json` files are not registered in Claude Code desktop sessions (zero of 627 measured hook executions came from a plugin), so the `CLAUDE.md` rules remain the desktop fallback; the README documents this caveat explicitly.

## How to use it

The hook is active for any repo using git-agent via the claude.ai plugin system with Claude Code CLI (not desktop). No configuration is required.

To disable for a repo:

```bash
touch .claude/no-scope-guard
```

To run scoped formatter invocations that pass the guard:

```bash
prettier --write src/           # explicit path — passes
eslint --fix kit/plugins/git-agent  # explicit path — passes
git stash pop stash@{0}         # explicit reference — passes
```

To use the lint gate for tests (documented in the README as part of this change):

```json
// .claude/lint-gate.json
{"commands": ["npm run lint", "npm test"]}
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |

<!-- generated:end -->

## References

- Plan: [add-scope-guard-hook.md](plans/add-scope-guard-hook.md)
- `kit/plugins/git-agent/hooks/scope-guard.py` — the hook
- `kit/plugins/git-agent/hooks/lint-before-commit.py` — the fast-bail pattern, manifest walk, and opt-out convention reused here
- `tests/plugins/test-scope-guard.sh` — block, pass, and fast-bail tests
