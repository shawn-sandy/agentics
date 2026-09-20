# Prove merge readiness locally, without GitHub Actions

> CI on this account is frequently billing-blocked, so a red check proves nothing and a green one never arrives. This builds a merge gate that runs entirely on...

<!-- generated:start -->

**Status:** Shipped 2026-08-22  **Plan:** [add-local-merge-gate.md](plans/add-local-merge-gate.md)
**Type:** feature

## What shipped

- Create `tests/fixtures/verify-gate-bare/` holding a project with no toolchain at all — a tracked `.gitkeep` and a one...
- Write `tests/test-verify-gate.sh` asserting that running the gate in the bare fixture prints a `SKIP (not configured)...
- Write `tests/plugins/test-verified-change-skill.sh` asserting the skill's frontmatter carries `name` and a descriptio...
- Write `kit/plugins/code-testing-agent/skills/verified-change/assets/verify.sh` running typecheck, lint, unit, then e2...
- Copy the template to `scripts/verify.sh`, mark it executable, and add `kit/plugins/code-testing-agent/bin/install-ver...
- Write `kit/plugins/code-testing-agent/skills/verified-change/SKILL.md` with the six-step loop — write the test, mutat...
- Write `references/mutation-check.md` giving a mutation catalogue by change type and the safe break-and-restore protoc...
- Write `references/verification-section.md` containing one filled VERIFICATION section — every gate with its real resu...
- Copy the finished skill directory — `SKILL.md` **and** both `references/` files — to `.claude/skills/verified-change/...
- Bump `code-testing-agent` from 3.5.2 to 3.6.0 in `.claude-plugin/marketplace.json`, add the skill to the plugin READM...

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `tests/test-verify-gate.sh` | objective test for skip behaviour, ordering, and exit codes | Created |
| `tests/plugins/test-verified-change-skill.sh` | skill structure, budgets, guard, and copy parity | Created |
| `kit/plugins/code-testing-agent/skills/verified-change/assets/verify.sh` | the portable gate template | Created |
| `kit/plugins/code-testing-agent/skills/verified-change/SKILL.md` | the six-step verified-change loop | Created |
| `kit/plugins/code-testing-agent/skills/verified-change/references/mutation-check.md` | mutation catalogue and safe restore protocol | Created |
| `kit/plugins/code-testing-agent/skills/verified-change/references/verification-section.md` | one filled VERIFICATION example | Created |
| `tests/fixtures/README.md` | document the two new fixtures and their deliberate depart... | Modified |
| `tests/plugins/test-exitplanmode-guard.sh` | register verified-change in the hardcoded guard list | Modified |
| `kit/plugins/code-testing-agent/README.md` | document the new skill | Modified |
| `kit/plugins/code-testing-agent/CHANGELOG.md` | 3.6.0 entry | Modified |
| `.claude-plugin/marketplace.json` | bump code-testing-agent to 3.6.0 | Modified |
| `README.md` | regenerated Plugin Reference Table | Modified |
| `scripts/verify.sh` | agentics' dogfood copy of the gate | Created |
| `CLAUDE.md` | the merge-gate rule | Modified |

## How it works

Ship a portable `verify.sh` merge gate and a `verified-change` skill that enforces test-first, mutation-checked changes, then dogfood both into the agentics repo so no change here is proposed for merge without local proof.

GitHub Actions is frequently billing-blocked on this account. A quota-blocked run fails every job in seconds with no test output, which means red CI is not evidence of a defect and green CI is not evidence of correctness — it is evidence of nothing at all. Merge readiness has to be provable on the machine.

The implementation proceeded through these steps: Create `tests/fixtures/verify-gate-bare/` holding a project with no toolchain at all — a tracked `.gitkeep` and a one...; Write `tests/test-verify-gate.sh` asserting that running the gate in the bare fixture prints a `SKIP (not configured)...; Write `tests/plugins/test-verified-change-skill.sh` asserting the skill's frontmatter carries `name` and a descriptio...; Write `kit/plugins/code-testing-agent/skills/verified-change/assets/verify.sh` running typecheck, lint, unit, then e2...; Copy the template to `scripts/verify.sh`, mark it executable, and add `kit/plugins/code-testing-agent/bin/install-ver....

- Marketplace stage count — `tests/run-all.sh` is the auto-detected unit stage, so the marketplace block contributes three stages (marketplace validation, version guard, README freshness) rather than re-running the suite a second time as step 4's wording implied; step 13's "unit stage and the three 

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `fd41fec` | 2026-08-22 | feat: prove merge readiness locally with a verify gate and verified-change skill |
| `0818be0` | 2026-08-21 | docs(plans): plan a local merge gate independent of GitHub Actions (#592) |

<!-- generated:end -->

## References

- Plan: [add-local-merge-gate.md](plans/add-local-merge-gate.md)
- Issue: https://github.com/shawn-sandy/agentics/issues/591
