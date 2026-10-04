# Add Worked Examples

> Ship one worked example everywhere a skill emits structured output from placeholders alone, and close the remaining medium verification gaps across seven plugins.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-worked-examples.md](plans/add-worked-examples.md)
**Type:** chore

## What shipped

- **git-agent 4.19.2**: canonical worked PR body in `ship/references/pr-body.md`; filled bug-issue example in `create-issue/references/bug-report.md`; `create-issue` fallback now carries the approved draft and documents the "no issue exists until you submit it" outcome.
- **social-media-tools 2.23.3**: one worked post per platform in `references/platforms.md` (all measured within character limits); `save-artifact` now verifies the published copy exists and the gallery index checksum changed before reporting success.
- **code-testing-agent 3.5.2**: filled `parseDuration` suggestion with a runnable Vitest snippet in `references/output-guide.md`, referenced from Step 5.
- **content-tools 1.1.1**: worked finished-MDX-post example in `references/post-assembly.md` Phase 8.
- **plan-agent 9.4.4**: `markdown-to-html` Step 5b parser gate with `Bash(python3 *)` grant; `build-fleet` verifies subagent-reported PRs via `gh pr view`; `prototype` asserts console and DOM state instead of relying on a screenshot; `plan-status` executes the spec's objective `Run:` command and drops the invalid `draft` status.
- **memory-tools 4.1.1**: replaced the unrunnable inline write-gate (which used shell expansion that Bash refuses) with `bin/memory-verify-write` and `scripts/verify_write.py`; stale ledger entries removed; guard test mutation-tests the wrapper both directions; `allowed-tools` narrowed to the wrapper.
- **team-defaults 0.2.2**: `sync-rules` gained a post-copy `diff -q` verification step and the resolve-plugin-root-first instruction.
- Changelogs and marketplace bumps for all seven plugins.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/git-agent/skills/ship/references/pr-body.md` | Canonical worked PR body example | Modified |
| `kit/plugins/git-agent/skills/create-issue/references/bug-report.md` | Filled bug-issue example | Modified |
| `kit/plugins/social-media-tools/references/platforms.md` | Worked posts per platform | Modified |
| `kit/plugins/code-testing-agent/skills/code-testing-agent/references/output-guide.md` | Filled parseDuration Vitest example | Modified |
| `kit/plugins/plan-agent/skills/markdown-to-html/SKILL.md` | Parser gate added | Modified |
| `kit/plugins/plan-agent/skills/build-fleet/SKILL.md` | gh pr view verification added | Modified |
| `kit/plugins/plan-agent/skills/prototype/SKILL.md` | Console + DOM assertion gate | Modified |
| `kit/plugins/plan-agent/skills/plan-status/SKILL.md` | Executes Run: command, drops draft status | Modified |
| `kit/plugins/memory-tools/bin/memory-verify-write` | Runnable write-gate wrapper | Created |
| `kit/plugins/memory-tools/skills/agentic-memory-doctor/SKILL.md` | allowed-tools narrowed to wrapper | Modified |
| `.claude-plugin/marketplace.json` | Seven plugin version bumps | Modified |

## How it works

This tier of the agent-prompting audit focused on the Composition principle: a filled example teaches the model more reliably than a bracket-placeholder schema. Each shipped example replaces a structure like `[title]` or `[summary]` with actual content that a model can calibrate against.

The `pr-body.md` worked example is the highest-leverage change: it is referenced by `pr-agent`, `agent-pr`, and `agent-ship`, so one filled example improves three separate skills simultaneously. The example covers a real-world PR with a concrete summary, test plan, and rollback note — not a toy scenario.

The `platforms.md` worked posts close the gap where social-media-tools generated posts from character-limit tables alone. Each platform now has a filled post measured to fit within its limit, giving the model a concrete target.

The `memory-tools` wrapper fix (`bin/memory-verify-write`) is the most mechanical: the previous inline gate used `$(cat file | python3 -c ...)` shell expansion that the Bash tool refuses at runtime, making the gate unrunnable. The fix wraps the Python logic in a standalone executable that Bash can call without expansion, and the guard test mutation-tests the wrapper on both valid and broken fixture files to prove the gate actually fires.

The `plan-agent` verification gaps addressed a pattern where skills delegated verification back to the user despite having Bash available. `markdown-to-html` now runs a `python3` parse after generating HTML; `build-fleet` runs `gh pr view` on each subagent-reported PR URL; `prototype` asserts that the browser console is error-free and the expected DOM nodes are present; `plan-status` executes the spec's `Run:` command rather than inspecting its text.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| 0fd7b67 | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |

<!-- generated:end -->

## References

- Plan: [add-worked-examples.md](plans/add-worked-examples.md)
