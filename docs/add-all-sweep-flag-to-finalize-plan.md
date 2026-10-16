# Add `--all` Sweep Flag to finalize-plan

> Extends `plan-agent:finalize-plan` with a `--all` mode that discovers every non-completed plan, scores each with token evidence, and batch-finalizes selected plans in one pass.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-all-sweep-flag-to-finalize-plan.md](plans/add-all-sweep-flag-to-finalize-plan.md)
**Type:** feature

## What shipped

- Added `--all` sweep mode to `finalize-plan` that discovers every non-completed plan (via `grep -l` for `plan-status` meta tags valued `todo` or `in-progress`), scoring each with the existing token-evidence pass non-interactively.
- Batch confirmation via one multi-select `AskUserQuestion` prompt — a single picker replaces one prompt per plan.
- Selected plans are finalized via the existing Steps 3b/3c/5 pipeline; a single `SendUserFile` delivers all results.
- Discovery excludes `index.html` and never descends into `archive/`.
- Updated `argument-hint` frontmatter to include `--all` and moved sweep logic into a dedicated `references/sweep-mode.md` reference file.
- Documented the flag in `kit/plugins/plan-agent/README.md` with a feature-table row, usage example, and sweep-mode paragraph.
- Bumped `plan-agent` to `2.13.0` in `.claude-plugin/marketplace.json` with a CHANGELOG entry.
- Added `tests/plugins/test-finalize-all-flag.sh` pinning the flag contract, README docs, and marketplace version.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Skill contract — `--all` routing clause and sweep section | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/references/sweep-mode.md` | Extracted sweep logic (S1–S5) | Created |
| `tests/plugins/test-finalize-all-flag.sh` | Smoke test asserting flag contract, README, and version | Created |
| `kit/plugins/plan-agent/README.md` | Feature table row and usage block | Modified |
| `.claude-plugin/marketplace.json` | `plan-agent` bumped to `2.13.0` | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | `2.13.0` entry | Modified |

## How it works

Before this change, `finalize-plan` accepted a single plan file (or resolved the most recently modified one) and could only finalize one plan at a time. Plans that were fully implemented but never explicitly marked completed would silently accumulate.

The `--all` flag adds a routing clause at the top of Step 1: when `$ARGUMENTS` contains `--all`, single-file resolution is skipped entirely and control transfers to `references/sweep-mode.md`.

Sweep discovery (S1) uses `grep -l` to find every plan file carrying a `<meta name="plan-status">` tag valued `todo` or `in-progress`. This deliberately excludes `index.html` (which carries no such tag) and never recurses into `archive/`. The discovery is intentionally cheap — it reads only the meta tag, not the full plan body.

Scoring (S2–S3) reuses the existing token-evidence pass from Steps 2 and 3a of the single-plan flow: file-path and identifier tokens are extracted from the plan and checked against the codebase via `Glob` and `Grep`. Critically, per-criterion verification (the more expensive Step 3b) and the objective-verification test (Step 3c) are deferred — only token-less plans score 0% at this stage, never prompting. This keeps the sweep fast even across a large backlog.

Confirmation (S4) fires a single `AskUserQuestion` with `multiSelect`, presenting all scored candidates ranked by evidence percentage. The user ticks which plans to finalize and chooses a batch criteria mode, replacing what would otherwise be N individual confirmation dialogs.

For each selected plan, the existing per-plan pipeline (Steps 3b/3c/5) runs in sequence. A single `SendUserFile` call (S5) delivers all updated plan files together when the batch completes.

The `argument-hint` frontmatter now reads `[plan-file.md|.html] [--all] [--dir <path>]`. The SKILL.md body itself stays thin — it adds only the routing clause pointing to `references/sweep-mode.md`, consistent with the reference-file decomposition the skill already uses for evidence analysis and write-completions.

## How to use it

`/plan-agent:finalize-plan` with the `--all` flag sweeps the entire plans directory.

```text
/plan-agent:finalize-plan --all
/plan-agent:finalize-plan --all --dir docs/plans
```

When invoked, a multi-select picker appears listing every non-completed plan with its token-evidence score. Tick the plans to finalize and confirm — per-criterion verification runs only on the selected set.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |
| `17114d5` | 2026-08-25 | feat(plan-agent): card artifact-only plans in the plans gallery (9.7.0) (#601) |
| `3263bbc` | 2026-08-30 | feat(plan-agent): reconcile a plan against what actually shipped (9.11.0) (#613) |

<!-- generated:end -->

## References

- Plan: [add-all-sweep-flag-to-finalize-plan.md](plans/add-all-sweep-flag-to-finalize-plan.md)
