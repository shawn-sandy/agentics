# Add Verification Gates

> Five confirmed places where a skill can declare success on broken output because "done" is defined as producing the artifact, not verifying it. This redefines "done" as artifact + verification in the five highest-blast-radius skills.

<!-- generated:start -->

**Status:** Shipped 2026-08-17 **Plan:** [add-verification-gates.md](plans/add-verification-gates.md)
**Type:** fix

## What shipped

- **settings-restore**: added Step 7 re-running the Step 4 comparison for every restored entry and checking `~/.claude/hooks` execute bits; Step 9 report uses verified results only, leading with `Restore INCOMPLETE` on any failure.
- **code-review**: added Verify Findings step re-reading each cited file:line, pasting the verbatim snippet, dropping or labeling `Unconfirmed` anything unsubstantiated; `agent-code-reviewer.md` background agent gets the same plus a filled example finding.
- **ship / agent-ship**: added PR state check (`"state":"OPEN"` → stop; merged, closed, or no-PR → proceed to create); fixed for `pr-agent` in 3.3.2, now ported to `ship` and `agent-ship`.
- **code-testing-agent**: added execute gate to Step 6a and `reviewing-tests` Step 7 — written/edited tests run via Bash before reporting done; bounded 3-iteration fix loop with honest hard stops; behavior-gap failures reported as findings; stale-mock findings need paired mock+source quotes.
- **review-plan**: added Step 1 spec/legacy mode detection; spec mode maps selector targets to spec sections and re-renders with `plan-agent-render`; Step 7 verifies each edit landed and announces an applied/skipped tally; `REVIEW INCOMPLETE` in background mode on any skip.
- Bumped five plugins: code-review 3.3.4, code-testing-agent 3.5.1, git-agent 4.19.1, settings-sync 1.1.3, plan-agent 9.4.3.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/settings-sync/skills/settings-restore/SKILL.md` | Step 7 verification gate | Modified |
| `kit/plugins/code-review/skills/code-review-agent/SKILL.md` | Verify Findings step | Modified |
| `kit/plugins/code-review/agents/agent-code-reviewer.md` | Verify Findings + example | Modified |
| `kit/plugins/git-agent/skills/ship/references/pr-body.md` | PR state check | Modified |
| `kit/plugins/git-agent/agents/agent-ship.md` | PR state check | Modified |
| `kit/plugins/git-agent/skills/ship/SKILL.md` | PR state check | Modified |
| `kit/plugins/code-testing-agent/skills/code-testing-agent/SKILL.md` | Execute gate Step 6a | Modified |
| `kit/plugins/code-testing-agent/skills/reviewing-tests/SKILL.md` | Execute gate Step 7 | Modified |
| `kit/plugins/plan-agent/skills/review-plan/SKILL.md` | Spec/legacy detection, Step 7 tally | Modified |
| `kit/plugins/plan-agent/skills/review-plan/references/output-template.md` | Applied/skipped tally | Modified |
| `kit/plugins/plan-agent/agents/agent-review-plan.md` | REVIEW INCOMPLETE signal | Modified |
| `kit/plugins/plan-agent/commands/review-plan-bg.md` | REVIEW INCOMPLETE signal | Modified |
| `tests/review-plan-skill.test.mjs` | 12 assertions over Step 7 | Modified |
| `.claude-plugin/marketplace.json` | Five plugin version bumps | Modified |

## How it works

Each fix closes a specific gap in a high-blast-radius skill:

- **settings-restore**: a destructive overwrite was reporting planned counts, not verified ones. Step 7 re-checks every entry after the restore so the final report reflects the actual state.
- **code-review**: a checklist became a report with no evidence requirement. The Verify step requires a verbatim current-file quote for every Critical Issue or Breaking Change.
- **ship**: `gh pr view` was not checking PR state before creating — it now stops on `OPEN` only and proceeds on merged, closed, or no existing PR.
- **code-testing-agent**: both skills handed verification to the user despite having Bash access. Done now means written **and** executed.
- **review-plan**: HTML edits were being regenerated away by the pipeline's own hook. Spec-backed plans now edit the `.md` spec and re-render.

## How to use it

The gates fire automatically as part of each skill's existing workflow. No invocation change is needed — `settings-restore`, `code-review`, `ship`, `code-testing-agent`, and `review-plan` all carry their verification steps as standard parts of their flows.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| — | 2026-08-17 | fix: add verification gates to five highest-blast-radius skills (code-review 3.3.4, code-testing-agent 3.5.1, git-agent 4.19.1, settings-sync 1.1.3, plan-agent 9.4.3) |

<!-- generated:end -->

## References

- Plan: [add-verification-gates.md](plans/add-verification-gates.md)
