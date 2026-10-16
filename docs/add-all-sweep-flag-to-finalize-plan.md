# Add `--all` sweep flag to finalize-plan

> Adds a `--all` sweep mode to `finalize-plan` that discovers every non-completed plan in the plans directory, scores each cheaply, and batch-confirms via one multi-select prompt.

<!-- generated:start -->

**Status:** Shipped 2026-07-02 **Plan:** [add-all-sweep-flag-to-finalize-plan.md](plans/add-all-sweep-flag-to-finalize-plan.md)
**Type:** feature

## What shipped

- Extended `finalize-plan/SKILL.md` with a `--all` routing clause and a `## Sweep mode (--all)` section that discovers non-completed plans via `grep -l` on `plan-status` meta tags, scores them with the cheap token-evidence pass, and batch-confirms via one `AskUserQuestion` multi-select prompt.
- Updated `argument-hint` and `description` frontmatter to document `--all` as a valid invocation form.
- Documented the flag in `kit/plugins/plan-agent/README.md` with a feature table row and usage examples.
- Bumped `plan-agent` to `2.13.0` in `.claude-plugin/marketplace.json` with a CHANGELOG entry.
- Added `tests/plugins/test-finalize-all-flag.sh` pinning the sweep contract to the SKILL.md, README, and marketplace version.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin documentation | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Version history | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |
| `tests/plugins/test-finalize-all-flag.sh` | Smoke test | Created |

## How it works

The `finalize-plan` skill's Step 1 previously resolved a single plan file. The `--all` routing clause intercepts the flag before that path and enters sweep mode. Sweep mode: discovers every `.html` plan file whose `<meta name="plan-status">` is `todo` or `in-progress` (excluding `index.html` and `archive/`), runs the cheap token-evidence scan from Step 3a on each candidate non-interactively (token-less plans score 0%), presents candidates ranked by evidence in one multi-select `AskUserQuestion`, and then runs the standard Steps 3b/3c/5 finalize pipeline only on user-selected plans.

The one-prompt design was intentional: a single batch confirmation instead of one prompt per plan scales to dozens of stale plans without requiring the user to sit through multiple interruptions.

## How to use it

```
/plan-agent:finalize-plan --all       # sweep all non-completed plans
/plan-agent:finalize-plan             # single-plan mode (unchanged)
```

After invoking `--all`, the skill presents a candidate table ranked by evidence score. Select the plans to finalize, choose criteria mode, and the skill processes only the selected set.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [add-all-sweep-flag-to-finalize-plan.md](plans/add-all-sweep-flag-to-finalize-plan.md)
- Changelog: [plan-agent CHANGELOG v2.13.0](../kit/plugins/plan-agent/CHANGELOG.md)
