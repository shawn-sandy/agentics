---
status: completed
type: refactor
created: 2026-10-08
modified: 2026-10-08
repo-name: agentics
---

# Refactor commit-agent to push without asking

## Context

`commit-agent` Step 6 asked "Push / Don't push" via `AskUserQuestion` after every
direct-invocation commit (added in git-agent 4.10.0). The developer wants the
push to happen automatically. That prompt was the only gate on the push, so its
replacement must guard the default branch and must not trust the Step 5 `@{u}`
probe: a branch cut with `git checkout -b <branch> origin/main` tracks
`origin/main`, so the bare `git push` the probe picked fails or lands on the
base branch.

## Objective

A direct `/git-agent:commit-agent` run commits and pushes with no prompt,
always to the branch's own name, never to the default branch, and every skill
that calls commit-agent as a sub-step still stops before the push.

## Steps

1. Write `tests/plugins/test-commit-agent-auto-push.sh` and watch it fail against the current skill. Why: the regression test must prove the prompt is gone and the guards exist. Verify: the test exits 1 with failing push-step checks.
2. Replace Steps 5–6 in `kit/plugins/git-agent/skills/commit-agent/SKILL.md` with one Step 5 that skips the default branch (`refs/remotes/origin/HEAD`, `main`, `master`) and otherwise runs `git push -u origin <current-branch>`. Why: the push must run without asking, never follow an upstream that points at the base, and never land on the default branch. Verify: the test passes and seven mutants (renamed Step 4, prose ask, inverted guard, guard after push, bare push, asking description, dropped origin/HEAD) each fail it.
3. Mark every `Invoke ... commit-agent` call site as delegated: tdd-loop Steps 3 and 6, tdd-fix Step 7 and `references/handoff.md`. Why: an undelegated call now pushes, which would push tdd-loop's failing-test commit. Verify: the test's caller check passes.
4. Update `kit/plugins/git-agent/README.md`, `docs/guides/how-to/git-agent.md`, the `agent-commit` README rationale, and ship-autonomous `references/pr-events.md`. Why: each described the removed prompt. Verify: `grep -rn "whether to push\|push prompt" kit/plugins/git-agent docs/guides --include='*.md' | grep -v CHANGELOG` returns nothing.
5. Add CHANGELOG entries and bump `.claude-plugin/marketplace.json` (git-agent 4.23.0, code-testing-agent 3.6.1), then regenerate the root README table. Why: the CI version guard and the `verify.sh` readme stage require both. Verify: `BASE_REF=main node scripts/check-plugin-versions.mjs` prints OK and `node scripts/build-readme-table.mjs --check` exits 0.

## Tests

### Objective verification

`tests/plugins/test-commit-agent-auto-push.sh` asserts the push step follows
the commit, says not to ask, has no `AskUserQuestion`, runs
`git push -u origin <current-branch>` and never a bare push, guards the default
branch before the push command, never forces or reconciles, keeps the
delegated stop after Step 4, and that every `Invoke ... commit-agent` line in
any plugin says it is delegating.

## Acceptance criteria

- [x] Direct invocation pushes after the commit with no prompt.
- [x] The push always names the branch, so a branch tracking `origin/main` pushes to its own name.
- [x] On the default branch the commit stays local and the skill says so.
- [x] A failed push is reported verbatim with no retry, force, or reconciliation.
- [x] Delegated invocation, and every skill that calls commit-agent, stops before the push.
- [x] `agent-commit` behavior is unchanged.

## Verification

`bash tests/run-all.sh` and `bash scripts/verify.sh` exit 0.
