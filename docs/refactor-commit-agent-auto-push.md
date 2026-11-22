# Refactor commit-agent to push without asking

> commit-agent asked "Push / Don't push" via AskUserQuestion after every direct-invocation commit. This removes the prompt and makes commit-agent push automatically, always to the branch's own name, with a default-branch guard.

<!-- generated:start -->

**Status:** Shipped 2026-10-08 **Plan:** [refactor-commit-agent-auto-push.md](plans/refactor-commit-agent-auto-push.md)
**Type:** refactor

## What shipped

- Updated `kit/plugins/git-agent/skills/commit-agent/SKILL.md` Steps 5–6: replaced the `AskUserQuestion` push prompt with one Step 5 that reads the default branch live via `git ls-remote --symref origin HEAD` (plus `main` and `master` as fallbacks), stops if it cannot be read, and runs `git push -u origin <current-branch>` for any non-default branch.
- Marked every `Invoke ... commit-agent` call site in tdd-loop, tdd-fix, and `references/handoff.md` as delegated so those callers still stop before the push.
- Updated `kit/plugins/git-agent/README.md`, `docs/guides/how-to/git-agent.md`, the `agent-commit` README rationale, and `ship-autonomous/references/pr-events.md` to remove references to the removed prompt.
- Added `tests/plugins/test-commit-agent-auto-push.sh`: seven mutant-tested assertions covering prompt removal, default-branch guard, branch-name push, delegation stop, and no force/reconcile.
- Bumped git-agent to 4.23.0 and code-testing-agent to 3.6.1 (for the tdd-loop caller mark); regenerated the root README table.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/commit-agent/SKILL.md` | Auto-push + default-branch guard | Modified |
| `kit/plugins/git-agent/skills/tdd-loop/SKILL.md` | Delegated caller mark | Modified |
| `kit/plugins/git-agent/skills/tdd-fix/SKILL.md` | Delegated caller mark | Modified |
| `kit/plugins/git-agent/skills/tdd-fix/references/handoff.md` | Delegated caller mark | Modified |
| `kit/plugins/git-agent/README.md` | Removed prompt references | Modified |
| `docs/guides/how-to/git-agent.md` | Removed prompt references | Modified |
| `kit/plugins/git-agent/skills/ship-autonomous/references/pr-events.md` | Removed prompt references | Modified |
| `tests/plugins/test-commit-agent-auto-push.sh` | Auto-push assertions | Created |
| `kit/plugins/git-agent/CHANGELOG.md` | 4.23.0 entry | Modified |
| `kit/plugins/code-testing-agent/CHANGELOG.md` | 3.6.1 entry | Modified |
| `.claude-plugin/marketplace.json` | git-agent 4.23.0, code-testing-agent 3.6.1 | Modified |
| `README.md` | Regenerated plugin table | Modified |

## How it works

**Push-without-asking**: The `AskUserQuestion` gate is removed. After a successful commit, the skill runs `git push -u origin <current-branch>` unconditionally.

**Default-branch guard**: The skill reads the actual default branch name live from `git ls-remote --symref origin HEAD` rather than caching `origin/HEAD`, which could point at the base branch for a branch cut with `git checkout -b <branch> origin/main`. On the default branch, the commit stays local and the skill reports why it did not push.

**Delegated callers**: Skills that invoke commit-agent as a sub-step (tdd-loop, tdd-fix) are marked as delegated. The delegated path still stops before the push, so a tdd-loop's failing-test commit does not get pushed automatically.

**Failed push**: A push failure is reported verbatim. The skill never retries, forces, or reconciles — the user resolves it manually.

## How to use it

```
/git-agent:commit-agent
```

The commit is made and pushed with no prompt. To stop before the push (e.g. when calling from another skill), mark the invocation as delegated.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| — | 2026-10-08 | refactor(git-agent): commit-agent auto-push — no prompt, default-branch guard, delegated callers (4.23.0) |

<!-- generated:end -->

## References

- Plan: [refactor-commit-agent-auto-push.md](plans/refactor-commit-agent-auto-push.md)
