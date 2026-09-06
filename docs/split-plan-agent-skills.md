# Stop paying 10,776 words for guidance nobody reads yet

> Split the five monolithic `plan-agent` skills into small SKILL.md cores under 600 words each, with mechanics moved to on-demand `references/*.md` files, cutting 10,776 words of always-loaded context by ~65%.

<!-- generated:start -->

**Status:** Shipped 2026-08-15 **Plan:** [split-plan-agent-skills.md](plans/split-plan-agent-skills.md)
**Type:** refactor

## What shipped

- Wrote `tests/plugins/test-progressive-disclosure.sh` as an objective gate (before any skill was edited) asserting each SKILL.md is under 600 words, has at least one `references/*.md`, links every reference file on disk, and names no reference path that does not exist; confirmed it fails on the unmodified tree.
- Wired the new test into `.github/workflows/check-plugin-versions.yml`.
- Split `build/SKILL.md` into a core plus `references/invocation.md`, `references/resolve-plan.md`, `references/author-plan-chain.md`, and `references/completion-gates.md`; kept the re-render subroutine in the core since every step calls it.
- Updated `tests/plugins/test-build-skill.sh` so its 18 contract-phrase checks resolve across the SKILL.md and all `references/*.md`, with no check deleted or weakened.
- Split `finalize-plan/SKILL.md` into a core plus `references/resolve-and-modes.md`, `references/sweep-mode.md`, `references/evidence-analysis.md`, and `references/write-completions.md`; updated `test-finalize-all-flag.sh` accordingly.
- Split `documenting-plans/SKILL.md` into a core plus `references/resolve-and-preconditions.md`, `references/gather-evidence.md`, and `references/doc-template.md`; deleted the now-redundant hand-maintained Table of Contents.
- Split `plan-status/SKILL.md` into a core plus `references/single-file-flow.md`, `references/bulk-mode.md`, and `references/type-classification.md`; deleted its Table of Contents.
- Split `setup-sites/SKILL.md` into a core plus `references/preflight.md`, `references/scaffold.md`, and `references/enable-and-verify.md`; updated `test-setup-sites.sh` accordingly.
- Bumped plan-agent from 7.5.0 to 7.6.0 and added a CHANGELOG entry naming all five split skills with before/after word counts.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Core — trigger, arguments summary, step names, re-render subroutine | Modified |
| `kit/plugins/plan-agent/skills/build/references/invocation.md` | Command vs model activation, flag parsing, objective-versus-path grammar | Created |
| `kit/plugins/plan-agent/skills/build/references/resolve-plan.md` | Step 0 exit-plan-mode, dirty-tree preflight, discovery offer, preconditions | Created |
| `kit/plugins/plan-agent/skills/build/references/author-plan-chain.md` | Step 1b no-plan chain: objective check, proposal-vs-direct gate, delegation paths | Created |
| `kit/plugins/plan-agent/skills/build/references/completion-gates.md` | Steps 3, 4, 5 and spec-is-source-of-truth rules | Created |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Core — step names and argument summary | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/references/resolve-and-modes.md` | Step 1 argument parsing, spec-versus-legacy edit mode | Created |
| `kit/plugins/plan-agent/skills/finalize-plan/references/sweep-mode.md` | `--all` flow, S1 through S5 | Created |
| `kit/plugins/plan-agent/skills/finalize-plan/references/evidence-analysis.md` | Steps 2, 3a, 3b, 3c and Step 4 findings table | Created |
| `kit/plugins/plan-agent/skills/finalize-plan/references/write-completions.md` | Step 5 spec and legacy modes, Step 6 delivery | Created |
| `kit/plugins/plan-agent/skills/documenting-plans/SKILL.md` | Core — step names | Modified |
| `kit/plugins/plan-agent/skills/documenting-plans/references/resolve-and-preconditions.md` | Steps 0–2: resolution priority and completed-and-30-days-old gate | Created |
| `kit/plugins/plan-agent/skills/documenting-plans/references/gather-evidence.md` | Steps 3–7: parse plan, slug, inspect files, git history, collision check | Created |
| `kit/plugins/plan-agent/skills/documenting-plans/references/doc-template.md` | Step 8 document template and Step 9 report table | Created |
| `kit/plugins/plan-agent/skills/plan-status/SKILL.md` | Core — step names | Modified |
| `kit/plugins/plan-agent/skills/plan-status/references/single-file-flow.md` | Steps 0–4, 6–7: resolution, git dates, frontmatter, evidence scoring, write rules | Created |
| `kit/plugins/plan-agent/skills/plan-status/references/bulk-mode.md` | Directory / `--all` seven-stage flow with triage table | Created |
| `kit/plugins/plan-agent/skills/plan-status/references/type-classification.md` | Step 5 signal-to-type table and keep-existing-type rule | Created |
| `kit/plugins/plan-agent/skills/setup-sites/SKILL.md` | Core — step names | Modified |
| `kit/plugins/plan-agent/skills/setup-sites/references/preflight.md` | Steps 1–3: git/remote URL derivation, `plansDirectory` sanity check, template lookup | Created |
| `kit/plugins/plan-agent/skills/setup-sites/references/scaffold.md` | Step 4 four idempotent artifacts and hub placeholder/card-pruning rules | Created |
| `kit/plugins/plan-agent/skills/setup-sites/references/enable-and-verify.md` | Steps 5–7: Pages source enablement, verification block, delivery summary | Created |
| `tests/plugins/test-progressive-disclosure.sh` | Objective test — word ceiling, link integrity in both directions | Created |
| `tests/plugins/test-build-skill.sh` | Updated — section extractors search SKILL.md and `references/` | Modified |
| `tests/plugins/test-finalize-all-flag.sh` | Updated — same extractor treatment for `finalize-plan` | Modified |
| `tests/plugins/test-setup-sites.sh` | Updated — same extractor treatment for `setup-sites` | Modified |
| `.github/workflows/check-plugin-versions.yml` | CI — new step running `test-progressive-disclosure.sh` | Modified |
| `.claude-plugin/marketplace.json` | plan-agent version bump 7.5.0 → 7.6.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 7.6.0 release entry | Modified |

## How it works

A SKILL.md body is paid in full whenever its skill triggers — there is no partial load. `build`'s `## Step 1b — Author a plan first (the no-plan chain)` runs ~60 lines that fire only when no plan is named; every ordinary `/plan-agent:build docs/plans/x.md` invocation paid for all of it and read none of it. The three mandatory completion gates added another ~80 lines that matter only at the end of a run. The same pattern repeated across the other four skills: `finalize-plan`'s `--all` sweep, `plan-status`'s bulk mode, `setup-sites`'s embedded shell blocks.

