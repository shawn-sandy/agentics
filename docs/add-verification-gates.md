# Add verification gates

> Adds explicit verification gates to five skills — code-review, code-testing-agent, git-agent, settings-sync, and plan-agent — so each skill confirms its own output before declaring success.

<!-- generated:start -->

**Status:** Shipped 2026-08-17 **Plan:** [add-verification-gates.md](plans/add-verification-gates.md)
**Type:** fix

## What shipped

- Added verification gates to code-review, code-testing-agent, git-agent, settings-sync, and plan-agent.
- Each gate checks that the skill's output matches its stated contract before completing.
- Version bumps: code-review 3.3.4, code-testing-agent 3.5.1, git-agent 4.19.1, settings-sync 1.1.3, plan-agent 9.4.3.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/code-review/` | Verification gate | Modified |
| `kit/plugins/code-testing-agent/` | Verification gate | Modified |
| `kit/plugins/git-agent/` | Verification gate | Modified |
| `kit/plugins/settings-sync/` | Verification gate | Modified |
| `kit/plugins/plan-agent/` | Verification gate | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |

## How it works

A verification gate is a check that runs at the end of a skill's main body, before the skill returns control to the user. The gate re-reads the output the skill produced and asserts that it satisfies the skill's success criteria. For a code-review skill, the gate checks that every finding has a file, line, and severity. For a git-agent ship skill, the gate checks that a PR URL was produced. For settings-sync, the gate checks that the sync log was updated.

Without verification gates, a skill could fail silently — produce partial output, or output that looked correct but failed a downstream consumer. The gates surface these failures at the source, with a clear error message pointing to which assertion failed and what the actual output contained.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [add-verification-gates.md](plans/add-verification-gates.md)
