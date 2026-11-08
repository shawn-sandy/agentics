# Refactor commit-agent to push without asking

> Replace commit-agent's push/don't-push prompt with an automatic push that guards the default branch and always names the branch explicitly, while every delegated caller remains unchanged.

<!-- generated:start -->

**Status:** Shipped 2026-10-08  **Plan:** [refactor-commit-agent-auto-push.md](plans/refactor-commit-agent-auto-push.md)
**Type:** refactor

## What shipped

- Wrote `tests/plugins/test-commit-agent-auto-push.sh` first (red-green: confirms prompt is gone and guards exist).
- Replaced Steps 5–6 in `kit/plugins/git-agent/skills/commit-agent/SKILL.md` with one Step 5 that reads the default branch live via `git ls-remote --symref origin HEAD` (plus `main` and `master` as fallbacks), stops if it cannot be read, and runs `git push -u origin <current-branch>` without asking.
- Marked every `Invoke ... commit-agent` call site as delegated in `tdd-loop` Steps 3 and 6, `tdd-fix` Step 7, and `references/handoff.md`.
- Updated `kit/plugins/git-agent/README.md`, `docs/guides/how-to/git-agent.md`, the `agent-commit` README rationale, and `ship-autonomous/references/pr-events.md` to remove references to the removed prompt.
- Bumped `git-agent` to `4.23.0` and `code-testing-agent` to `3.6.1` in `.claude-plugin/marketplace.json`; regenerated the root README table.

> See [CHANGELOG v4.23.0](../kit/plugins/git-agent/CHANGELOG.md) for the authoritative feature list.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/commit-agent/SKILL.md` | Commit skill — push prompt replaced with auto-push + default-branch guard | Modified |
| `tests/plugins/test-commit-agent-auto-push.sh` | Objective-verification test | Created |

## How it works

`commit-agent` Step 6 added a `Push / Don't push` prompt in git-agent 4.10.0. After every direct-invocation commit, the skill paused and waited for user input. The developer wanted the push to happen automatically.

The push prompt was the only gate on the push, so its replacement had to include a default-branch guard. A branch cut with `git checkout -b <branch> origin/main` tracks `origin/main`, meaning `git push` without an explicit branch name (which the old Step 5 `@{u}` probe could pick) would fail or land on the base branch. The fix reads the default branch live via `git ls-remote --symref origin HEAD` at push time, falls back to checking `main` and `master`, and stops with an informational message if the default branch cannot be determined. The push always uses `git push -u origin <current-branch>` — never bare, never forced.

Delegated call sites needed marking because those callers must not push. `tdd-loop` Steps 3 and 6, `tdd-fix` Step 7, and `references/handoff.md` were each updated with a "delegating — do not push" note. Without these markers, an auto-push would push a failing-test commit during a tdd-loop cycle.

`tests/plugins/test-commit-agent-auto-push.sh` asserts seven properties: the push step follows the commit, the skill does not ask, there is no `AskUserQuestion` call, the push uses `git push -u origin <current-branch>` (never bare), the default branch is guarded live (not via cached `origin/HEAD`), the skill stops when the default branch is unknown, and every `Invoke ... commit-agent` line in any plugin says it is delegating.

## How to use it

Direct invocation (`/git-agent:commit-agent`) now commits and pushes automatically with no prompt.

The push will not proceed when the current branch is the default branch — the commit happens but the skill reports that the push was skipped. On a tracking branch, the push always uses the branch's own name rather than following any configured upstream.

Skills that call `commit-agent` as a sub-step (tdd-loop, tdd-fix) are unaffected — the delegated marker tells them the push stop is handled by their own step.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |
| `9277c9f` | 2026-09-18 | feat(git-agent): commit and ship paths handle lint-gate blocks (4.21.0) (#635) |
| `052d88c` | 2026-10-08 | refactor(git-agent): commit-agent pushes without asking (4.23.0) (#646) |
| `8a8a392` | 2026-10-31 | fix(git-agent): remove model pins from skills (4.25.0) (#667) |

<!-- generated:end -->

## References

- Plan: [refactor-commit-agent-auto-push.md](plans/refactor-commit-agent-auto-push.md)
