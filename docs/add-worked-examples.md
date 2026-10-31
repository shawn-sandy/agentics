# Add worked examples

> Adds worked examples to seven plugins and fixes a missing memory-verify-write binary, giving each plugin at least one concrete end-to-end usage example.

<!-- generated:start -->

**Status:** Shipped 2026-08-17 **Plan:** [add-worked-examples.md](plans/add-worked-examples.md)
**Type:** chore

## What shipped

- Added worked examples to git-agent, social-media-tools, code-testing-agent, content-tools, plan-agent, memory-tools, and team-defaults.
- Added `bin/memory-verify-write` to memory-tools (the binary was referenced in docs but not present).
- Version bumps: git-agent 4.19.2, social-media-tools 2.23.3, code-testing-agent 3.5.2, content-tools 1.1.1, plan-agent 9.4.4, memory-tools 4.1.1, team-defaults 0.2.2.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/` | Worked examples | Modified |
| `kit/plugins/social-media-tools/` | Worked examples | Modified |
| `kit/plugins/code-testing-agent/` | Worked examples | Modified |
| `kit/plugins/content-tools/` | Worked examples | Modified |
| `kit/plugins/plan-agent/` | Worked examples | Modified |
| `kit/plugins/memory-tools/bin/memory-verify-write` | Missing binary | Created |
| `kit/plugins/memory-tools/` | Worked examples | Modified |
| `kit/plugins/team-defaults/` | Worked examples | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |

## How it works

Each worked example follows the same structure: a realistic invocation with realistic input, the expected output, and a note on what to do if the output differs from expectation. The format is consistent across plugins so users know what to look for.

The `memory-verify-write` binary gap was found during worked-example authoring: the memory-tools README documented a `memory-verify-write` command that didn't exist in `bin/`. The command verifies that a write to memory was durably recorded by reading it back and comparing. Creating the binary closes the doc-reality gap and makes the worked example actually runnable.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [add-worked-examples.md](plans/add-worked-examples.md)
