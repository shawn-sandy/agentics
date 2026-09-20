# A plan-backlog fleet skill for plan-agent

> The 2026-08-14 usage report proposed spawning a subagent per backlog plan, each in its own worktree, shipping concurrently. Four of the five subsystems that...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-plan-backlog-fleet-skill.md](plans/add-plan-backlog-fleet-skill.md)
**Type:** feature

## What shipped

- Write `kit/plugins/plan-agent/skills/build-fleet/SKILL.md` as a dispatch-only skill: collect candidates by reusing `b...
- Add the blast-radius guards to the Guardrails section — a mandatory confirmation naming how many pull requests will o...
- End the fleet at green PRs and route merging to `/git-agent:merge`, documenting that the repo's two merge drivers alr...
- Register the skill — bump plan-agent to 9.3.0 in `.claude-plugin/marketplace.json`, add the CHANGELOG entry, add the...
- Add `tests/plugins/test-build-fleet.sh` covering the frontmatter contract, `allowed-tools`, the verbatim plan-mode gu...
- Replace Step 2's "dispatch all, dispatch a subset, or cancel" with a real picker — one `multiSelect` `AskUserQuestion...
- Resolve the base branch from `git symbolic-ref --short refs/remotes/origin/HEAD` in Step 1 and carry the value into e...

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build-fleet/SKILL.md` | the dispatcher | Created |
| `.claude-plugin/marketplace.json` | plan-agent 9.2.0 to 9.3.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 9.3.0 entry | Modified |
| `kit/plugins/plan-agent/README.md` | Features table row and component section | Modified |
| `README.md` | regenerated Plugin Reference Table | Modified |
| `tests/plugins/test-build-fleet.sh` | structural smoke test | Created |

## How it works

Add `plan-agent:build-fleet`, a dispatch-only skill that fans `build` out across a plan backlog — one worktree subagent per `status: todo` plan, each running `build` then `ship-autonomous` to a green PR.

The 2026-08-14 usage report (`~/.claude/usage-data/report-2026-08-14-071004.html`) proposed "Parallel Worktree Fleets For Plan Backlogs": instead of shipping one plan at a time, spawn a subagent per backlog plan, each in an isolated git worktree, each implementing, verifying, opening a PR, and triaging review comments concurrently, with a supervisor watching CI and merging in dependency order. Four of the five subsystems that idea describes already ship here. `plan-agent:build` implements one pl...

The implementation proceeded through these steps: Write `kit/plugins/plan-agent/skills/build-fleet/SKILL.md` as a dispatch-only skill: collect candidates by reusing `b...; Add the blast-radius guards to the Guardrails section — a mandatory confirmation naming how many pull requests will o...; End the fleet at green PRs and route merging to `/git-agent:merge`, documenting that the repo's two merge drivers alr...; Register the skill — bump plan-agent to 9.3.0 in `.claude-plugin/marketplace.json`, add the CHANGELOG entry, add the ...; Add `tests/plugins/test-build-fleet.sh` covering the frontmatter contract, `allowed-tools`, the verbatim plan-mode gu....

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates ( |

<!-- generated:end -->

## References

- Plan: [add-plan-backlog-fleet-skill.md](plans/add-plan-backlog-fleet-skill.md)
