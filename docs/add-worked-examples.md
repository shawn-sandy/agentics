# Add Worked Examples

> Ships one worked example everywhere a skill emits structured output from placeholders alone, and closes the remaining medium verification gaps across six plugins (Tier 4 of the agent-prompting audit).

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [add-worked-examples](plans/add-worked-examples.md)
**Type:** chore

## What shipped

- **git-agent 4.19.2**: canonical worked PR body in `ship/references/pr-body.md`; filled bug-issue example in `create-issue/references/bug-report.md`; create-issue fallback carries approved draft with "no issue exists until you submit it" outcome
- **social-media-tools 2.23.3**: one worked post per platform in `references/platforms.md` (measured within character limits); `save-artifact` verifies published copy exists and gallery index checksum changed before reporting success
- **code-testing-agent 3.5.2**: filled `parseDuration` suggestion with runnable Vitest snippet in `references/output-guide.md`
- **content-tools 1.1.1**: worked finished-MDX-post example in `references/post-assembly.md` Phase 8
- **plan-agent 9.4.4**: markdown-to-html Step 5b parser gate + `Bash(python3 *)` grant; build-fleet verifies subagent-reported PRs via `gh pr view`; prototype asserts console + DOM state; plan-status executes the spec's objective `Run:` command, drops invalid `draft` status
- **memory-tools 4.1.1**: `bin/memory-verify-write` + `scripts/verify_write.py` replace the unrunnable inline gate; ledger entries deleted; guard test mutation-tests the wrapper

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/ship/references/pr-body.md` | Reference — worked PR body example | Modified |
| `kit/plugins/git-agent/skills/create-issue/references/bug-report.md` | Reference — worked bug issue example | Created |
| `kit/plugins/social-media-tools/references/platforms.md` | Reference — worked post examples | Modified |
| `kit/plugins/code-testing-agent/references/output-guide.md` | Reference — worked Vitest suggestion | Modified |
| `kit/plugins/content-tools/references/post-assembly.md` | Reference — worked MDX post example | Modified |
| `kit/plugins/memory-tools/bin/memory-verify-write` | Script — runnable verify-write wrapper | Created |
| `kit/plugins/memory-tools/scripts/verify_write.py` | Script — verify write implementation | Created |

## How it works

Tiers 1–3 of the audit (security scrub gaps, verification gates, verification standards) fixed skills that could declare success on broken output and created the authoring standard requiring verification. Tier 4 fills the composition gap: everywhere a skill emits structured output from placeholder schemas alone, a filled worked example replaces the schema.

The principle (from the audit): a filled instance beats a bracket-placeholder schema. `[PR_TITLE]` tells the author nothing about length, tone, or format. A real PR title from a real commit does. Each worked example is measured against the actual constraint — character limits for social posts, runnable test output for code suggestions.

The `memory-verify-write` wrapper replaces an inline gate that used a Bash expansion Claude Code refuses to run. The wrapper is a real executable that the guard test mutation-tests in both directions (valid input passes, broken input fails), confirming the gate has teeth.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [add-worked-examples](plans/add-worked-examples.md)
