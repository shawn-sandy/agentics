# Add Verification Gates

> Redefine "done" as artifact + verification in the five highest-blast-radius skills: settings-restore, code-review (both paths), ship/agent-ship, code-testing...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-verification-gates.md](plans/add-verification-gates.md)
**Type:** fix

## What shipped

- settings-restore — verify the restore (a destructive overwrite reported planned counts, not verified ones.)
- code-review — findings survive a re-read
- ship/agent-ship — PR state check
- code-testing-agent — run what you write (both skills handed verification to the user despite having Bash.)
- review-plan — edit the spec, not the render
- Bump versions and changelogs — : code-review 3

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `(see plan)` | — | — |

## How it works

Redefine "done" as artifact + verification in the five highest-blast-radius skills: settings-restore, code-review (both paths), ship/agent-ship, code-testing-agent (both skills), and review-plan.

Tier 2 of the agent-prompting audit run against <https://shumer.dev/prompting-ai-agents> (Tier 1 shipped as the security-scrub PR): five confirmed places where a skill can declare success on broken output because "done" is defined as producing the artifact, not

The implementation proceeded through these steps: **settings-restore — verify the restore**; **code-review — findings survive a re-read**; **ship/agent-ship — PR state check**; **code-testing-agent — run what you write**; **review-plan — edit the spec, not the render**.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `ec3abc2` | 2026-08-17 | docs(plans): mark Tier 3 audit next-step done in add-verification-gates (#574) |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates ( |

<!-- generated:end -->

## References

- Plan: [add-verification-gates.md](plans/add-verification-gates.md)
