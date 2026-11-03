# Stop Paying 10,776 Words for Guidance Nobody Reads Yet

> Five plan-agent skills bill 10,776 words of context every time they fire, and an ordinary run reads maybe a quarter of it — Step 1b's 60-line no-plan contract is paid in full by every invocation that names a plan. The cost is invisible today because nothing measures it, so this ships the measurement alongside the fix and treats a behavioral regression as blocking even if every word count drops.

<!-- generated:start -->

**Status:** Shipped 2026-08-01  **Plan:** [split-plan-agent-skills.md](plans/split-plan-agent-skills.md)
**Type:** refactor

## What shipped

- Split five monolithic `plan-agent` SKILL.md files — `build`, `finalize-plan`, `documenting-plans`, `plan-status`, `setup-sites` — into small cores under 600 words each, with mechanics moved to `references/<topic>.md` files.
- Created 15 new reference files covering: `build` invocation, plan resolution, the no-plan chain, and completion gates; `finalize-plan` modes, sweep mode, evidence analysis, and write completions; `documenting-plans` resolution, evidence gathering, and the document template; `plan-status` single-file flow, bulk mode, and type classification; `setup-sites` preflight, scaffold, and enable-and-verify steps.
- Deleted both hand-maintained `## Table of Contents` sections from `documenting-plans` and `plan-status` (redundant with the linked step lists).
- Updated `tests/plugins/test-build-skill.sh`, `tests/plugins/test-finalize-all-flag.sh`, and `tests/plugins/test-setup-sites.sh` to resolve their assertions across SKILL.md and `references/*.md`, keeping all 18 `build` checks and every phrase assertion intact.
- Added `tests/plugins/test-progressive-disclosure.sh` asserting: cores under 600 words, at least one reference per skill, every linked reference resolves, no orphaned reference files.
- Wired the new test into `.github/workflows/check-plugin-versions.yml`.
- Bumped `plan-agent` from 7.5.0 to 7.6.0 and added a CHANGELOG entry naming all five split skills with before/after word counts.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Core — trigger, arguments, step names, re-render subroutine | Modified |
| `kit/plugins/plan-agent/skills/build/references/invocation.md` | Reference — command vs model activation, flag parsing, misparse note | Created |
| `kit/plugins/plan-agent/skills/build/references/resolve-plan.md` | Reference — exit-plan-mode, dirty-tree preflight, AskUserQuestion fallback | Created |
| `kit/plugins/plan-agent/skills/build/references/author-plan-chain.md` | Reference — Step 1b no-plan chain in full | Created |
| `kit/plugins/plan-agent/skills/build/references/completion-gates.md` | Reference — Steps 3, 4, 5 and spec-is-source-of-truth rules | Created |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Core — trigger, step names | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/references/resolve-and-modes.md` | Reference — argument parsing, spec vs. legacy mode | Created |
| `kit/plugins/plan-agent/skills/finalize-plan/references/sweep-mode.md` | Reference — `--all` flow | Created |
| `kit/plugins/plan-agent/skills/finalize-plan/references/evidence-analysis.md` | Reference — Steps 2–4 evidence and findings table | Created |
| `kit/plugins/plan-agent/skills/finalize-plan/references/write-completions.md` | Reference — Step 5 spec and legacy modes, Step 6 delivery | Created |
| `kit/plugins/plan-agent/skills/documenting-plans/SKILL.md` | Core — trigger, step names, TOC removed | Modified |
| `kit/plugins/plan-agent/skills/documenting-plans/references/resolve-and-preconditions.md` | Reference — Steps 0–2: todos, resolution priority, gate | Created |
| `kit/plugins/plan-agent/skills/documenting-plans/references/gather-evidence.md` | Reference — Steps 3–7: parse, slug, git history, collision | Created |
| `kit/plugins/plan-agent/skills/documenting-plans/references/doc-template.md` | Reference — Step 8 template and Step 9 report table | Created |
| `kit/plugins/plan-agent/skills/plan-status/SKILL.md` | Core — trigger, step names, TOC removed | Modified |
| `kit/plugins/plan-agent/skills/plan-status/references/single-file-flow.md` | Reference — Steps 0–4, 6–7: resolution, scoring, write rules | Created |
| `kit/plugins/plan-agent/skills/plan-status/references/bulk-mode.md` | Reference — directory/`--all` seven-stage flow | Created |
| `kit/plugins/plan-agent/skills/plan-status/references/type-classification.md` | Reference — Step 5 signal-to-type table | Created |
| `kit/plugins/plan-agent/skills/setup-sites/SKILL.md` | Core — trigger, step names | Modified |
| `kit/plugins/plan-agent/skills/setup-sites/references/preflight.md` | Reference — Steps 1–3: git/remote URL, sanity check, template lookup | Created |
| `kit/plugins/plan-agent/skills/setup-sites/references/scaffold.md` | Reference — Step 4 four idempotent artifacts | Created |
| `kit/plugins/plan-agent/skills/setup-sites/references/enable-and-verify.md` | Reference — Steps 5–7: Pages source, verification, delivery | Created |
| `tests/plugins/test-progressive-disclosure.sh` | Test — word ceiling and link integrity for all five skills | Created |
| `tests/plugins/test-build-skill.sh` | Test — extractors updated to resolve across SKILL.md and references/ | Modified |
| `tests/plugins/test-finalize-all-flag.sh` | Test — extractors updated for split | Modified |
| `tests/plugins/test-setup-sites.sh` | Test — extractors updated for split | Modified |
| `.github/workflows/check-plugin-versions.yml` | CI workflow — progressive-disclosure test step added | Modified |
| `.claude-plugin/marketplace.json` | Marketplace manifest — plan-agent 7.5.0 → 7.6.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Plugin changelog — 7.6.0 entry | Modified |

## How it works

A SKILL.md body is loaded in full whenever the skill triggers — there is no partial load, no lazy paragraph. The five pre-split files totalled 10,776 words across one plugin: `build` (2,907), `finalize-plan` (2,764), `documenting-plans` (1,897), `plan-status` (1,681), `setup-sites` (1,527). The `build` skill's `## Step 1b — Author a plan first` section alone was ~60 lines of delegation contract that fired only when the skill was invoked with no plan named; every ordinary `/plan-agent:build docs/plans/x.md` call paid for all of it and read none.

