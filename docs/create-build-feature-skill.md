# Create the build-feature skill — feature docs that split into plans

> Teams get a /plan-agent:build-feature command that turns a feature idea into a committed feature doc plus a recommended split into smaller, dependency-ordere...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [create-build-feature-skill.md](plans/create-build-feature-skill.md)
**Type:** feature

## What shipped

- Scaffold kit/plugins/plan-agent/skills/build-feature/SKILL.md with the frontmatter contract: `name: build-feature`, `...
- Author the SKILL.md workflow body: the verbatim plan-mode guard as the first step, then a right-sizing triage with a...
- Specify the dual-deliverable convergence in the SKILL.md body: the feature doc ends with a Sub-feature breakdown sect...
- Write references/feature-doc-shape.md: the canonical feature-doc section order (frontmatter, title and framing note,...
- Register and document the skill: bump plan-agent to 9.2.0 in .claude-plugin/marketplace.json and add build-feature to...
- Add tests/plugins/test-build-feature.sh mirroring test-build-proposal.sh — assert the SKILL.md frontmatter contract,...

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build-feature/SKILL.md` | the skill: frontmatter contract, workflow, dual-deliverab... | Created |
| `kit/plugins/plan-agent/skills/build-feature/references/feature-doc-shape.md` | canonical feature-doc section order and the sub-feature b... | Created |
| `.claude-plugin/marketplace.json` | bump plan-agent 9.1.1 → 9.2.0; add build-feature to the d... | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 9.2.0 entry | Modified |
| `kit/plugins/plan-agent/README.md` | components-table row and a build-feature section mirrorin... | Modified |
| `tests/plugins/test-build-feature.sh` | structural smoke test mirroring test-build-proposal.sh | Created |
| `tests/plugins/test-exitplanmode-guard.sh` | add the new SKILL.md to the guard whitelist | Modified |

## How it works

Add a new `build-feature` skill to the plan-agent plugin that turns a feature idea into a team-readable feature doc at `docs/features/<slug>.md` — covering context, users, goals, scope, and risks — ending in a recommended breakdown into smaller sub-feature plans, each with a paste-ready `/plan-agent:implementation-plan` prompt and a saved prompt for the planning layer.

The request started as "refactor build-proposal to create a feature rather than a proposal," with the adapt-vs-new decision explicitly left open. Exploration settled it: `build-proposal` is load-bearing for three other skills — `build` Step 1b falls through to direct plan authoring only when the proposal stage writes nothing, `implementation-plan` ships a dedicated `--from-prompt` mode for its output, and `prompt` owns a caller-driven `proposal` type with sha-guarded in-place rewrites. Repurposi...

The implementation proceeded through these steps: Scaffold kit/plugins/plan-agent/skills/build-feature/SKILL.md with the frontmatter contract: `name: build-feature`, `...; Author the SKILL.md workflow body: the verbatim plan-mode guard as the first step, then a right-sizing triage with a ...; Specify the dual-deliverable convergence in the SKILL.md body: the feature doc ends with a Sub-feature breakdown sect...; Write references/feature-doc-shape.md: the canonical feature-doc section order (frontmatter, title and framing note, ...; Register and document the skill: bump plan-agent to 9.2.0 in .claude-plugin/marketplace.json and add build-feature to....

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates ( |

<!-- generated:end -->

## References

- Plan: [create-build-feature-skill.md](plans/create-build-feature-skill.md)
- Issue: https://github.com/shawn-sandy/agentics/issues/546
