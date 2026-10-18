# Create the build-feature skill — feature docs that split into plans

> Adds `plan-agent:build-feature`, a new skill that turns a feature idea into a team-readable feature doc ending in a recommended breakdown into dependency-ordered sub-feature plans with paste-ready implementation-plan prompts, without touching the proven build-proposal loop.

<!-- generated:start -->

**Status:** Shipped 2026-08-12  **Plan:** [create-build-feature-skill.md](plans/create-build-feature-skill.md)
**Type:** feature

## What shipped

- Added `kit/plugins/plan-agent/skills/build-feature/SKILL.md` — the verbatim plan-mode guard, a Tier 0 scale-down gate (small/clear features route straight to `/plan-agent:implementation-plan`), frame-and-confirm gate, tiered parallel research fan-out, facts-vs-decisions separation, and dual-deliverable convergence on a feature doc + per-sub-feature saved prompts.
- Added `kit/plugins/plan-agent/skills/build-feature/references/feature-doc-shape.md` — the canonical section order (frontmatter, context, problem and users, goals, scope, UX/accessibility notes, risks, sub-feature breakdown, next step) with the breakdown-entry format and paste-ready prompt template.
- Added `tests/plugins/test-build-feature.sh` asserting the SKILL.md frontmatter contract, allowed-tools set, three-part description budget, references file, marketplace registration, dual-deliverable paths, and Tier 0 routing line.
- Extended `tests/plugins/test-exitplanmode-guard.sh` with the new SKILL.md path.
- Updated `kit/plugins/plan-agent/README.md` with a components-table row and a build-feature section.
- Bumped `plan-agent` to `9.2.0` in `.claude-plugin/marketplace.json`.
- `build-proposal` shipped byte-identical to `main`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/plan-agent/skills/build-feature/SKILL.md` | Skill instructions | Created |
| `kit/plugins/plan-agent/skills/build-feature/references/feature-doc-shape.md` | Feature doc shape reference | Created |
| `tests/plugins/test-build-feature.sh` | Smoke test | Created |
| `tests/plugins/test-exitplanmode-guard.sh` | Guard whitelist | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin documentation | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release notes | Modified |
| `.claude-plugin/marketplace.json` | Marketplace version | Modified |

## How it works

`build-feature` reuses `build-proposal`'s proven loop shape (tier triage, frame-and-confirm gate, parallel research fan-out, facts-vs-decisions separation, recommendation-first questions) but converges on a different deliverable. A proposal answers "should we?"; a feature doc answers "what are we building, and how does it split into plans?"

The sub-plan breakdown is recommend-only: the skill writes paste-ready `/plan-agent:implementation-plan` prompts for each sub-feature but never invokes plan generation on the user's behalf. Prompts are written at convergence only, via the prompt skill's standard path, avoiding churn on each research round.

The feature doc is written to the resolved features directory (`planAgent.featuresDirectory` via settings precedence, falling back to `${PWD}/docs/features/`). Each sub-feature entry includes a rationale, an S/M/L size estimate, its dependency order, and a paste-ready planning prompt.

## How to use it

```
/plan-agent:build-feature "real-time collaboration for the editor"
```

Or just describe a feature idea in natural language — the skill recognizes "feature doc" and "break this feature into plans" as activation phrases.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `67ab9a1` | 2026-08-19 | docs: sync README plugin table with memory-tools 4.3.0 (#588) |

<!-- generated:end -->

## References

- Plan: [create-build-feature-skill.md](plans/create-build-feature-skill.md)
