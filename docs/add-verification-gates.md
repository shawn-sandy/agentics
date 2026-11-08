# Add Verification Gates

> Redefine "done" as artifact + verification in the five highest-blast-radius skills: settings-restore, code-review, ship/agent-ship, code-testing-agent, and review-plan.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [add-verification-gates.md](plans/add-verification-gates.md)
**Type:** fix

## What shipped

- **settings-restore**: added Step 7 that re-runs the Step 4 comparison for every restored entry, checks `~/.claude/hooks` execute bits, and gates the Step 9 report on verified results only — leading with `Restore INCOMPLETE` on any failure (previously reported planned counts, not verified ones)
- **code-review** (both paths): added a Verify Findings step that re-reads each cited `file:line`, pastes the verbatim snippet, and drops or labels `Unconfirmed` anything unsubstantiated; the background agent got the same treatment plus a filled example finding
- **ship / agent-ship**: fixed the PR state check to `STOP` only on `"state":"OPEN"` — merged, closed, or no-PR now proceeds to create rather than halting
- **code-testing-agent** (both skills): added execution of written/edited tests via Bash, a bounded 3-iteration fix loop with honest hard stops, behavior-gap failures reported as findings, and the requirement that stale-mock findings carry paired mock+source quotes
- **review-plan**: added Step 1 spec/legacy mode detection; spec mode maps selector targets to spec sections and re-renders with `plan-agent-render`; Team Review appended to the spec; Step 7 verifies each edit landed and announces an applied/skipped tally with `REVIEW INCOMPLETE` in background mode on any skip
- Bumped code-review 3.3.4, code-testing-agent 3.5.1, git-agent 4.19.1, settings-sync 1.1.3, plan-agent 9.4.3

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/settings-sync/skills/settings-restore/SKILL.md` | Step 7 verification gate | Modified |
| `kit/plugins/code-review/skills/code-review-agent/SKILL.md` | Verify Findings step | Modified |
| `kit/plugins/code-review/agents/agent-code-reviewer.md` | Verify Findings + filled example | Modified |
| `kit/plugins/git-agent/skills/ship/references/pr-body.md` | PR state check fix | Modified |
| `kit/plugins/git-agent/agents/agent-ship.md` | PR state check fix | Modified |
| `kit/plugins/git-agent/skills/ship/SKILL.md` | PR state check fix | Modified |
| `kit/plugins/code-testing-agent/skills/code-testing-agent/SKILL.md` | Execution gate, fix loop | Modified |
| `kit/plugins/code-testing-agent/skills/reviewing-tests/SKILL.md` | Execution gate, fix loop | Modified |
| `kit/plugins/plan-agent/skills/review-plan/SKILL.md` | Spec/legacy detection, edit tally | Modified |
| `kit/plugins/plan-agent/skills/review-plan/references/output-template.md` | Tally format | Modified |
| `kit/plugins/plan-agent/agents/agent-review-plan.md` | Background mode INCOMPLETE flag | Modified |
| `kit/plugins/plan-agent/commands/review-plan-bg.md` | Background mode INCOMPLETE flag | Modified |
| `.claude-plugin/marketplace.json` | Five plugin version bumps | Modified |

## How it works

Each fix targeted the specific gap where "done" was defined as producing the artifact rather than verifying it. The central finding — agents produce plausible-looking work and confidently declare completion — held in each of the five cases.

For `settings-restore`, the destructive overwrite (`rm -rf`/`rsync --delete`) previously reported planned entry counts. The new Step 7 re-runs the Step 4 file-by-file comparison after the write, checks execute bits on hook files, and the Step 9 report is only reachable once that gate passes.

For code-review, the checklist → report flow had no evidence requirement. The Verify Findings step forces a re-read of each cited location before a finding can be reported as confirmed. The background agent additionally got a filled example finding so its output format is unambiguous.

For ship/agent-ship, the fix was ported from `pr-agent` 3.3.2 where it had already been resolved: `gh pr view` now queries `state` and only an `OPEN` PR stops the flow. Merged or closed PRs proceed to create a new one.

For code-testing-agent, both skills previously handed verification to the user despite having access to Bash. The fix adds a mandatory execution step after writing or editing tests, a bounded 3-iteration fix loop (escalating to a hard stop rather than faking success), and the requirement that behavior-gap failures be reported as findings.

For review-plan, the previous HTML-editing approach was regenerated away by the pipeline's own rebuild hook. The fix adds spec-mode detection that maps review suggestions to the backing `.md` spec sections, re-renders after editing, and verifies each edit landed — reporting an applied/skipped tally rather than declaring success on the first pass.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `43d18ee` | 2026-10-31 | fix(plan-agent,social-media-tools): remove model pins from skills (9.22.0, 2.25.0) (#668) |
| `cc28a20` | 2026-10-28 | fix(settings-sync): restore switches back to this machine's branch (1.3.1) (#665) |
| `2f8b101` | 2026-10-28 | fix(settings-sync): back up each machine to its own branch (1.3.0) (#662) |
| `02136c1` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `28c3d70` | 2026-09-03 | fix(settings-sync): add marketplace step to install docs and stop false exec-bit failures (1.1.5) (#618) |
| `43a7fd9` | 2026-09-01 | feat(plan-agent): take review-plan off the experimental Agent Teams flag (#614) |
| `88a686a` | 2026-08-28 | fix(plan-agent): make artifact-published plans first-class in review, design, and prototype (#609) |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [add-verification-gates.md](plans/add-verification-gates.md)
- Audit source: <https://shumer.dev/prompting-ai-agents>
- Related plans: [add-verification-standards.md](add-verification-standards.md), [add-worked-examples.md](add-worked-examples.md)
