# Create the build-feature skill — feature docs that split into plans

> Adds `build-feature` to plan-agent (9.2.0): a sibling skill to `build-proposal` that turns a feature idea into a team-readable feature doc and a recommended breakdown into dependency-ordered sub-feature plans.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [create-build-feature-skill.md](plans/create-build-feature-skill.md)
**Type:** feature

## What shipped

- Added `kit/plugins/plan-agent/skills/build-feature/SKILL.md` — a new skill with `model: claude-fable-5`, trigger phrases disjoint from `build-proposal`'s should-we loop, and a Tier 0 scale-down gate that routes small, already-clear features straight to `/plan-agent:implementation-plan` without writing a feature doc.
- Added `kit/plugins/plan-agent/skills/build-feature/references/feature-doc-shape.md` — the canonical section order and sub-feature breakdown format (kept in a reference file to hold the SKILL.md body under the 500-line budget).
- The skill delivers two outputs at convergence: a feature doc at `docs/features/<slug>.md` covering context, users, goals, scope, and risks; and per-sub-feature saved prompts at `<prompts-dir>/feature-<slug>-<sub-slug>.md` authored via `plan-agent:prompt`. Implementation-plan invocation is recommend-only — the skill never generates plans on the user's behalf on Tier 1/2 runs.
- Bumped plan-agent to 9.2.0 in `.claude-plugin/marketplace.json`.
- Added `tests/plugins/test-build-feature.sh` and updated `tests/plugins/test-exitplanmode-guard.sh` to include the new SKILL.md.
- `build-proposal` ships byte-identical to main.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build-feature/SKILL.md` | Skill instructions | Created |
| `kit/plugins/plan-agent/skills/build-feature/references/feature-doc-shape.md` | Canonical feature-doc section order | Created |
| `tests/plugins/test-build-feature.sh` | Structural smoke test | Created |
| `.claude-plugin/marketplace.json` | plan-agent bumped to 9.2.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 9.2.0 entry | Modified |
| `kit/plugins/plan-agent/README.md` | Components table row and build-feature section | Modified |
| `tests/plugins/test-exitplanmode-guard.sh` | New SKILL.md added to guard whitelist | Modified |

## How it works

The skill reuses `build-proposal`'s proven loop shape — tier triage, frame-and-confirm gate, parallel research fan-out, facts-vs-decisions separation, recommendation-first questions — but converges on a different deliverable. A proposal answers "should we?"; a feature doc answers "what are we building, and how does it split into plans?"

Right-sizing triage runs first. A Tier 0 answer routes straight to `/plan-agent:implementation-plan` (and the skill writes nothing else), keeping small, already-clear features from getting a 10-section feature doc.

On Tier 1/2, the skill frames the feature in one line and waits for confirmation before starting research. Codebase research runs via an `Agent` call before the first web fetch. Facts and decisions are separated; questions are posed recommendation-first.

At convergence the skill writes the feature doc to the resolved features directory (`planAgent.featuresDirectory` via settings precedence, falling back to `${PWD}/docs/features/`). The Sub-feature breakdown section lists each sub-feature with a rationale, an S/M/L size, its dependency order, and a paste-ready `/plan-agent:implementation-plan` prompt. Only once the breakdown is settled does the skill write the per-sub-feature saved prompts, delegating to `plan-agent:prompt` with explicit `--out` and `--answers-gathered` flags. This convergence-only write prevents churning N files mid-loop.

> See [CHANGELOG v9.2.0](../kit/plugins/plan-agent/CHANGELOG.md) for the authoritative feature list.

## How to use it

```
/plan-agent:build-feature <feature idea>                    # start a feature doc
/plan-agent:build-feature <feature idea> --tier 0           # force small-feature route
/plan-agent:build-feature <feature idea> --dir docs/features/my-area
```

The skill activates on descriptions like "feature doc", "build a feature for", or "break this feature into plans". It does not activate on "should we" phrasing — that routes to `build-proposal`.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `43d18ee` | 2026-10-31 | fix(plan-agent,social-media-tools): remove model pins from skills (9.22.0, 2.25.0) (#668) |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [create-build-feature-skill.md](plans/create-build-feature-skill.md)
- Related: [kit/plugins/plan-agent/CHANGELOG.md](../kit/plugins/plan-agent/CHANGELOG.md)
- Related: [kit/plugins/plan-agent/skills/build-proposal/SKILL.md](../kit/plugins/plan-agent/skills/build-proposal/SKILL.md) — the sibling skill this mirrors
