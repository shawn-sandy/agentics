# Harden review gates

> Adds five new defect classes to code-review, billing-block detection in merge, a stale-checkout guard in resolve-plan, and syncs review-bot-loops.md — hardening the review pipeline against known false-negative patterns.

<!-- generated:start -->

**Status:** Shipped 2026-08-21 **Plan:** [harden-review-gates.md](plans/harden-review-gates.md)
**Type:** feature

## What shipped

- Added five new defect classes to code-review: pagination tie-breakers, `parseInt` without radix, stale derived state, timezone-unaware dates, and scripts not aborting on error.
- Added billing-block detection in merge: identifies when a CI failure is caused by quota exhaustion rather than a code defect.
- Added stale-checkout guard in resolve-plan: warns when the plan being resolved was last modified before the branch diverged from main.
- Synced `review-bot-loops.md` with the new defect classes.
- Created `tests/review-gates.test.mjs`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/code-review/` | Five new defect classes | Modified |
| `kit/plugins/git-agent/skills/ship/references/` | Billing-block detection | Modified |
| `kit/plugins/plan-agent/skills/resolve-plan/` | Stale-checkout guard | Modified |
| `kit/plugins/git-agent/skills/ship/references/review-bot-loops.md` | Defect class sync | Modified |
| `tests/review-gates.test.mjs` | Review gate tests | Created |

## How it works

The five new defect classes fill gaps in the existing checklist:

1. **Pagination tie-breakers**: result sets sorted by a non-unique field (e.g., `created_at`) can return different rows on different pages when two rows share the timestamp. The fix is always adding a unique field as a secondary sort key.

2. **`parseInt` without radix**: `parseInt("08")` returns `0` in older environments because `08` is treated as octal and `8` is not a valid octal digit. The fix is always passing `10` as the radix.

3. **Stale derived state**: a value derived from props or state in a React component (or equivalent) that isn't recalculated when its inputs change. Typically caught by `useMemo` with a stale dependency array.

4. **Timezone-unaware dates**: `new Date()` returns local time; code that treats it as UTC produces wrong results for users in other timezones. The fix is using UTC methods or an explicit timezone library.

5. **Scripts not aborting on error**: shell scripts without `set -e` silently continue after a failing command. The fix is adding `set -euo pipefail` at the top of every shell script.

Billing-block detection checks CI failure output for quota-exhaustion patterns ("billing suspended", "spending limit reached") and classifies matching failures as external-blocker rather than code failures.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [harden-review-gates.md](plans/harden-review-gates.md)
