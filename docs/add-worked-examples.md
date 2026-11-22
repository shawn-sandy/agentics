# Add Worked Examples

> Seven plugins had skills that emitted structured output from placeholder schemas alone, with no filled instance a reader could learn from. This delivers one worked example everywhere a skill emits structured output, and closes the remaining medium verification gaps across the kit.

<!-- generated:start -->

**Status:** Shipped 2026-08-17 **Plan:** [add-worked-examples.md](plans/add-worked-examples.md)
**Type:** chore

## What shipped

- **git-agent 4.19.2**: canonical worked PR body in `ship/references/pr-body.md`; filled bug-issue example in `create-issue/references/bug-report.md`; create-issue fallback carries the approved draft with "no issue exists until you submit it" outcome.
- **social-media-tools 2.23.3**: one worked post per platform in `references/platforms.md` (all measured within character limits); `save-artifact` verifies the published copy exists and the gallery index checksum changed before reporting success.
- **code-testing-agent 3.5.2**: filled `parseDuration` suggestion with a runnable Vitest snippet in `references/output-guide.md`, referenced from Step 5.
- **content-tools 1.1.1**: worked finished-MDX-post example in `references/post-assembly.md` Phase 8.
- **plan-agent 9.4.4**: `markdown-to-html` Step 5b parser gate (+ `Bash(python3 *)` grant); `build-fleet` verifies subagent-reported PRs via `gh pr view`; `prototype` asserts console + DOM state instead of a screenshot; `plan-status` executes the spec's objective `Run:` command and drops the invalid `draft` status.
- **memory-tools 4.1.1**: `bin/memory-verify-write` + `scripts/verify_write.py` replace the unrunnable inline gate; ledger entries deleted; `allowed-tools` narrowed to the wrapper; `test-memory-doctor-guard.sh` mutation-tests the wrapper both directions.
- **team-defaults 0.2.2**: `sync-rules` post-copy `diff -q` verification and the resolve-plugin-root-first instruction.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/ship/references/pr-body.md` | Worked PR body | Modified |
| `kit/plugins/git-agent/skills/create-issue/references/bug-report.md` | Worked bug-issue example | Modified |
| `kit/plugins/social-media-tools/references/platforms.md` | Worked posts per platform | Modified |
| `kit/plugins/social-media-tools/skills/save-artifact/SKILL.md` | Publish verification | Modified |
| `kit/plugins/code-testing-agent/skills/code-testing-agent/references/output-guide.md` | Worked test suggestion | Modified |
| `kit/plugins/content-tools/references/post-assembly.md` | Worked MDX post example | Modified |
| `kit/plugins/plan-agent/skills/markdown-to-html/SKILL.md` | Parser gate Step 5b | Modified |
| `kit/plugins/plan-agent/skills/build-fleet/SKILL.md` | PR verification | Modified |
| `kit/plugins/plan-agent/skills/prototype/SKILL.md` | Console + DOM assertion | Modified |
| `kit/plugins/plan-agent/skills/plan-status/SKILL.md` | Executes Run: command | Modified |
| `kit/plugins/memory-tools/bin/memory-verify-write` | Runnable write gate | Created |
| `kit/plugins/memory-tools/scripts/verify_write.py` | Write verification script | Created |
| `kit/plugins/team-defaults/skills/sync-rules/SKILL.md` | Post-copy diff verification | Modified |
| `.claude-plugin/marketplace.json` | Seven plugin version bumps | Modified |

## How it works

The Composition principle: a filled instance beats a bracket-placeholder schema. Each worked example is wired to the step that reads it, so the model encounters both the template and a real example at the same time.

The memory-tools fix addresses a specific mechanical gap: the previous write gate used a Bash expansion (`${CLAUDE_PLUGIN_ROOT}/...`) that the harness rejects before any permission rule is consulted. The new `bin/memory-verify-write` wrapper replaces this with a stable invocable path, mutation-tested in both directions.

## How to use it

The worked examples are automatically loaded by each skill as it generates structured output. No invocation change is needed.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `bcaf6fa8` | 2026-08-17 | chore: worked examples and remaining verification gaps — 7 plugins (git-agent 4.19.2, social-media-tools 2.23.3, code-testing-agent 3.5.2, content-tools 1.1.1, plan-agent 9.4.4, memory-tools 4.1.1, team-defaults 0.2.2) (#570) |

<!-- generated:end -->

## References

- Plan: [add-worked-examples.md](plans/add-worked-examples.md)
