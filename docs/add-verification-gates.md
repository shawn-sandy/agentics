# Add Verification Gates

> Redefine "done" as artifact + verification in the five highest-blast-radius skills: settings-restore, code-review (both paths), ship/agent-ship, code-testing...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-verification-gates.md](plans/add-verification-gates.md)
**Type:** fix

## What shipped

- **settings-restore — verify the restore** (a destructive overwrite reported planned counts, not verified ones.)
- **code-review — findings survive a re-read**
- **ship/agent-ship — PR state check**
- **code-testing-agent — run what you write** (both skills handed verification to the user despite having Bash.)
- **review-plan — edit the spec, not the render**
- Bump versions and changelogs — : code-review 3.3.4, code-testing-agent

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/settings-sync/skills/settings-restore/SKILL.md` | Skill instructions | Modified |
| `agents/agent-code-reviewer.md` | Documentation | Modified |
| `agents/agent-ship.md` | Documentation | Modified |
| `references/output-template.md` | Documentation | Modified |
| `agents/agent-review-plan.md` | Documentation | Modified |
| `commands/review-plan-bg.md` | Command wrapper | Modified |
| `tests/review-plan-skill.test.mjs` | Test suite | Modified |

## How it works

Redefine "done" as artifact + verification in the five highest-blast-radius skills: settings-restore, code-review (both paths), ship/agent-ship, code-testing-agent (both skills), and review-plan.

Tier 2 of the agent-prompting audit run against <https://shumer.dev/prompting-ai-agents> (Tier 1 shipped as the security-scrub PR): five confirmed places where a skill can declare success on broken output because "done" is defined as producing the artifact, not verifying it. The audit's central finding — agents produce plausible-looking

The implementation proceeded through the following steps: **settings-restore — verify the restore**; **code-review — findings survive a re-read**; **ship/agent-ship — PR state check**; **code-testing-agent — run what you write**; **review-plan — edit the spec, not the render**; Bump versions and changelogs: : code-review 3.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `ec3abc2` | 2026-08-17 | docs(plans): mark Tier 3 audit next-step done in add-verification-gates (#574) |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates (#573) |

<!-- generated:end -->

## References

- Plan: [add-verification-gates.md](plans/add-verification-gates.md)