The pattern being applied is already proven inside the same plugin. `kit/plugins/plan-agent/skills/implementation-plan/` ships a core that explicitly names its `guidelines/*.md` files and tells the model to read each "when the step calls for it, not all up front." This plan copies that structure using the `references/` directory spelling that `build-dist.mjs` already whitelists and that `code-testing-agent` and `wcag-compliance-reviewer` use for their own skills.

The split for each skill followed the same template: the core keeps the trigger description, argument summary, a list of named steps each linking its reference file, and any subroutine called by every step (the re-render subroutine in `build` stayed in the core for exactly this reason — moving it would trade one always-paid block for five on-demand fetches of four lines). The mechanics — the 60-line no-plan chain, the three completion-gate blocks, the `--all` sweep, the entire bulk-mode workflow, the shell blocks for site scaffolding — moved verbatim into `references/` files.

Behavior preservation was the primary risk, mitigated at two levels. The existing tests (`test-build-skill.sh` with 18 phrase assertions, `test-finalize-all-flag.sh`, `test-setup-sites.sh`) were updated to search both SKILL.md and the `references/*.md` files for each owning heading before asserting its contract phrases. All assertions were kept unchanged — no phrase was weakened or deleted. These tests are the only record that the split did not drop a rule. The new `test-progressive-disclosure.sh` enforces the structural contract in CI: every core under 600 words, at least one reference file, every link in a core resolves to a file on disk, every file on disk is linked from the core (no orphans).

The split also deleted the hand-maintained `## Table of Contents` sections from `documenting-plans` and `plan-status`. A manually-maintained TOC beside a step list is Rule 4 repetition (say a thing once), and the linked step list in the core serves the same navigational purpose without a separate section to keep in sync. The `description:` frontmatter lines were untouched in all five files — these strings drive skill activation, and `test-description-budget.sh` confirmed all five still pass the 200/80 budget after the split.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| 0fd7b67 | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |

<!-- generated:end -->

## References

- Plan: [split-plan-agent-skills.md](plans/split-plan-agent-skills.md)
