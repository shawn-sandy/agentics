# Add worked examples and close remaining verification gaps

> Tier 4 of the agent-prompting audit: ships one worked example everywhere a skill emits structured output from placeholders alone, and closes the remaining medium verification gaps across git-agent, social-media-tools, code-testing-agent, content-tools, plan-agent, memory-tools, and team-defaults.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-worked-examples.md](plans/add-worked-examples.md)
**Type:** chore

## What shipped

- **git-agent 4.19.2**: canonical worked PR body in `ship/references/pr-body.md`; filled bug-issue example in `create-issue/references/bug-report.md`; create-issue fallback carries the approved draft.
- **social-media-tools 2.23.3**: one worked post per platform in `references/platforms.md` (all measured within character limits); `save-artifact` verifies the published copy exists and the gallery index checksum changed before reporting success.
- **code-testing-agent 3.5.2**: filled `parseDuration` suggestion with a runnable Vitest snippet in `references/output-guide.md`, referenced from Step 5.
- **content-tools 1.1.1**: worked finished-MDX-post example in `references/post-assembly.md` Phase 8.
- **plan-agent 9.4.4**: `markdown-to-html` Step 5b parser gate with `Bash(python3 *)` grant; `build-fleet` verifies subagent-reported PRs via `gh pr view`; `prototype` asserts console + DOM state instead of a screenshot; `plan-status` executes the spec's objective `Run:` command and drops the invalid `draft` status.
- **memory-tools 4.1.1**: `bin/memory-verify-write` + `scripts/verify_write.py` replace the unrunnable inline gate (Bash-tool expansion refusal); guard test mutation-tests the shipped wrapper both directions; `allowed-tools` narrowed to the wrapper.
- **team-defaults 0.2.2**: sync-rules post-copy `diff -q` verification and the resolve-plugin-root-first instruction.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/git-agent/skills/ship/references/pr-body.md` | PR body worked example | Modified |
| `kit/plugins/git-agent/skills/create-issue/references/bug-report.md` | Issue body worked example | Modified |
| `kit/plugins/social-media-tools/references/platforms.md` | Per-platform worked examples | Modified |
| `kit/plugins/social-media-tools/skills/save-artifact/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/code-testing-agent/references/output-guide.md` | Output worked example | Modified |
| `kit/plugins/content-tools/references/post-assembly.md` | MDX worked example | Modified |
| `kit/plugins/plan-agent/skills/markdown-to-html/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-agent/skills/build-fleet/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-agent/skills/prototype/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-agent/skills/plan-status/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/memory-tools/bin/memory-verify-write` | Write verification wrapper | Created |
| `kit/plugins/memory-tools/scripts/verify_write.py` | Write verification script | Created |
| `kit/plugins/memory-tools/skills/agentic-memory-doctor/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/team-defaults/skills/sync-rules/SKILL.md` | Skill instructions | Modified |
| `.claude-plugin/marketplace.json` | Marketplace versions | Modified |

## How it works

The Composition principle from the agent-prompting audit: a filled instance beats a bracket-placeholder schema. Each worked example gives the model a concrete target to match rather than an abstract pattern to interpret, which is particularly important for structured output like PR bodies, issue templates, and test suggestion formats.

The memory-tools fix addresses a practical failure: the inline gate used a Bash-tool variable expansion (`${path}`) that the harness rejects before executing, making the gate unrunnable. The replacement wraps the verification logic in a proper script file that can be called without expansion.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `67ab9a1` | 2026-08-19 | docs: sync README plugin table with memory-tools 4.3.0 (#588) |

<!-- generated:end -->

## References

- Plan: [add-worked-examples.md](plans/add-worked-examples.md)
