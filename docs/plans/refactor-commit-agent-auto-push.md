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
replacement needs a guard against pushing the default branch.

## Objective

A direct `/git-agent:commit-agent` run commits and pushes with no prompt, never
pushes `main` or `master`, and keeps the existing push-failure and delegated
contracts.

## Steps

1. Write `tests/plugins/test-commit-agent-auto-push.sh` and watch it fail against the current skill. Why: the regression test must prove the old prompt is gone and the guards exist. Verify: the test exits 1 with failing Step 6 checks.
2. Replace Step 6 in `kit/plugins/git-agent/skills/commit-agent/SKILL.md` with an unprompted push, add the `main`/`master` skip, and update the description, intro, "When not to use", and delegated rationale. Why: the push must run without asking and never land on the default branch. Verify: the new test passes.
3. Update `kit/plugins/git-agent/README.md` and `docs/guides/how-to/git-agent.md`, including the `agent-commit` rationale that cited the removed prompt. Why: both described the prompt. Verify: `grep -rn "whether to push" kit/plugins/git-agent docs/guides` returns nothing.
4. Add a v4.23.0 entry to `kit/plugins/git-agent/CHANGELOG.md` and bump `.claude-plugin/marketplace.json` to 4.23.0. Why: the CI version guard requires a bump for any plugin change. Verify: `BASE_REF=main node scripts/check-plugin-versions.mjs` prints OK.

## Tests

### Objective verification

`tests/plugins/test-commit-agent-auto-push.sh` asserts Step 6 is a push step
after the commit with no `AskUserQuestion`, no "Don't push" option anywhere,
the description says it pushes, the `main` and `master` guards, no force or
reconciliation on failure, and the delegated stop after Step 4.

## Acceptance criteria

- [x] Direct invocation pushes after the commit with no prompt.
- [x] On `main` or `master` the commit stays local and the skill says so.
- [x] A failed push is reported verbatim with no retry, force, or reconciliation.
- [x] Delegated invocation still stops after Step 4.
- [x] `agent-commit` behavior is unchanged.

## Verification

`bash tests/run-all.sh` and `bash scripts/verify.sh` exit 0.
