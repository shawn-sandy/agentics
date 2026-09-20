# Add Verification Standards

> Make verification self-enforcing — the authoring rules require it, the reviewer scores it, CI runs every test automatically, and the dist build fails loudly.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-verification-standards.md](plans/add-verification-standards.md)
**Type:** chore

## What shipped

- Authoring rule — (`
- Rubric — (`skill-reviewer/
- Retention test — (`tests/plugins/test-verification-gate-rule
- Test runner — (`tests/run-all (49 of 77 test files ran in no workflow. *Verify:* `bash)
- Fix the stale render baseline — (`tests/plugins/test-plan-phases
- Dist builder — (`scripts/build-dist
- Bump skill-reviewer — 2

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `(see plan)` | — | — |

## How it works

Make verification self-enforcing — the authoring rules require it, the reviewer scores it, CI runs every test automatically, and the dist build fails loudly.

Tier 3 — the leverage point — of the agent-prompting audit run against <https://shumer.dev/prompting-ai-agents>. Tiers 1–2 fixed nine shipped skills that could declare success on broken output; this tier fixes why they shipped that way: neither authoring rule required a verification gate or a worked

The implementation proceeded through these steps: Authoring rule: (`; Rubric: (`skill-reviewer/; Retention test: (`tests/plugins/test-verification-gate-rule; Test runner: (`tests/run-all; Fix the stale render baseline: (`tests/plugins/test-plan-phases.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates ( |

<!-- generated:end -->

## References

- Plan: [add-verification-standards.md](plans/add-verification-standards.md)