Step 1 wrote the objective gate before any edit. `test-progressive-disclosure.sh` counts words in Python (locale-independent, unlike `wc -w` which can vary by ~20 words per file on multibyte characters), checks for at least one `references/*.md`, walks all `references/*.md` files on disk to confirm each is linked from the core (no orphans), and walks all `references/<name>.md` strings in each core to confirm each resolves to a file on disk (no dangling links). Running it against the unmodified tree produced exit 1 naming all five skills as over-ceiling with no reference files.

Steps 3 through 8 performed the splits in skill order. Text moved verbatim from the core into the appropriate reference file; each moved section was replaced in the core with a named step line linking its reference file. The deliberate exception to the ceiling: `build`'s four-line re-render subroutine stayed in the core because every single step calls it, and pulling it out would trade one always-paid block for five on-demand fetches of the same four lines.

For each split, the plan also updated the test that reads that skill. `test-build-skill.sh` carries 18 contract-phrase checks with exact phrase assertions; its `flatten`/`sed` section extractors were taught to search SKILL.md and every `references/*.md` in the skill directory for the owning heading. This means a dropped guard still fails the test regardless of which file the guard was supposed to be in. The same treatment was applied to `test-finalize-all-flag.sh` and `test-setup-sites.sh`. Hand-maintained Tables of Contents in `documenting-plans` and `plan-status` were deleted since the linked step list in each core serves the same navigation purpose (Rule 4: say a thing once).

## How to use it

Each skill is invoked through the plan-agent plugin. The split is transparent to end users; commands and skill triggers are unchanged. The only visible effect is that the model loads the relevant `references/*.md` file at the step that needs it rather than loading all mechanics upfront.

```bash
# Skills are invoked as before
/plan-agent:build docs/plans/<slug>.md
/plan-agent:finalize-plan docs/plans/<slug>.md
/plan-agent:documenting-plans docs/plans/<slug>.md
/plan-agent:plan-status docs/plans/<slug>.md
/plan-agent:setup-sites
```

The objective test confirms the split is structurally sound:

```bash
bash tests/plugins/test-progressive-disclosure.sh
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `17114d5` | 2026-08-25 | feat(plan-agent): card artifact-only plans in the plans gallery (9.7.0) (#601) |
| `94c0569` | 2026-08-23 | feat(plan-agent): add design phase — canvas link, gallery, and drift check (#596) |
| `e1e8840` | 2026-08-15 | feat(git-agent): add post-merge-cleanup skill (4.19.0) (#565) |

<!-- generated:end -->

## References

- Plan: [split-plan-agent-skills.md](plans/split-plan-agent-skills.md)
