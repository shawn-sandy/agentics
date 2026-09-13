# Create the build-feature skill — feature docs that split into plans

> Adds a `build-feature` skill to plan-agent that turns a feature idea into a team-readable feature doc at `docs/features/<slug>.md` ending in a dependency-ordered breakdown into sub-feature plans.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [create-build-feature-skill.md](plans/create-build-feature-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/plan-agent/skills/build-feature/SKILL.md` with the full workflow: plan-mode guard, Tier 0 scale-down gate, frame-and-confirm, tiered parallel research, facts-vs-decisions separation, dual-deliverable convergence.
- Created `kit/plugins/plan-agent/skills/build-feature/references/feature-doc-shape.md` — the canonical feature-doc section order and sub-feature breakdown format, mirroring the way `build-proposal` keeps its artifact shape in a reference file.
- Bumped plan-agent from 9.1.1 to 9.2.0 in `.claude-plugin/marketplace.json`.
- Added the 9.2.0 CHANGELOG entry and updated `kit/plugins/plan-agent/README.md` with a components-table row and a `build-feature` section.
- Added `tests/plugins/test-build-feature.sh` (structural smoke test) and added the new skill path to the whitelist in `tests/plugins/test-exitplanmode-guard.sh`.
- Post-ship (commit `daa72b9`, 2026-08-23): the skill was extended to include user stories with acceptance criteria, goals with measured baselines, release and rollout planning, and an optional artifact-publish step — the description and argument-hint updated to match.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build-feature/SKILL.md` | Feature-doc workflow skill | Created |
| `kit/plugins/plan-agent/skills/build-feature/references/feature-doc-shape.md` | Canonical feature-doc section order and breakdown format | Created |
| `kit/plugins/plan-agent/CHANGELOG.md` | 9.2.0 entry | Modified |
| `kit/plugins/plan-agent/README.md` | Components table row and build-feature section | Modified |
| `.claude-plugin/marketplace.json` | plan-agent bumped to 9.2.0 | Modified |
| `tests/plugins/test-build-feature.sh` | Structural smoke test | Created |
| `tests/plugins/test-exitplanmode-guard.sh` | New skill path added to whitelist | Modified |

## How it works

The plan resolved an adapt-vs-new decision before writing any code: `build-proposal` is load-bearing for three other skills (`build`, `implementation-plan`, `prompt`), so repurposing it would have been a MAJOR break. The new `build-feature` skill is a sibling using the same loop shape — tier triage, frame-and-confirm, parallel research fan-out, facts-vs-decisions separation — but converges on a different deliverable. A proposal answers "should we?"; a feature doc answers "what are we building and how does it split into plans?"

The Tier 0 gate is the most important routing decision. A single-surface, already-clear feature routes straight to `/plan-agent:implementation-plan` with no feature doc written — the skill stops over-engineering clear cases the same way `build-proposal` does.

For Tier 1 and 2 features the skill converges on two deliverables: the feature doc at `<features-dir>/<slug>.md` and per-sub-feature saved prompts at `<prompts-dir>/feature-<slug>-<sub-slug>.md`. The prompts are written only at convergence (never per research round) by delegating to `plan-agent:prompt` with an explicit `--out` path. This is recommend-only: the skill names each sub-feature and supplies a paste-ready `/plan-agent:implementation-plan` prompt, but it never generates the actual plans on the user's behalf.

`references/feature-doc-shape.md` holds the canonical section order (frontmatter, title, context, problem and users, goals and success metrics, scope in/out, UX and accessibility notes, risks, sub-feature breakdown, next step) so the `SKILL.md` body stays under the 500-line budget. The sub-feature breakdown entry format and paste-ready prompt template live there as well.

The smoke test asserts the frontmatter contract (name, model, no `disable-model-invocation`), the allowed-tools set, the three-part ≤200-char description, the references file, and the key body requirements: `docs/features/`, the `feature-<slug>-<sub-slug>.md` prompt path, the Tier 0 routing line, and marketplace registration above `origin/main`. The guard test confirms the new `SKILL.md` is in the whitelist and carries the verbatim plan-mode guard.

Since the initial 9.2.0 ship the skill grew further: commit `daa72b9` (2026-08-23) added product content, user stories, acceptance criteria, metrics, release and rollout guidance, and an optional publish-to-artifact step.

## How to use it

Available after loading `plan-agent`. Argument hint: `<feature idea> [--dir <path>] [--tier 0|1|2] [--publish|--no-publish]`.

Activation triggers: "feature doc", "break this feature into plans", "help me scope this feature". These are disjoint from `build-proposal`'s "should we?" triggers by design.

Examples:
- `/plan-agent:build-feature add dark mode to the dashboard` — full Tier 2 feature doc
- `/plan-agent:build-feature rename all API endpoints --tier 0` — routes straight to `implementation-plan`
- `/plan-agent:build-feature add OAuth login --publish` — publishes the finished doc as a claude.ai artifact

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |
| `0fd7b67` | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |
| `daa72b9` | 2026-08-23 | build-feature: add product content, stories, metrics, rollout, and publishing (#593) |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |

<!-- generated:end -->

## References

- Plan: [create-build-feature-skill.md](plans/create-build-feature-skill.md)
