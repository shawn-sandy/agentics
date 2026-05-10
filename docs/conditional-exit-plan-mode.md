# Refactor ExitPlanMode: Conditional Detection + Silent Exit

> Standardizes all `ExitPlanMode` usage across git-agent and agentic-plugin-dev to a "detect-then-exit-silently" pattern, replacing unconditional calls and user-prompting with an explicit plan-mode check at the start of each write-heavy skill.

<!-- generated:start -->

**Status:** Shipped 2026-05-01 **Plan:** [conditional-exit-plan-mode.md](plans/conditional-exit-plan-mode.md)
**Type:** feature

## What shipped

- Updated the four git-mutating `git-agent` skills (`branch-agent`, `commit-agent`, `pr-agent`, `ship`) to detect whether plan mode is active before calling `ExitPlanMode`, skipping the call when not in plan mode (v3.6.1, PATCH — no behavioral change).
- Refactored `agentic-plugin-dev`'s `plugin-creator` skill to self-exit plan mode silently instead of blocking execution and asking the user to exit (v1.2.0, MINOR — new capability).
- Added `ExitPlanMode` to `plugin-creator`'s `allowed-tools`.
- Renumbered `plugin-creator` steps: the new Step 0 (Exit Plan Mode) precedes the existing Disambiguation step (now Step 1).
- Updated both plugins' CHANGELOGs and bumped versions in `.claude-plugin/marketplace.json`.

> See [git-agent CHANGELOG §v3.6.1](../kit/plugins/git-agent/CHANGELOG.md#v361--conditional-exitplanmode-detection) and [agentic-plugin-dev CHANGELOG §1.2.0](../kit/plugins/agentic-plugin-dev/CHANGELOG.md#120---2026-05-01) for the authoritative feature lists.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/branch-agent/SKILL.md` | Skill instructions — branch-agent | Modified |
| `kit/plugins/git-agent/skills/commit-agent/SKILL.md` | Skill instructions — commit-agent | Modified |
| `kit/plugins/git-agent/skills/pr-agent/SKILL.md` | Skill instructions — pr-agent | Modified |
| `kit/plugins/git-agent/skills/ship/SKILL.md` | Skill instructions — ship | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Release notes | Modified |
| `kit/plugins/agentic-plugin-dev/skills/plugin-creator/SKILL.md` | Skill instructions — plugin-creator | Modified |
| `kit/plugins/agentic-plugin-dev/CHANGELOG.md` | Release notes | Modified |
| `.claude-plugin/marketplace.json` | Marketplace registry | Modified |

## How it works

Before this change, several skills called `ExitPlanMode` unconditionally — always exiting plan mode even when not in plan mode. Others (specifically `plugin-creator`) blocked execution and displayed a manual prompt like "Please exit plan mode before continuing." Both patterns are fragile: unconditional calls add noise when not in plan mode, and user-prompting can stall automated workflows.

The new Step 0 template reads:

> "If plan mode is active (a system reminder indicates 'Plan mode is active'), call `ExitPlanMode` silently before any other action. If plan mode is not active, skip directly to Step 1. Do not prompt the user — exit silently."

Each skill adapts this template with a rationale sentence appropriate to its operation (e.g., "Git mutations require plan mode to be off").

For `plugin-creator`, the existing "Plan Mode Guard" section was replaced by Step 0, `ExitPlanMode` was added to `allowed-tools`, and the subsequent disambiguation step became Step 1 (with all further steps renumbered). The Table of Contents was also updated.

The `code-simplifier` and `plan-interview hooks.json` were reviewed and found to require no changes — `code-simplifier` owns its own plan-mode lifecycle within the skill, and `plan-interview`'s hook fires after `ExitPlanMode` has already been called.

## How to use it

This is a behavioral refinement, not a new feature. All skills work the same way — the difference is that they no longer require or prompt around plan mode.

If you load `git-agent` with `--plugin-dir`:
- Invoke any of `branch-agent`, `commit-agent`, `pr-agent`, or `ship` while in plan mode → the skill silently exits plan mode and proceeds.
- Invoke the same skill outside plan mode → Step 0 is skipped with no side effect.

For `plugin-creator` (in `agentic-plugin-dev`):
- Previously: if in plan mode, the skill blocked and asked you to exit manually.
- Now: the skill exits plan mode silently and continues.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `428cdaa` | 2026-05-01 | refactor(kit/plugins): conditional ExitPlanMode detection — skip if not in plan mode |
| `c3cf1ce` | 2026-05-01 | docs(plans): add YAML frontmatter to conditional-exit-plan-mode |
| `c15082d` | 2026-05-07 | fix(plugins): improve skill activation, discoverability, and README sync (#95) |

<!-- generated:end -->

## References

- Plan: [conditional-exit-plan-mode.md](plans/conditional-exit-plan-mode.md)
- Changelog: [git-agent CHANGELOG §v3.6.1](../kit/plugins/git-agent/CHANGELOG.md) · [agentic-plugin-dev CHANGELOG §1.2.0](../kit/plugins/agentic-plugin-dev/CHANGELOG.md)
- Related docs: [add-ship-skill-to-git-agent.md](add-ship-skill-to-git-agent.md)
