# Stop paying 10,776 words for guidance nobody reads yet

> Splits the five monolithic plan-agent skills — build, finalize-plan, documenting-plans, plan-status, setup-sites — into small cores under 600 words holding trigger, arguments, and step names, with mechanics moved to per-topic reference files loaded on demand.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [split-plan-agent-skills](plans/split-plan-agent-skills.md)
**Type:** refactor

## What shipped

- Split `build/SKILL.md` (2,907 words) into a core plus `references/invocation.md`, `references/resolve-plan.md`, `references/author-plan-chain.md`, and `references/completion-gates.md`
- Split `finalize-plan/SKILL.md` (2,764 words) into a core plus `references/resolve-and-modes.md`, `references/sweep-mode.md`, `references/evidence-analysis.md`, and `references/write-completions.md`
- Split `documenting-plans/SKILL.md` (1,897 words) into a core plus `references/resolve-and-preconditions.md`, `references/gather-evidence.md`, and `references/doc-template.md`; deleted the hand-maintained Table of Contents
- Split `plan-status/SKILL.md` (1,681 words) into a core plus `references/single-file-flow.md`, `references/bulk-mode.md`, and `references/type-classification.md`; deleted its Table of Contents
- Split `setup-sites/SKILL.md` (1,527 words) into a core plus `references/preflight.md`, `references/scaffold.md`, and `references/enable-and-verify.md`
- Updated `tests/plugins/test-build-skill.sh`, `test-finalize-all-flag.sh`, and `test-setup-sites.sh` with extractors that resolve assertions across SKILL.md and its references
- Created `tests/plugins/test-progressive-disclosure.sh` (word ceiling, link integrity in both directions for all five skills)
- Added the new test to `.github/workflows/check-plugin-versions.yml`
- Bumped plan-agent to 7.6.0

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Skill core — step names, re-render subroutine, Steps 2 and 6 | Modified |
| `kit/plugins/plan-agent/skills/build/references/` | Four new reference files | Created |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Skill core | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/references/` | Four new reference files | Created |
| `kit/plugins/plan-agent/skills/documenting-plans/SKILL.md` | Skill core | Modified |
| `kit/plugins/plan-agent/skills/documenting-plans/references/` | Three new reference files | Created |
| `kit/plugins/plan-agent/skills/plan-status/SKILL.md` | Skill core | Modified |
| `kit/plugins/plan-agent/skills/plan-status/references/` | Three new reference files | Created |
| `kit/plugins/plan-agent/skills/setup-sites/SKILL.md` | Skill core | Modified |
| `kit/plugins/plan-agent/skills/setup-sites/references/` | Three new reference files | Created |
| `tests/plugins/test-progressive-disclosure.sh` | Smoke test — objective gate | Created |
| `tests/plugins/test-build-skill.sh` | Smoke test — updated extractors | Modified |
| `tests/plugins/test-finalize-all-flag.sh` | Smoke test — updated extractors | Modified |
| `tests/plugins/test-setup-sites.sh` | Smoke test — updated extractors | Modified |
| `.github/workflows/check-plugin-versions.yml` | CI — progressive disclosure step | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry — plan-agent 7.6.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release history — 7.6.0 entry | Modified |

## How it works

A SKILL.md body is paid in **full** whenever the skill triggers — there is no partial load. `build`'s Step 1b no-plan chain (~60 lines) fires only when no plan is named; every ordinary invocation pays for it and reads none of it. The three completion gates (~80 lines) matter only at the end of a run. The total across five skills was 10,776 words; the post-split cores sum to under 3,000.

The re-render subroutine in `build` (four lines called by every step) deliberately stayed in the core — pulling it out would trade one always-paid block for five on-demand fetches of the same lines. Every other section moved to the reference file matching its topic.

`test-progressive-disclosure.sh` enforces the objective in both directions: every `references/*.md` file on disk is linked from its SKILL.md (no orphans), and every `references/<name>.md` path named in a SKILL.md resolves to an existing file (no dangling links). The test also asserts each core is under 600 words using a locale-independent Python counter, since `wc -w` produces different counts for files with em dashes and arrows depending on the system locale — exactly the swing that separates a passing dev machine from a failing CI runner.

The three behavior-preservation tests (`test-build-skill.sh`, `test-finalize-all-flag.sh`, `test-setup-sites.sh`) were updated to search both SKILL.md and every `references/*.md` in the skill directory when looking for assertion phrases. All 18 checks in `test-build-skill.sh` pass unchanged — the phrases moved files, not meaning.

`frontmatter description:` values were left byte-identical. Any SKILL.md split that changes its own description changes the skill's trigger, and `tests/plugins/test-description-budget.sh` would catch it.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [split-plan-agent-skills](plans/split-plan-agent-skills.md)
