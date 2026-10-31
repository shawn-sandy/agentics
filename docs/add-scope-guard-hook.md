# Add a Scope-Guard Hook for Repo-Wide Formatters and Bare Stash Pops

> One `npm run fix:all` reformatted about 190 untouched files and needed a guarded revert; one bare `git stash pop` restored an unrelated stash and created conflicts. Both are prevented by a rule that lives only in a personal CLAUDE.md. This ships the rule as a PreToolUse hook in git-agent — resolving npm scripts so `fix:all` is actually caught — and documents the existing lint gate's config as a test gate.

<!-- generated:start -->

**Status:** Shipped 2026-08-19  **Plan:** [add-scope-guard-hook.md](plans/add-scope-guard-hook.md)
**Type:** feature

## What shipped

- Added `kit/plugins/git-agent/hooks/scope-guard.py`, a `PreToolUse` hook that blocks repo-wide formatter runs and index-less `git stash pop` before execution, with package-script resolution against the nearest `package.json` manifest so `npm run fix:all` (whose script expands to `prettier --write .`) is actually caught.
- Registered the hook as a second command in the existing `PreToolUse` `Bash` matcher in `hooks.json`, leaving `lint-before-commit.py` and its 480s budget unchanged.
- Added a `.claude/no-scope-guard` opt-out at the repo root, mirroring the `.claude/no-lint-gate` convention.
- Added `tests/plugins/test-scope-guard.sh` covering both blocked patterns, passing counterparts, script resolution, the opt-out, non-Bash payloads, and non-executing mentions.
- Updated the `README.md` with both rules, both escape hatches, the desktop-app caveat, and a `.claude/lint-gate.json` test-command example.
- Bumped git-agent from 4.18.0 (or 4.17.0) to the appropriate version and added a CHANGELOG entry.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/git-agent/hooks/scope-guard.py` | Hook — PreToolUse guard for formatters and stash pops | Created |
| `kit/plugins/git-agent/hooks.json` | Hook manifest — second command in existing Bash matcher | Modified |
| `kit/plugins/git-agent/README.md` | Plugin docs — guard rules, opt-out, desktop caveat, lint-gate test example | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Changelog — version entry | Modified |
| `.claude-plugin/marketplace.json` | Marketplace — git-agent version bump | Modified |
| `tests/plugins/test-scope-guard.sh` | Test — block, pass, and fast-bail assertions | Created |

## How it works

The hook begins with three cheap bail conditions that cover the vast majority of Bash calls: a non-Bash tool payload, a command whose text contains none of the trigger tokens (`--write`, `--fix`, `stash`, or a package-runner prefix), and a command whose first token is not itself a runner, formatter, or `git`. These bails open no files and exit 0 immediately. The first-token rule is what prevents a `git commit -m "...fix:all..."` message from being refused — only an actual invocation triggers the checks.

Package-script resolution is the critical capability that was missing from the existing user-level hook. For a command whose first token is `npm`, `pnpm`, `yarn`, or `bun`, the hook strips an optional `run` token and treats the next token as the script name, then walks up from the payload's cwd to the git root, reads the first manifest declaring that script, and matches against the script's value rather than the typed command. All eight spellings of the same invocation (`npm run fix:all`, `npm fix:all`, `pnpm run fix:all`, etc.) resolve identically. A missing manifest, unreadable JSON, or absent script resolves to the typed text and never blocks on its own.

The formatter rule blocks when the resolved command invokes a formatter or linter with `--write` or `--fix` and either no path operand or `.` as the operand. An explicit path argument — `prettier --write src/`, `eslint --fix kit/plugins/git-agent` — passes without restriction, because the constraint is blast radius, not the tool. Formatting only the files you touched must stay frictionless or the guard gets switched off.

The stash rule blocks `git stash pop` and `git stash apply` with no stash reference. The block message quotes `git stash list` as the first step, because the remediation is a listing rather than abstinence, and a guard whose message says nothing the user can act on gets removed. An explicit `stash@{N}` or numeric index passes.

Blocks exit 2 with the rule and safe alternative on stderr — the PreToolUse contract that returns the message to the model as actionable feedback. The `.claude/no-scope-guard` opt-out at the repo root disables every rule silently, matching `.claude/no-lint-gate` so a user who knows one escape hatch knows both.

The desktop-app caveat is documented in the README: plugin `hooks.json` files are not registered in Claude Code desktop sessions (measured across 627 hook executions, where zero came from any plugin). The guard is CLI-only enforcement, and the personal `CLAUDE.md` rules remain the desktop fallback.

## How to use it

The hook fires automatically when the git-agent plugin is loaded in a CLI session. To opt out in a specific repo:

```bash
touch .claude/no-scope-guard
```

To enable test commands in the lint gate, add to `.claude/lint-gate.json`:

```json
{"commands": ["npm run lint", "npm test"]}
```

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `0fd7b67` | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |

<!-- generated:end -->

## References

- Plan: [add-scope-guard-hook.md](plans/add-scope-guard-hook.md)
