# Add `--all` sweep flag to finalize-plan

> Extends `/plan-agent:finalize-plan` with a `--all` batch mode that discovers every non-completed plan, scores each with token evidence, and batch-confirms via one multi-select prompt.

<!-- generated:start -->

**Status:** Shipped 2026-07-02  **Plan:** [add-all-sweep-flag-to-finalize-plan.md](plans/add-all-sweep-flag-to-finalize-plan.md)
**Type:** feature

## What shipped

- Added `--all` routing clause to `finalize-plan/SKILL.md` with a `## Sweep mode (--all)` section covering discovery, scoring, and batch confirmation.
- Discovery uses `grep -l` to find plans with `todo`/`in-progress` status, excluding `index.html` and `archive/`.
- Batch confirmation via a single two-question `AskUserQuestion` with `multiSelect`, replacing per-plan prompts.
- Delivery via one `SendUserFile` call rather than per-plan messages.
- Updated `argument-hint` and `description` frontmatter to document the new invocation form.
- Added `2.13.0` CHANGELOG entry and bumped `plan-agent` to `2.13.0` in `marketplace.json`.
- Added `tests/plugins/test-finalize-all-flag.sh` pinning the sweep contract.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin documentation | Modified |
| `.claude-plugin/marketplace.json` | Marketplace version | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release notes | Modified |
| `tests/plugins/test-finalize-all-flag.sh` | Smoke test | Created |

## How it works

The `finalize-plan` skill gained a `--all` routing clause in its Step 1 that activates when the argument `--all` is passed. When triggered, it enters a sweep section instead of the single-plan flow.

The sweep discovers candidates by running `grep -l` for a `plan-status` meta tag with values `todo` or `in-progress`, excluding `index.html` and the `archive/` directory. This ensures only active plans are candidates.

Each candidate is scored using the existing token-evidence pass from Steps 2 and 3a — a cheap, non-interactive check that assigns a completion percentage based on evidence tokens. Token-less plans score 0% rather than prompting for per-criterion verification.

The user sees a single `AskUserQuestion` with `multiSelect` to pick which plans to finalize and choose criteria mode. Only selected plans proceed to the full verification and status-update flow (Steps 3b/3c/5).

## How to use it

Invoke as `/plan-agent:finalize-plan --all` to scan the plans directory. A multi-select prompt shows all eligible candidates with their evidence scores; check the ones to finalize.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|

<!-- generated:end -->

## References

- Plan: [add-all-sweep-flag-to-finalize-plan.md](plans/add-all-sweep-flag-to-finalize-plan.md)
