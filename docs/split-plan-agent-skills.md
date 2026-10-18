# Split the five monolithic plan-agent skills into progressively-disclosed cores

> Splits build, finalize-plan, documenting-plans, plan-status, and setup-sites from single SKILL.md files (10,776 words total) into cores under 600 words each plus per-topic reference files, reducing always-paid context by 68%.

<!-- generated:start -->

**Status:** Shipped 2026-07-27  **Plan:** [split-plan-agent-skills.md](plans/split-plan-agent-skills.md)
**Type:** refactor

## What shipped

- Wrote `tests/plugins/test-progressive-disclosure.sh` — asserts each SKILL.md core is under 600 words (Python counter, locale-independent), has at least one `references/*.md`, every reference file on disk is linked from its core (no orphans), and every referenced path resolves to a file (no dangling links); wired into `.github/workflows/check-plugin-versions.yml`.
- Split `kit/plugins/plan-agent/skills/build/SKILL.md` into a core plus `references/invocation.md`, `references/resolve-plan.md`, `references/author-plan-chain.md`, and `references/completion-gates.md`; kept the re-render subroutine inline (called by every step).
- Split `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` into a core plus `references/resolve-and-modes.md`, `references/sweep-mode.md`, `references/evidence-analysis.md`, and `references/write-completions.md`.
- Split `kit/plugins/plan-agent/skills/documenting-plans/SKILL.md` into a core plus `references/resolve-and-preconditions.md`, `references/gather-evidence.md`, and `references/doc-template.md`; deleted the hand-maintained Table of Contents.
- Split `kit/plugins/plan-agent/skills/plan-status/SKILL.md` into a core plus `references/single-file-flow.md`, `references/bulk-mode.md`, and `references/type-classification.md`; deleted the hand-maintained Table of Contents.
- Split `kit/plugins/plan-agent/skills/setup-sites/SKILL.md` into a core plus `references/preflight.md`, `references/scaffold.md`, and `references/enable-and-verify.md`.
- Updated `tests/plugins/test-build-skill.sh`, `tests/plugins/test-finalize-all-flag.sh`, and `tests/plugins/test-setup-sites.sh` to resolve assertions across the split files.
- Bumped plan-agent to `7.6.0` in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Skill core | Modified |
| `kit/plugins/plan-agent/skills/build/references/` | Reference files (4) | Created |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Skill core | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/references/` | Reference files (4) | Created |
| `kit/plugins/plan-agent/skills/documenting-plans/SKILL.md` | Skill core | Modified |
| `kit/plugins/plan-agent/skills/documenting-plans/references/` | Reference files (3) | Created |
| `kit/plugins/plan-agent/skills/plan-status/SKILL.md` | Skill core | Modified |
| `kit/plugins/plan-agent/skills/plan-status/references/` | Reference files (3) | Created |
| `kit/plugins/plan-agent/skills/setup-sites/SKILL.md` | Skill core | Modified |
| `kit/plugins/plan-agent/skills/setup-sites/references/` | Reference files (3) | Created |
| `tests/plugins/test-progressive-disclosure.sh` | Objective test | Created |
| `tests/plugins/test-build-skill.sh` | Behavior test | Modified |
| `tests/plugins/test-finalize-all-flag.sh` | Behavior test | Modified |
| `tests/plugins/test-setup-sites.sh` | Behavior test | Modified |
| `.github/workflows/check-plugin-versions.yml` | CI configuration | Modified |
| `.claude-plugin/marketplace.json` | Marketplace version | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release notes | Modified |

## How it works

A SKILL.md body is paid in full whenever the skill triggers — there is no partial load. The five skills totalled 10,776 words: `build` (2,907), `finalize-plan` (2,764), `documenting-plans` (1,897), `plan-status` (1,681), `setup-sites` (1,527). An ordinary `/plan-agent:build docs/plans/x.md` call paid for `build`'s entire Step 1b no-plan chain (60 lines) and three completion gate sections (80 lines) even though neither fires on a normal invocation.

The split follows the pattern already shipping in `implementation-plan/`: a core holding trigger, arguments, and step names, with mechanics in per-topic `references/*.md` files that the model fetches at the step that needs them. Content moved verbatim — the split is a relocation, not a rewrite. Each moved section is replaced in the core with a named step line linking its reference file.

The `test-progressive-disclosure.sh` objective test was written before any split, so each intermediate step had a concrete pass/fail: failing first proves the test can detect a monolithic skill, and passing after proves the split landed correctly. The test uses Python word counting rather than `wc -w` because `wc -w` is locale-dependent on files with multibyte characters — a ~20-word swing that can pass on a developer machine and fail on a CI runner.

Three existing behavior tests groped the skill bodies by path. They were updated to search both the core and its reference files for the owning heading, keeping every assertion phrase unchanged — a dropped rule still fails, a moved rule still passes.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `67ab9a1` | 2026-08-19 | docs: sync README plugin table with memory-tools 4.3.0 (#588) |

<!-- generated:end -->

## References

- Plan: [split-plan-agent-skills.md](plans/split-plan-agent-skills.md)
