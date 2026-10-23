# Create the build-feature skill

> Add a `build-feature` skill to plan-agent that turns a feature idea into a team-readable feature doc with a sized sub-feature breakdown and paste-ready planning prompts, without touching the existing build-proposal loop.

<!-- generated:start -->

**Status:** Shipped 2026-08-12 **Plan:** [create-build-feature-skill.md](plans/create-build-feature-skill.md)
**Type:** feature

## What shipped

- Added `kit/plugins/plan-agent/skills/build-feature/SKILL.md` — a new sibling to `build-proposal` that converges on a feature doc rather than a proposal
- Added `kit/plugins/plan-agent/skills/build-feature/references/feature-doc-shape.md` — canonical section order and sub-feature breakdown format
- Bumped plan-agent from 9.1.1 to 9.2.0 in `.claude-plugin/marketplace.json`
- Added a 9.2.0 CHANGELOG entry and updated README with the components table row and a `build-feature` section
- Added `tests/plugins/test-build-feature.sh` structural smoke test
- Updated `tests/plugins/test-exitplanmode-guard.sh` whitelist to include the new SKILL.md
- Left `build-proposal` byte-identical — no cross-skill changes

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build-feature/SKILL.md` | New skill | Created |
| `kit/plugins/plan-agent/skills/build-feature/references/feature-doc-shape.md` | Canonical doc shape | Created |
| `.claude-plugin/marketplace.json` | plan-agent bumped to 9.2.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 9.2.0 entry | Modified |
| `kit/plugins/plan-agent/README.md` | Components table and usage section | Modified |
| `tests/plugins/test-build-feature.sh` | Structural smoke test | Created |
| `tests/plugins/test-exitplanmode-guard.sh` | Whitelist updated | Modified |

## How it works

`build-proposal` answers "should we build this?" — it is load-bearing for three downstream skills (`build`, `implementation-plan`, and `prompt`) and cannot be repurposed without a MAJOR version bump. `build-feature` is a new sibling with a different seam: it answers "what are we building, and how does it split into plans?" The two skills share no activation phrases.

The skill reuses `build-proposal`'s proven loop shape — tier triage, frame-and-confirm gate, parallel research fan-out, facts-vs-decisions separation, recommendation-first questions — but converges on a different deliverable. A Tier 0 scale-down gate routes small, already-clear features straight to `/plan-agent:implementation-plan` with no feature doc or prompts written. Tier 1/2 runs produce both deliverables.

The first deliverable is a feature doc written to `docs/features/<slug>.md` (or the path resolved from `planAgent.featuresDirectory` in settings). The doc covers frontmatter, context, problem and users, goals and success metrics, scope in/out, UX and accessibility notes, risks, and a sub-feature breakdown — defined in full in `references/feature-doc-shape.md` so the SKILL.md body stays under 500 lines.

The second deliverable is per-sub-feature saved prompts written at `<prompts-dir>/feature-<slug>-<sub-slug>.md`, each authored by delegating to `plan-agent:prompt` through its standard authoring path with explicit `--out` and `--answers-gathered` flags. Prompts are written only once, at convergence, not per round. The skill never invokes `implementation-plan` itself on Tier 1/2 runs — the sub-plan generation stays user-initiated.

The plan-mode guard — "**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state." — appears verbatim as the skill's first step. `tests/plugins/test-exitplanmode-guard.sh` greps for the exact string in a fixed file list that was extended to include the new SKILL.md.

`build-proposal` shipped byte-identical. `git diff origin/main -- kit/plugins/plan-agent/skills/build-proposal/` prints nothing.

## How to use it

```bash
# Load the plugin locally
claude --plugin-dir kit/plugins/plan-agent
```

```text
# Scope a feature
/plan-agent:build-feature "add dark mode to the dashboard"

# With explicit tier and output directory
/plan-agent:build-feature "migrate auth to OAuth" --tier 1 --dir docs/features/
```

Tier 0 routes directly to `/plan-agent:implementation-plan` and writes nothing. Tier 1/2 writes a feature doc and one saved prompt per sub-feature.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |
| `0fd7b67` | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |
| `daa72b9` | 2026-08-23 | build-feature: add product content, stories, metrics, rollout, and publishing (#593) |
| `be304fd` | 2026-08-26 | feat(plan-agent): publish-hub — bundle a plan and its related HTML into one hub artifact (9.8.0) (#603) |

<!-- generated:end -->

## References

- Plan: [create-build-feature-skill.md](plans/create-build-feature-skill.md)
