# Add `--all` sweep flag to finalize-plan

> Adds a `--all` sweep mode to `finalize-plan` that discovers every non-completed plan, scores each with token-evidence checks, and batch-confirms via one multi-select prompt.

<!-- generated:start -->

**Status:** Shipped 2026-08-15 **Plan:** [add-all-sweep-flag-to-finalize-plan.md](plans/add-all-sweep-flag-to-finalize-plan.md)
**Type:** feature

## What shipped

- Added `--all` sweep routing clause to `finalize-plan` SKILL.md so a single invocation discovers and finalizes multiple plans (avoiding silent accumulation of done-but-unmarked plans).
- Implemented sweep discovery via `grep -lE` matching `plan-status` meta tags valued `todo` or `in-progress`, excluding `index.html` and never descending into `archive/`.
- Added non-interactive scoring pass that reuses the existing token-evidence checks — token-less plans score 0% rather than prompting per-plan.
- Introduced batch confirmation via a single `AskUserQuestion` multi-select prompt, replacing per-plan interactive gates.
- Delivered all finalized plans via a single `SendUserFile` call.
- Updated `argument-hint` and `description` frontmatter in SKILL.md to document `--all`.
- Documented the flag in the plugin README with a feature table row, usage example, and sweep-mode paragraph.
- Bumped `plan-agent` to `2.13.0` in `marketplace.json` with a CHANGELOG entry.
- Added `tests/plugins/test-finalize-all-flag.sh` to pin the sweep contract across SKILL.md, README, and marketplace version.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Skill contract — routing clause and sweep section | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin documentation — feature table, usage, and description | Modified |
| `.claude-plugin/marketplace.json` | Marketplace version bump to 2.13.0 | Modified |
| `tests/plugins/test-finalize-all-flag.sh` | Smoke test pinning the sweep contract | Created |

## How it works

**Routing.** Step 1 of `finalize-plan` gained a `--all` routing clause. When the flag is present, execution branches into sweep mode rather than resolving a single plan filename. This sits at the top of Step 1 so the sweep path is entered before any single-plan resolution runs.

**Discovery.** Sweep mode discovers candidates with `grep -lE` searching for a `<meta name="plan-status">` tag valued `todo` or `in-progress`. The search is scoped to the plans directory and explicitly excludes `index.html` and the `archive/` subdirectory, so neither the gallery index nor archived historical plans are offered as candidates.

**Scoring.** Each discovered plan is scored using the same cheap token-evidence pass already present in Steps 2 and 3a of the single-plan flow. Crucially, this scoring is non-interactive: a plan with no matching tokens scores 0% rather than prompting the user. This keeps the sweep viable for repositories with dozens of candidates.

**Batch confirmation.** After scoring, all candidates are presented in a single `AskUserQuestion` call with `multiSelect` — one prompt to pick which plans to finalize and what criteria mode to use. Per-plan verification gates (the expensive per-criterion checks) run only on user-selected plans. This mirrors the single-plan Steps 3b and 3c flow.

**Delivery.** Selected plans go through the standard Steps 3b, 3c, and 5 pipeline, then all results are delivered via one `SendUserFile` call. This avoids repeated delivery prompts when many plans are finalized together.

**Test coverage.** `tests/plugins/test-finalize-all-flag.sh` asserts seven checks: the routing clause is present in SKILL.md, the sweep section exists with `grep -lE` discovery, the `index.html` and `archive/` exclusions are stated, multi-select confirmation is documented, expensive verification is deferred to selected plans only, `--all` appears in the README table and usage block, and both the CHANGELOG and `marketplace.json` carry `2.13.0`.

## How to use it

Activation trigger: `/plan-agent:finalize-plan --all`

```
# Finalize all non-completed plans in the plans directory
/plan-agent:finalize-plan --all

# Finalize a single specific plan (unchanged behavior)
/plan-agent:finalize-plan docs/plans/my-feature.md
```

The sweep presents a multi-select menu of candidates sorted by evidence score. Select plans and choose a criteria mode; only selected plans receive the full per-criterion verification and are marked completed.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `3263bbc` | 2026-08-30 | feat(plan-agent): reconcile a plan against what actually shipped (9.11.0) (#613) |
| `17114d5` | 2026-08-25 | feat(plan-agent): card artifact-only plans in the plans gallery (9.7.0) (#601) |

<!-- generated:end -->

## References

- Plan: [add-all-sweep-flag-to-finalize-plan.md](plans/add-all-sweep-flag-to-finalize-plan.md)
