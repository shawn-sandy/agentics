# Add "agentic" as a trigger keyword across plan-interview skills

> Extends all four plan-interview skills, marketplace tags, plugin keywords, and README examples to recognise "agentic" as an activation keyword so phrasings like "stress test my agentic plan" reliably match (v1.14.3).

<!-- generated:start -->

**Status:** Shipped 2026-05-07  **Plan:** [add-agentic-trigger-to-plan-interview-skills.md](plans/add-agentic-trigger-to-plan-interview-skills.md)
**Type:** artifact

## What shipped

- Renamed the plan file from the auto-generated `review-the-triggers-to-quiet-orbit.md` to `add-agentic-trigger-to-plan-interview-skills.md` as a first commit step, per plan-hygiene rules.
- Added "agentic" as an activation keyword to all four skill descriptions: `plan-interview`, `deep-grill`, `plan-status`, and `documenting-plans` (purely additive — no existing trigger keywords were removed).
- Updated marketplace tags for the `plan-interview` entry in `.claude-plugin/marketplace.json`, appending `"agentic"` to the `tags` array.
- Updated `kit/plugins/plan-interview/.claude-plugin/plugin.json` to append `"agentic"` to the `keywords` array.
- Added one "agentic plan" example phrase to each of the three trigger blocks in `kit/plugins/plan-interview/README.md` (lines covering `plan-interview`, `deep-grill`, and `plan-status`).
- Bumped the plugin version from `1.14.2` to `1.14.3` (PATCH — metadata/keyword addition only) in `marketplace.json` and added a `[1.14.3] - 2026-04-20` CHANGELOG entry. (See CHANGELOG citation below.)

> CHANGELOG citation — `kit/plugins/plan-interview/CHANGELOG.md`, `## [1.14.3] - 2026-04-20`: "Accept 'agentic' as an activation trigger across the `plan-interview`, `deep-grill`, `plan-status`, and `documenting-plans` skills so phrasings like 'stress test my agentic plan' or 'document my agentic plan' reliably match. Also added 'agentic' to the marketplace tags, plugin keywords, and README trigger examples."

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/plan-interview/skills/plan-interview/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-interview/skills/deep-grill/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-interview/skills/plan-status/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-interview/skills/documenting-plans/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-interview/.claude-plugin/plugin.json` | Plugin manifest | Modified |
| `kit/plugins/plan-interview/README.md` | Plugin README | Modified |
| `kit/plugins/plan-interview/CHANGELOG.md` | Version history | Modified |
| `.claude-plugin/marketplace.json` | Marketplace entry | Modified |
| `docs/plans/add-agentic-trigger-to-plan-interview-skills.md` | Plan file (renamed) | Modified |

## How it works

Prior to this change, "agentic" appeared only in the repository URL (`shawn-sandy/agentics`) and the marketplace name (`agentics-kit`). None of the four skills recognised it as a trigger keyword, so natural user phrasings like "stress test my agentic plan" or "check my agentic plan status" could fail to activate the correct skill.

The fix is purely additive: each skill's YAML `description` field was extended with a parenthetical `(or agentic plan)` clause or an example phrase that surfaces the word "agentic." Claude Code's skill-matching logic reads these descriptions at activation time, so the additional phrase widens the vocabulary without touching any execution steps or removing existing triggers.

For `plan-interview`, the description was amended to include "agentic plans and agentic workflows" alongside the existing stress-test and interview phrasings. The `deep-grill` skill gained the example `"deep grill my agentic plan"`. The `plan-status` skill's exclusion clause ("not for stress-testing") was preserved intact while the inclusion side was extended to mention agentic plans. The `documenting-plans` skill received `"(including agentic plans)"` after "completed plan file" and gained `"document my agentic plan"` as an additional example phrase.

The marketplace `tags` array for the `plan-interview` entry in `.claude-plugin/marketplace.json` was updated from `["planning", "interview", "stress-test", "architecture"]` to include `"agentic"`. The `keywords` array in `plugin.json` received the same addition. These metadata fields improve plugin discoverability in marketplace search.

Three README trigger blocks (one per skill, excluding `documenting-plans` which lives in a separate section) each gained one new example phrase: `Stress-test my agentic plan`, `Deep grill my agentic plan`, and `Check the status of my agentic plan`. This keeps the documentation aligned with the extended matching vocabulary.

The version bump from `1.14.2` to `1.14.3` was classified as PATCH, consistent with the immediately preceding `1.14.2` change that added the "stress test" (with space) variant — both are keyword additions with no change to skill execution behaviour.

## How to use it

The change is transparent to users — existing invocations continue to work. The following phrasings now additionally activate their respective skills:

**`plan-interview` skill** — activated by phrasings such as:
- "Stress test my agentic plan"
- "Interview my agentic plan"

**`deep-grill` skill** — activated by phrasings such as:
- "Deep grill my agentic plan"

**`plan-status` skill** — activated by phrasings such as:
- "Check the status of my agentic plan"

**`documenting-plans` skill** — activated by phrasings such as:
- "Document my agentic plan"
- "Write docs for this agentic plan"

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `c15082d` | 2026-05-07 | fix(plugins): improve skill activation, discoverability, and README sync (#95) |

<!-- generated:end -->

## References

- Plan: [add-agentic-trigger-to-plan-interview-skills.md](plans/add-agentic-trigger-to-plan-interview-skills.md)
- Related docs: [add-deep-grill-step-plan-interview.md](add-deep-grill-step-plan-interview.md), [add-plan-status-skill-to-plan-interview.md](add-plan-status-skill-to-plan-interview.md), [add-allowed-tools-recommendation-to-plan-interview.md](add-allowed-tools-recommendation-to-plan-interview.md)
