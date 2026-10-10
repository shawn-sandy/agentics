# Create the build-feature skill

> Teams get a `/plan-agent:build-feature` command that turns a feature idea into a committed feature doc plus a recommended split into smaller, dependency-ordered plans — without touching the proven build-proposal loop. Done means plan-agent loads at 9.2.0 and the new skill's smoke test passes.

<!-- generated:start -->

**Status:** Shipped 2026-08-12  **Plan:** [create-build-feature-skill.md](plans/create-build-feature-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/plan-agent/skills/build-feature/SKILL.md` with the full workflow: plan-mode guard, Tier 0 scale-down gate routing already-clear features to `implementation-plan`, frame-and-confirm gate, tiered parallel research fan-out, facts-vs-decisions separation, and convergence on a dual deliverable.
- Created `kit/plugins/plan-agent/skills/build-feature/references/feature-doc-shape.md` with the canonical feature-doc section order and the sub-feature breakdown format, keeping the SKILL.md body under 500 lines.
- Bumped plan-agent from 9.1.1 to 9.2.0 in `.claude-plugin/marketplace.json` and added `build-feature` to the plugin description's skill list.
- Added a 9.2.0 CHANGELOG entry and a `build-feature` section to `README.md`.
- Created `tests/plugins/test-build-feature.sh` mirroring `test-build-proposal.sh`.
- Extended `tests/plugins/test-exitplanmode-guard.sh` to include the new SKILL.md in its whitelist.
- Left `build-proposal` byte-identical to `main` throughout (verified via `git diff`).

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/plan-agent/skills/build-feature/SKILL.md` | Build-feature skill workflow | Created |
| `kit/plugins/plan-agent/skills/build-feature/references/feature-doc-shape.md` | Canonical feature-doc section order | Created |
| `.claude-plugin/marketplace.json` | plan-agent bumped to 9.2.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 9.2.0 entry | Modified |
| `kit/plugins/plan-agent/README.md` | Components table row and build-feature section | Modified |
| `tests/plugins/test-build-feature.sh` | Structural smoke test | Created |
| `tests/plugins/test-exitplanmode-guard.sh` | build-feature SKILL.md added to whitelist | Modified |

## How it works

The skill was built as a sibling to `build-proposal`, not a replacement. The exploration that resolved this decision found that `build-proposal` is load-bearing for three other skills — `build` falls through to direct plan authoring only when the proposal stage writes nothing, `implementation-plan` has a dedicated `--from-prompt` mode for proposal output, and `prompt` owns a `proposal` type with sha-guarded in-place rewrites. A repurpose would have been a MAJOR bump and would have broken that chain.

`build-feature` reuses the proven loop shape from `build-proposal` — tier triage, frame-and-confirm gate, parallel research fan-out with a codebase `Agent` in flight before the first web fetch, facts-vs-decisions separation — but converges on a different question. A proposal answers "should we?"; a feature doc answers "what are we building, and how does it split into plans?"

The Tier 0 scale-down gate is the key usability guard. A feature that is already small and clear — a single surface, no open design questions — routes directly to `/plan-agent:implementation-plan` with a clear message and no feature doc written. This prevents a one-plan feature from generating a ten-section document.

The dual deliverable at convergence is: (1) a feature doc written to the resolved features directory (`planAgent.featuresDirectory` via settings, falling back to `${PWD}/docs/features/`), ending with a Sub-feature breakdown section where each sub-feature carries rationale, an S/M/L size, dependency order, and a paste-ready `/plan-agent:implementation-plan` prompt; and (2) per-sub-feature saved prompts at `<prompts-dir>/feature-<slug>-<sub-slug>.md`, authored by delegating to `plan-agent:prompt` through its standard path. Saved prompts are written only at convergence — never per round — to avoid churning stale files when sub-features merge or split mid-loop.

The `feature-doc-shape.md` reference file carries the canonical section order and breakdown-entry format, mirroring how `build-proposal` externalizes its artifact shape. This keeps the SKILL.md body under the 500-line budget.

## How to use it

```bash
# Load the plugin
claude --plugin-dir kit/plugins/plan-agent

# Turn a feature idea into a feature doc
/plan-agent:build-feature "Add real-time collaboration to the plan editor"

# Scale down directly to a plan for a small, already-clear feature
/plan-agent:build-feature "Add a --dry-run flag to sync-rules" --tier 0

# Specify a custom output directory
/plan-agent:build-feature "Redesign the plans gallery" --dir docs/features/2026
```

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| 0fd7b67 | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |

<!-- generated:end -->

## References

- Plan: [create-build-feature-skill.md](plans/create-build-feature-skill.md)
