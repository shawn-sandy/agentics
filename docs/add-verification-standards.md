# Add Verification Standards

> Make verification self-enforcing — the authoring rules require it, the reviewer scores it, CI runs every test automatically, and the dist build fails loudly.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-verification-standards.md](plans/add-verification-standards.md)
**Type:** chore

## What shipped

- Authoring rule — (`.claude/rules/plugin-patterns.md`): new "The
- Rubric — (`skill-reviewer/.../references/audit-steps.md` Dimension 3 +
- Retention test — (`tests/plugins/test-verification-gate-rule.sh`): holds
- Test runner — (`tests/run-all.sh` + `check-plugin-versions.yml` + (49 of 77 test files ran in no workflow. *Verify:* `bash)
- Fix the stale render baseline — (`tests/plugins/test-plan-phases.mjs`):
- Dist builder — (`scripts/build-dist.mjs`): a manifest-registered plugin
- Bump skill-reviewer — 2.5.1 → 2.5.2 with a changelog entry.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `tests/plugins/test-verification-gate-rule.sh` | Test suite | Modified |
| `skill-reviewer/.../references/audit-steps.md` | Documentation | Modified |
| `best-practices.md` | Documentation | Modified |
| `test-exitplanmode-guard.sh` | Shell script | Modified |
| `tests/run-all.sh` | Test suite | Modified |
| `check-plugin-versions.yml` | Source file | Modified |
| `tests/plugins/test-plan-phases.mjs` | Test suite | Modified |
| `scripts/build-dist.mjs` | Implementation (JavaScript) | Modified |

## How it works

Make verification self-enforcing — the authoring rules require it, the reviewer scores it, CI runs every test automatically, and the dist build fails loudly.

Tier 3 — the leverage point — of the agent-prompting audit run against <https://shumer.dev/prompting-ai-agents>. Tiers 1–2 fixed nine shipped skills that could declare success on broken output; this tier fixes why they shipped that way: neither authoring rule required a verification gate or a worked example, the skill-quality rubric never scored them, 49 of 77 test files ran

The implementation proceeded through the following steps: Authoring rule: (`; Rubric: (`skill-reviewer/; Retention test: (`tests/plugins/test-verification-gate-rule; Test runner: (`tests/run-all; Fix the stale render baseline: (`tests/plugins/test-plan-phases; Dist builder: (`scripts/build-dist.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates (#573) |

<!-- generated:end -->

## References

- Plan: [add-verification-standards.md](plans/add-verification-standards.md)
