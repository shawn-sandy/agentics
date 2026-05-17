# Refactor ExitPlanMode: Conditional Detection + Silent Exit

> Standardizes all ExitPlanMode usage across the git-agent and agentic-plugin-dev plugins to a "detect-then-exit-silently" pattern, replacing unconditional calls and user-facing exit prompts with an explicit conditional Step 0.

<!-- generated:start -->

**Status:** Shipped 2026-05-07  **Plan:** [conditional-exit-plan-mode.md](plans/conditional-exit-plan-mode.md)
**Type:** artifact

## What shipped

- Updated `kit/plugins/git-agent/skills/branch-agent/SKILL.md` — replaced unconditional `ExitPlanMode` call in Step 0 with conditional detection: check for "Plan mode is active" system reminder, call `ExitPlanMode` silently if active, skip to Step 1 if not.
- Updated `kit/plugins/git-agent/skills/commit-agent/SKILL.md` — same conditional Step 0 pattern (commits require plan mode off for write access).
- Updated `kit/plugins/git-agent/skills/pr-agent/SKILL.md` — same conditional Step 0 pattern (PR creation requires plan mode off).
- Updated `kit/plugins/git-agent/skills/ship/SKILL.md` — same conditional Step 0 pattern (ship workflow chains multiple write operations).
- Refactored `kit/plugins/agentic-plugin-dev/skills/plugin-creator/SKILL.md` — replaced the "Plan Mode Guard" section (which told the user to manually exit plan mode and blocked execution) with a conditional Step 0 that self-exits silently; added `ExitPlanMode` to `allowed-tools`; renumbered subsequent steps (Disambiguation is now Step 1, Steps 1-5 become Steps 2-6); updated Table of Contents.
- Updated `kit/plugins/git-agent/CHANGELOG.md` with a `v3.6.1` patch entry covering all four git-mutating skills.
- Updated `kit/plugins/agentic-plugin-dev/CHANGELOG.md` with a `[1.2.0]` minor entry for the plugin-creator self-exit change.
- Bumped `.claude-plugin/marketplace.json`: `git-agent` 3.6.0 → 3.6.1 (patch), `agentic-plugin-dev` 1.1.0 → 1.2.0 (minor).

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/git-agent/skills/branch-agent/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/git-agent/skills/commit-agent/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/git-agent/skills/pr-agent/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/git-agent/skills/ship/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/agentic-plugin-dev/skills/plugin-creator/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Changelog | Modified |
| `kit/plugins/agentic-plugin-dev/CHANGELOG.md` | Changelog | Modified |
| `.claude-plugin/marketplace.json` | Marketplace entry | Modified |

## How it works

`ExitPlanMode` is already a no-op when called outside plan mode, so the unconditional calls in the git-agent skills had no behavioral defect. The problem was at the instruction level: skills that always called `ExitPlanMode` without checking first were training ambiguous reading habits and could confuse future authors about when the call is necessary. Making the conditional detection explicit ensures that skills accurately model their own execution context.

The standardized Step 0 template reads: "If plan mode is active (a system reminder indicates 'Plan mode is active'), call `ExitPlanMode` silently before any other action. If plan mode is not active, skip directly to Step 1. Do not prompt the user — exit silently." Each skill adds a rationale sentence explaining why that particular skill needs plan mode off (commits, PR creation, file writes, etc.).

The `plugin-creator` change in `agentic-plugin-dev` was more substantive. The prior "Plan Mode Guard" section was a blocking pattern: it detected plan mode and then instructed the user to exit manually rather than doing so programmatically. This created a friction point every time a user invoked plugin scaffolding from plan mode. The refactored Step 0 follows the same self-exit pattern used by the git-agent skills, and `ExitPlanMode` was added to the skill's `allowed-tools` frontmatter (in alphabetical order) to ensure the tool is available without a permission prompt.

The step renumbering in `plugin-creator` was necessary because the old "Plan Mode Guard" occupied the Step 0 position but was not a numbered step in the workflow. After the refactor, the disambiguation logic (formerly an unnumbered Step 0) becomes the first numbered step, and all subsequent steps shift by one.

The version bumps reflect the change classification: the four git-agent skills received a patch bump (no behavioral change, instruction clarity only) while `agentic-plugin-dev` received a minor bump (new `ExitPlanMode` capability added to the allowed-tools list, enabling a workflow that previously required manual user action).

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `44dc02f` | 2026-05-17 | docs(sweep): mark 18 completed plans as artifact and generate initial docs |
| `a7466d4` | 2026-05-13 | fix: document deferred-tool bootstrap for ExitPlanMode across all skills |
| `c15082d` | 2026-05-07 | fix(plugins): improve skill activation, discoverability, and README sync (#95) |

<!-- generated:end -->

## References

- Plan: [conditional-exit-plan-mode.md](plans/conditional-exit-plan-mode.md)
