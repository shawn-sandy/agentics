# Add `--all` sweep flag to finalize-plan

> `finalize-plan --all` discovers every non-completed plan in the plans directory, scores each with the token-evidence pass, and batch-finalizes user-selected candidates in one prompt.

<!-- generated:start -->

**Status:** Shipped 2026-08-27 **Plan:** [add-all-sweep-flag-to-finalize-plan.md](plans/add-all-sweep-flag-to-finalize-plan.md)
**Type:** feature

## What shipped

- Added `--all` sweep mode to `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` with a `### Sweep mode (--all)` section.
- Discovery uses `grep -lE` to find plans with `plan-status` meta tag valued `todo` or `in-progress`, excluding `index.html` and `archive/`.
- Cheap token-evidence scoring runs non-interactively; per-criterion verification runs only on user-selected plans.
- Single `AskUserQuestion` multi-select confirmation replaces one-prompt-per-plan flow.
- Bumped `plan-agent` to `2.13.0` with matching `CHANGELOG.md` entry and updated `argument-hint`.
- Added `tests/plugins/test-finalize-all-flag.sh` pinning the flag contract across SKILL.md, README, and marketplace.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin documentation | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Version history | Modified |
| `.claude-plugin/marketplace.json` | Marketplace registration | Modified |
| `tests/plugins/test-finalize-all-flag.sh` | Smoke test | Created |

## How it works

The `--all` flag adds a routing clause at the top of Step 1 in `finalize-plan/SKILL.md`. When present, the skill runs a sweep instead of the single-plan resolution path.

The sweep uses `grep -lE` to discover candidates: only files containing a `plan-status` meta tag valued `todo` or `in-progress` qualify; `index.html` and any path under `archive/` are excluded, preventing the gallery index and already-archived plans from appearing as candidates.

Each candidate receives a cheap, non-interactive token-evidence score using the same Step 2/3a checks the per-plan path already has. Plans that lack evidence tokens score 0% rather than triggering an interactive prompt, keeping the sweep fast.

A single `AskUserQuestion` with `multiSelect` presents the scored candidates to the user. Only plans the user picks proceed to the expensive per-criterion verification and finalization in Steps 3b, 3c, and 5. A single `SendUserFile` delivers the finalized output.

The test `tests/plugins/test-finalize-all-flag.sh` runs seven checks confirming the routing clause, sweep section, `grep -lE` discovery, exclusions, multi-select confirmation, deferred verification, and version alignment between CHANGELOG and marketplace.

## How to use it

```
/plan-agent:finalize-plan --all
```

Discovers all non-completed plans, presents a scored multi-select picker, and finalizes only the ones you choose. Without `--all`, the skill finalizes a single plan as before.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `87285986` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [add-all-sweep-flag-to-finalize-plan.md](plans/add-all-sweep-flag-to-finalize-plan.md)
