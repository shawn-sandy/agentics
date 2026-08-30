# Add `--all` sweep flag to finalize-plan

> `finalize-plan --all` discovers every non-completed plan in the plans directory, scores each with the existing token-evidence pass, and finalizes only the user-selected plans in one batch pass.

<!-- generated:start -->

**Status:** Shipped 2026-08-12 **Plan:** [add-all-sweep-flag-to-finalize-plan](plans/add-all-sweep-flag-to-finalize-plan.md)
**Type:** feature

## What shipped

- Added `--all` sweep mode to `finalize-plan` that discovers non-completed plans via `grep -lE` on `plan-status` meta tags valued `todo` or `in-progress`
- Sweep mode scores candidates with the cheap token-evidence pass non-interactively, without prompting per plan
- Batch confirmation via a single `AskUserQuestion` multi-select prompt rather than one prompt per plan
- Exclusions for `index.html` and the `archive/` directory prevent non-plan HTML from appearing as candidates
- Finalized plans are delivered in one `SendUserFile` call
- `plan-agent` bumped to `2.13.0` with documentation and marketplace entry updated

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Skill contract — routing clause, sweep section, updated argument-hint and description frontmatter | Modified |
| `kit/plugins/plan-agent/README.md` | User-facing docs — feature table row, usage example, sweep-mode paragraph | Modified |
| `.claude-plugin/marketplace.json` | Marketplace version bump to 2.13.0 and extended description | Modified |
| `tests/plugins/test-finalize-all-flag.sh` | Smoke test pinning the `--all` flag contract across SKILL.md, README, and marketplace | Created |

## How it works

`finalize-plan` previously handled exactly one plan per invocation — either the path you named or the most-recently-modified file in the plans directory. Implemented-but-never-closed plans accumulated silently with no tooling to find them.

The `--all` flag adds a routing clause at Step 1 of `SKILL.md`. When the flag is present the skill skips its normal single-plan resolution and enters sweep mode. Discovery runs `grep -lE` against the plans directory, matching files whose `<meta name="plan-status">` tag carries the value `todo` or `in-progress`. `index.html` is excluded explicitly, and no descent into `archive/` occurs.

Each discovered candidate is scored using the cheap token-evidence pass that Steps 2 and 3a of the normal flow already define. This scoring is non-interactive: a plan with no token evidence scores 0% rather than triggering a prompt, keeping the sweep fast regardless of how many candidates are found.

Confirmation collapses to one `AskUserQuestion` call with a `multiSelect` question presenting all scored candidates. A second question in the same call selects the criteria verification mode to apply across the batch. Only plans the user selects advance to the finalizing stages (Steps 3b, 3c, and 5 of the existing pipeline).

Delivery uses a single `SendUserFile` call rather than one per plan. The `argument-hint` frontmatter and README documentation were updated in the same PR to reflect the new invocation form.

The smoke test at `tests/plugins/test-finalize-all-flag.sh` asserts seven checks: the routing clause exists in SKILL.md, the sweep section is present, `grep -lE` is used for discovery with the todo/in-progress match, `index.html` and `archive/` are excluded, multi-select batch confirmation is documented, the README documents the `--all` flag, and the marketplace and CHANGELOG both carry `2.13.0`.

## How to use it

```text
/plan-agent:finalize-plan --all
```

Scans the plans directory, scores non-completed plans by token evidence, presents a single batch selector, and finalizes only the plans you select. Equivalent single-plan invocation is unchanged:

```text
/plan-agent:finalize-plan
/plan-agent:finalize-plan docs/plans/my-plan.md
```

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `df49b6d` | 2026-08-12 | feat(settings-sync): restore onto a new machine via clone URL (1.1.0) (#548) |

<!-- generated:end -->

## References

- Plan: [add-all-sweep-flag-to-finalize-plan](plans/add-all-sweep-flag-to-finalize-plan.md)
