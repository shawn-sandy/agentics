# Create the build-feature skill — feature docs that split into plans

> Adds `/plan-agent:build-feature`, a new skill that turns a feature idea into a committed feature doc plus a recommended breakdown into dependency-ordered implementation plans.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [create-build-feature-skill.md](plans/create-build-feature-skill.md)
**Type:** feature

## What shipped

- Added `kit/plugins/plan-agent/skills/build-feature/SKILL.md` — a new model-invocable skill that conducts a tiered research loop and converges on a feature doc at `docs/features/<slug>.md`.
- Added `references/feature-doc-shape.md` — the canonical feature-doc section order and the sub-feature breakdown format with paste-ready `/plan-agent:implementation-plan` prompts.
- Added a Tier 0 scale-down gate: small, already-clear features route directly to `/plan-agent:implementation-plan` with no artifact written.
- Sub-feature prompts are written only at convergence via `plan-agent:prompt`, never per research round, and only to `<prompts-dir>/feature-<slug>-<sub-slug>.md`.
- `build-proposal` shipped byte-identical — the new skill is a sibling, not a modification.
- Bumped plan-agent to 9.2.0 in `.claude-plugin/marketplace.json`.
- Shipped `tests/plugins/test-build-feature.sh` as a structural smoke test and extended `tests/plugins/test-exitplanmode-guard.sh` to include the new SKILL.md.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build-feature/SKILL.md` | Build-feature skill | Created |
| `kit/plugins/plan-agent/skills/build-feature/references/feature-doc-shape.md` | Feature-doc canonical shape | Created |
| `.claude-plugin/marketplace.json` | Marketplace version bump | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 9.2.0 entry | Modified |
| `kit/plugins/plan-agent/README.md` | Components table + section | Modified |
| `tests/plugins/test-build-feature.sh` | Structural smoke test | Created |
| `tests/plugins/test-exitplanmode-guard.sh` | Guard whitelist | Modified |

## How it works

`build-feature` reuses `build-proposal`'s proven loop shape — tier triage, frame-and-confirm gate, parallel research fan-out with codebase Agent before first web fetch, facts-vs-decisions separation, recommendation-first questions — but converges on a different deliverable. A proposal answers "should we?"; a feature doc answers "what are we building and how does it split into plans?"

The Tier 0 gate fires first: if the feature is already single-surface and clearly scoped, the skill routes directly to `/plan-agent:implementation-plan` and exits without writing a feature doc. This prevents a one-plan feature from going through a full ten-section document workflow.

For Tier 1 and Tier 2 runs, the feature doc ends with a sub-feature breakdown. Each sub-feature carries a rationale, an S/M/L size estimate, its dependency order, and a paste-ready `/plan-agent:implementation-plan` prompt. At convergence — and only at convergence, never per round — the skill delegates to `plan-agent:prompt` with explicit `--out` and `--answers-gathered` flags to write each saved prompt. This keeps intermediate rounds from producing stale prompt files when sub-features merge or split.

The features directory resolves via the `planAgent.featuresDirectory` settings key, falling back to `${PWD}/docs/features/`, mirroring how plans and prompts directories already resolve.

## How to use it

Activated by trigger phrases including "feature doc" and "break this feature into plans".

```
/plan-agent:build-feature "user authentication via OAuth"
/plan-agent:build-feature "redesign the settings page" --tier 1
/plan-agent:build-feature --dir docs/features/auth
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `43d18eec` | 2026-10-31 | fix(plan-agent,social-media-tools): remove model pins from skills (9.22.0, 2.25.0) (#668) |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [create-build-feature-skill.md](plans/create-build-feature-skill.md)
