# Add Verification Gates

> Redefine "done" as artifact + verification in the five highest-blast-radius skills: settings-restore, code-review (both paths), ship/agent-ship, code-testing...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-verification-gates.md](plans/add-verification-gates.md)
**Type:** fix

## What shipped

- settings-restore — verify the restore — (`kit/plugins/settings-sync/skills/settings-restore/SKILL.md`): new Step 7 re-runs the Step 4 comparison for every restored entry, checks `~/.claude/hooks` execute bits, and the Step 9 report uses verified results only, leading with `Restore INCOMPLETE` on any failure.
- code-review — findings survive a re-read — (`.../code-review-agent/SKILL.md`, `agents/agent-code-reviewer.md`): a Verify Findings step re-Reads each cited file:line, pastes the verbatim snippet, drops or labels **Unconfirmed** anything unsubstantiated; the background agent gets the same as a workflow step plus a filled example finding.
- ship/agent-ship — PR state check — (`.../ship/references/pr-body.md`, `agents/agent-ship.md`, `.../ship/SKILL.md`): STOP only on `"state":"OPEN"`/`"opened"`; merged, closed, or no-PR proceeds to create.
- code-testing-agent — run what you write — (`.../code-testing-agent/SKILL.md` Step 6a, `.../reviewing-tests/SKILL.md` Step 7): execute written/edited tests via Bash, bounded 3-iteration fix loop with honest hard stops, behavior-gap failures reported as findings; stale-mock findings need paired mock+source quotes.
- review-plan — edit the spec, not the render — (`.../review-plan/SKILL.md`, `references/output-template.md`, `agents/agent-review-plan.md`, `commands/review-plan-bg.md`): Step 1 spec/legacy mode detection; spec mode maps selector targets to spec sections and re-renders with `plan-agent-render`; Team Review appended to the spec; Step 7 verifies each edit landed and announces an applied/skipped tally, with `REVIEW INCOMPLETE` in background mode on any skip.
- Bump versions and changelogs — : code-review 3.3.4, code-testing-agent 3.5.1, git-agent 4.19.1, settings-sync 1.1.3 (skips in-flight 1.1.2), plan-agent 9.4.3 (skips in-flight 9.4.2).

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
