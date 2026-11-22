# Stop paying 10,776 words for guidance nobody reads yet

> Five plan-agent skills billed 10,776 words of context every time they fired, and an ordinary run read maybe a quarter of it. This splits each into a core under 600 words holding trigger, arguments, and step names, with mechanics moved to `references/` files loaded on demand.

<!-- generated:start -->

**Status:** Shipped 2026-08-01 **Plan:** [split-plan-agent-skills.md](plans/split-plan-agent-skills.md)
**Type:** refactor

## What shipped

- Split `kit/plugins/plan-agent/skills/build/SKILL.md` into a core plus `references/invocation.md`, `references/resolve-plan.md`, `references/author-plan-chain.md`, and `references/completion-gates.md`; re-render subroutine kept in core (every step calls it).
- Split `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` into a core plus `references/resolve-and-modes.md`, `references/sweep-mode.md`, `references/evidence-analysis.md`, and `references/write-completions.md`.
- Split `kit/plugins/plan-agent/skills/documenting-plans/SKILL.md` into a core plus `references/resolve-and-preconditions.md`, `references/gather-evidence.md`, and `references/doc-template.md`; deleted hand-maintained `## Table of Contents`.
- Split `kit/plugins/plan-agent/skills/plan-status/SKILL.md` into a core plus `references/single-file-flow.md`, `references/bulk-mode.md`, and `references/type-classification.md`; deleted `## Table of Contents`.
- Split `kit/plugins/plan-agent/skills/setup-sites/SKILL.md` into a core plus `references/preflight.md`, `references/scaffold.md`, and `references/enable-and-verify.md`.
- Added `tests/plugins/test-progressive-disclosure.sh`: asserts each `SKILL.md` is under 600 words (Python word count, locale-independent), has at least one `references/*.md`, every reference file on disk is linked from its core (no orphans), and every `references/<name>.md` path in the core resolves to a file (no dangling links).
- Wired the new test into `.github/workflows/check-plugin-versions.yml`.
- Updated `tests/plugins/test-build-skill.sh`, `tests/plugins/test-finalize-all-flag.sh`, and `tests/plugins/test-setup-sites.sh` so section extractors resolve headings across `SKILL.md` and `references/`; all existing phrase assertions unchanged.
- Bumped plan-agent to 7.6.0.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Core under 600 words | Modified |
| `kit/plugins/plan-agent/skills/build/references/` | 4 reference files | Created |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Core under 600 words | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/references/` | 4 reference files | Created |
| `kit/plugins/plan-agent/skills/documenting-plans/SKILL.md` | Core under 600 words | Modified |
| `kit/plugins/plan-agent/skills/documenting-plans/references/` | 3 reference files | Created |
| `kit/plugins/plan-agent/skills/plan-status/SKILL.md` | Core under 600 words | Modified |
| `kit/plugins/plan-agent/skills/plan-status/references/` | 3 reference files | Created |
| `kit/plugins/plan-agent/skills/setup-sites/SKILL.md` | Core under 600 words | Modified |
| `kit/plugins/plan-agent/skills/setup-sites/references/` | 3 reference files | Created |
| `tests/plugins/test-progressive-disclosure.sh` | Objective verification test | Created |
| `tests/plugins/test-build-skill.sh` | Section extractors updated | Modified |
| `tests/plugins/test-finalize-all-flag.sh` | Section extractors updated | Modified |
| `tests/plugins/test-setup-sites.sh` | Section extractors updated | Modified |
| `.github/workflows/check-plugin-versions.yml` | Wire test-progressive-disclosure.sh | Modified |
| `.claude-plugin/marketplace.json` | plan-agent → 7.6.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 7.6.0 entry | Modified |

## How it works

**Always-paid body**: A `SKILL.md` body is loaded in full whenever the skill triggers — there is no partial load. `build`'s `## Step 1b — Author a plan first` (~60 lines) fires only on a no-plan invocation; every ordinary `build docs/plans/x.md` paid for all of it.

**Progressive disclosure**: Each core names the reference file a step needs; the model fetches it when the step runs. The in-repo precedent is `implementation-plan/`, which already ships this layout and says explicitly "read the full file when the step calls for it, not all up front."

**Objective gate**: `test-progressive-disclosure.sh` fails three independent ways — word ceiling exceeded, orphaned reference on disk, dangling link in core — with a tautology check verifying each failure mode independently.

**Behavior preserved**: All 18 `test-build-skill.sh` checks still assert the exact same contract phrases; the only change is that section extractors search `SKILL.md` and all `references/*.md` for the owning heading, rather than `SKILL.md` alone.

## How to use it

The changes are automatic — sessions loading plan-agent 7.6.0+ get the split skills. Each core names which reference to read and when; models using Claude Code 1.0.33+ load references on demand.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| — | 2026-08-01 | refactor(plan-agent): split five monolithic skills into cores plus references, add progressive-disclosure test (7.6.0) |

<!-- generated:end -->

## References

- Plan: [split-plan-agent-skills.md](plans/split-plan-agent-skills.md)
