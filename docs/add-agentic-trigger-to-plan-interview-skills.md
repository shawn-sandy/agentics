# Add "agentic" as a trigger keyword across plan-interview skills

> Expands plan-interview activation to accept natural phrasings containing "agentic" (e.g., "stress test my agentic plan") across all four skills, marketplace tags, plugin keywords, and README examples.

<!-- generated:start -->

**Status:** Shipped 2026-04-20 **Plan:** [add-agentic-trigger-to-plan-interview-skills.md](plans/add-agentic-trigger-to-plan-interview-skills.md)
**Type:** feature

## What shipped

- Added "(or agentic plan)" trigger hint to the descriptions of all four `plan-interview` skills — `plan-interview`, `deep-grill`, `plan-status`, and `documenting-plans` — so phrasings like "stress test my agentic plan" and "document my agentic plan" reliably activate the matching skill.
- Appended `"agentic"` to the `plan-interview` entry's `tags` array in `.claude-plugin/marketplace.json` and to the `keywords` array in `kit/plugins/plan-interview/.claude-plugin/plugin.json`.
- Added one "agentic" example to each trigger block in the plugin `README.md` (`Stress-test my agentic plan`, `Deep grill my agentic plan`, `Check the status of my agentic plan`).
- Bumped the plugin from v1.14.2 → v1.14.3 (PATCH), then refined the phrasing in two follow-up patches (v1.14.4 and v1.14.5) — settling on the terse `(or agentic plan)` form.

> See [CHANGELOG §1.14.3–1.14.5](../kit/plugins/plan-interview/CHANGELOG.md) for the authoritative feature list.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-interview/skills/plan-interview/SKILL.md` | Skill instructions — plan-interview | Modified |
| `kit/plugins/plan-interview/skills/deep-grill/SKILL.md` | Skill instructions — deep-grill | Modified |
| `kit/plugins/plan-interview/skills/plan-status/SKILL.md` | Skill instructions — plan-status | Modified |
| `kit/plugins/plan-interview/skills/documenting-plans/SKILL.md` | Skill instructions — documenting-plans | Modified |
| `kit/plugins/plan-interview/.claude-plugin/plugin.json` | Plugin manifest | Modified |
| `kit/plugins/plan-interview/CHANGELOG.md` | Release notes | Modified |
| `kit/plugins/plan-interview/README.md` | User-facing documentation | Modified |
| `.claude-plugin/marketplace.json` | Marketplace registry | Modified |
| `docs/plans/add-agentic-trigger-to-plan-interview-skills.md` | Plan file (renamed from random name) | Modified |

## How it works

Prior to this change, the `plan-interview` skill's description mentioned "stress-test" and "stress test" (the space form was added in v1.14.2) but said nothing about "agentic." A user saying "stress test my agentic plan" might not reliably match the description because the trigger model looks for semantically relevant keywords.

The first implementation (v1.14.3) inserted verbose phrases like "including agentic plans and agentic workflows" into all four skill descriptions. Smoke testing revealed this language made the descriptions read as though the skills *only* target agentic plans, causing confusion. A follow-up patch (v1.14.4) tightened the wording to mark "agentic" as an optional qualifier. The final form (v1.14.5) simplified further to `(or agentic plan)` — a concise parenthetical that signals optional trigger expansion without changing semantics.

The marketplace `tags` and plugin `keywords` arrays receive `"agentic"` purely for discoverability in plugin search, not for skill activation logic.

The `README.md` trigger blocks (lines ~274–297) each gained one example showing the new phrasing so users can see the supported vocabulary at a glance.

The plan file itself was renamed from the auto-generated `review-the-triggers-to-quiet-orbit.md` to `add-agentic-trigger-to-plan-interview-skills.md` as Step 0 of implementation, per `.claude/rules/plan-hygiene.md`.

## How to use it

The change is transparent — existing invocations are unaffected. The new phrasings that now work:

| Skill | New trigger example |
| ----- | ------------------- |
| `plan-interview` | "Stress-test my agentic plan" |
| `deep-grill` | "Deep grill my agentic plan" |
| `plan-status` | "Check the status of my agentic plan" |
| `documenting-plans` | "Document my agentic plan" |

All prior activation phrases continue to work.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `80dd2a3` | 2026-04-20 | fix(kit/plugins/plan-interview): accept "agentic" as activation trigger (1.14.3) |
| `e78868d` | 2026-04-20 | fix(kit/plugins/plan-interview): make "agentic" trigger keyword optional (1.14.4) |
| `61b79a6` | 2026-04-20 | fix(kit/plugins/plan-interview): simplify "(or agentic plan)" trigger phrasing (1.14.5) |
| `8adddf0` | 2026-04-20 | Update docs/plans/add-agentic-trigger-to-plan-interview-skills.md |

<!-- generated:end -->

## References

- Plan: [add-agentic-trigger-to-plan-interview-skills.md](plans/add-agentic-trigger-to-plan-interview-skills.md)
- Changelog: [plan-interview CHANGELOG §1.14.3](../kit/plugins/plan-interview/CHANGELOG.md)
- Related docs: [add-plan-interview-exit-hook.md](add-plan-interview-exit-hook.md)
