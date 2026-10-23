# Add pre-PR adversarial review

> Adds step 4.7 to the pr-agent flow: an adversarial review of the diff before opening the PR, dispatched as a background subagent, with a six-point checklist and inline cold re-reads for background agents.

<!-- generated:start -->

**Status:** Shipped 2026-08-19 **Plan:** [add-pre-pr-adversarial-review.md](plans/add-pre-pr-adversarial-review.md)
**Type:** feature

## What shipped

- Added step 4.7 to `kit/plugins/git-agent/skills/pr-agent/SKILL.md`: adversarial pre-PR review.
- The ship skill dispatches step 4.7 as a background subagent, not inline.
- Background agents receive an inline cold re-read of the diff (they don't share context with the parent).
- Six-point checklist: correctness, security, performance, test coverage, breaking changes, documentation.
- Bumped git-agent to 4.19.3 in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/pr-agent/SKILL.md` | PR agent core | Modified |
| `kit/plugins/git-agent/skills/ship/SKILL.md` | Ship skill core | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |

## How it works

The adversarial review runs as a background subagent so it doesn't block the main ship flow: the PR description, labels, and reviewer assignments proceed in parallel while the review runs. The subagent gets a full copy of the diff inline because background agents start with no context — without the cold re-read, the agent would have no idea what to review.

The six-point checklist structures the review: correctness (does the code do what it claims), security (any new attack surfaces), performance (any O(n²) operations, unbounded allocations), test coverage (are the new paths tested), breaking changes (any interface changes that break callers), documentation (any public API changes without doc updates). Each point requires a finding or a green check — the review can't skip points.

When the adversarial review produces findings, they're posted as inline PR comments, not as a separate review summary. This matches how a human reviewer would comment — on the specific lines, not in a wall-of-text summary.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [add-pre-pr-adversarial-review.md](plans/add-pre-pr-adversarial-review.md)
