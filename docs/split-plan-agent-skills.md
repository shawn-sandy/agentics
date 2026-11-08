# Stop paying 10,776 words for guidance nobody reads yet

> Split five monolithic plan-agent skills into small cores under 600 words plus on-demand reference files, cutting always-loaded skill context by moving mechanics that fire only on specific branches into `references/*.md` files.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [split-plan-agent-skills.md](plans/split-plan-agent-skills.md)
**Type:** refactor

## What shipped

- Split `kit/plugins/plan-agent/skills/build/SKILL.md` (2,907 words) into a core plus four reference files: `invocation.md`, `resolve-plan.md`, `author-plan-chain.md`, and `completion-gates.md` (keeping the re-render subroutine in the core since every step calls it).
- Split `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` (2,764 words) into a core plus `resolve-and-modes.md`, `sweep-mode.md`, `evidence-analysis.md`, and `write-completions.md`.
- Split `kit/plugins/plan-agent/skills/documenting-plans/SKILL.md` (1,897 words) into a core plus `resolve-and-preconditions.md`, `gather-evidence.md`, and `doc-template.md`; deleted the hand-maintained Table of Contents.
- Split `kit/plugins/plan-agent/skills/plan-status/SKILL.md` (1,681 words) into a core plus `single-file-flow.md`, `bulk-mode.md`, and `type-classification.md`; deleted the Table of Contents.
- Split `kit/plugins/plan-agent/skills/setup-sites/SKILL.md` (1,527 words) into a core plus `preflight.md`, `scaffold.md`, and `enable-and-verify.md`.
- Updated `tests/plugins/test-build-skill.sh`, `test-finalize-all-flag.sh`, and `test-setup-sites.sh` to resolve assertions across SKILL.md and all reference files.
- Added `tests/plugins/test-progressive-disclosure.sh` as the objective CI gate, wired into `.github/workflows/check-plugin-versions.yml`.
- Bumped plan-agent to 7.6.0.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Build skill core — trigger, arguments, step names, re-render subroutine | Modified |
| `kit/plugins/plan-agent/skills/build/references/invocation.md` | Reference — command vs model activation, flag parsing | Created |
| `kit/plugins/plan-agent/skills/build/references/resolve-plan.md` | Reference — Step 0 exit-plan-mode, dirty-tree pre-flight, plans-directory resolution | Created |
| `kit/plugins/plan-agent/skills/build/references/author-plan-chain.md` | Reference — Step 1b full: objective check, proposal-vs-direct gate, delegation paths | Created |
| `kit/plugins/plan-agent/skills/build/references/completion-gates.md` | Reference — Steps 3, 4, 5 and spec-is-source-of-truth rules | Created |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Finalize skill core — step names | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/references/resolve-and-modes.md` | Reference — argument parsing, plans-directory precedence, spec-vs-legacy mode | Created |
| `kit/plugins/plan-agent/skills/finalize-plan/references/sweep-mode.md` | Reference — `--all` flow S1–S5 | Created |
| `kit/plugins/plan-agent/skills/finalize-plan/references/evidence-analysis.md` | Reference — Steps 2, 3a–3c, Step 4 findings table | Created |
| `kit/plugins/plan-agent/skills/finalize-plan/references/write-completions.md` | Reference — Step 5 spec/legacy mode, Step 6 delivery | Created |
| `kit/plugins/plan-agent/skills/documenting-plans/SKILL.md` | Documenting-plans skill core — step names | Modified |
| `kit/plugins/plan-agent/skills/documenting-plans/references/resolve-and-preconditions.md` | Reference — todos, plan resolution, 30-days-old gate | Created |
| `kit/plugins/plan-agent/skills/documenting-plans/references/gather-evidence.md` | Reference — parse plan, derive slug, inspect files, git history, target-doc collision | Created |
| `kit/plugins/plan-agent/skills/documenting-plans/references/doc-template.md` | Reference — Step 8 document template and Step 9 report table | Created |
| `kit/plugins/plan-agent/skills/plan-status/SKILL.md` | Plan-status skill core — step names | Modified |
| `kit/plugins/plan-agent/skills/plan-status/references/single-file-flow.md` | Reference — Steps 0–4, 6–7: resolution, git dates, scoring, write rules | Created |
| `kit/plugins/plan-agent/skills/plan-status/references/bulk-mode.md` | Reference — directory/`--all` seven-stage flow with triage table | Created |
| `kit/plugins/plan-agent/skills/plan-status/references/type-classification.md` | Reference — Step 5 signal-to-type table | Created |
| `kit/plugins/plan-agent/skills/setup-sites/SKILL.md` | Setup-sites skill core — step names | Modified |
| `kit/plugins/plan-agent/skills/setup-sites/references/preflight.md` | Reference — Steps 1–3: git/remote URL derivation, plansDirectory check | Created |
| `kit/plugins/plan-agent/skills/setup-sites/references/scaffold.md` | Reference — Step 4 four idempotent artifacts | Created |
| `kit/plugins/plan-agent/skills/setup-sites/references/enable-and-verify.md` | Reference — Steps 5–7: Pages source enablement, verification | Created |
| `tests/plugins/test-progressive-disclosure.sh` | Objective test — word ceiling plus link integrity in both directions | Created |
| `tests/plugins/test-build-skill.sh` | Test suite — section extractors resolve across SKILL.md and references/ | Modified |
| `tests/plugins/test-finalize-all-flag.sh` | Test suite — updated extractors | Modified |
| `tests/plugins/test-setup-sites.sh` | Test suite — updated extractors | Modified |
| `.github/workflows/check-plugin-versions.yml` | CI — step running `test-progressive-disclosure.sh` | Modified |
| `.claude-plugin/marketplace.json` | Marketplace — plan-agent 7.6.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Changelog — 7.6.0 entry | Modified |

## How it works

A SKILL.md body is paid in full every time the skill triggers — there is no partial load. `build`'s `## Step 1b — Author a plan first (the no-plan chain)` is ~60 lines that fire only on a no-argument invocation; every ordinary `/plan-agent:build docs/plans/x.md` paid for all of it. The three completion gates were ~80 more lines needed only at the end of a run.

The split pattern was already proven inside the same plugin: `implementation-plan` ships `guidelines/planning-principles.md` and sibling files, with its core instructing "read the full file when the step calls for it, not all up front." This plan standardized on `references/` (the dominant spelling in the repo) and copied that linking style to the other five skills.

Each split moved section text verbatim into the named reference file, then replaced the section in the core with a step name line linking the reference. No frontmatter `description:` lines were changed (a `git diff` assertion verified this). The re-render subroutine in `build` was deliberately left in the core since every single step calls it — pulling it out would trade one always-paid block for five on-demand fetches of the same four lines.

The objective test `test-progressive-disclosure.sh` asserts four things for each skill: `SKILL.md` is under 600 words (Python word count, locale-independent), at least one `references/*.md` exists, every reference file on disk is linked from the core (no orphans), and every `references/<name>.md` path mentioned in the core resolves to a real file (no dangling links).

The behavior-preservation tests (`test-build-skill.sh`, `test-finalize-all-flag.sh`, `test-setup-sites.sh`) were updated with section extractors that search across SKILL.md and its references. All 18 existing phrase-level assertions in `test-build-skill.sh` were kept intact — none was deleted or weakened.

> See [CHANGELOG v7.6.0](kit/plugins/plan-agent/CHANGELOG.md) for the authoritative feature list.

## How to use it

The skills invoke identically — the split is transparent to users. The only observable change is that a session invoking these skills now loads only the core on trigger and reads reference files on demand as steps are executed.

```bash
# These invocations are unchanged
/plan-agent:build docs/plans/my-plan.md
/plan-agent:finalize-plan docs/plans/my-plan.md
/plan-agent:plan-status docs/plans/my-plan.md
/plan-agent:setup-sites
/plan-agent:documenting-plans docs/plans/my-plan.md
```

The objective test verifies the split is correct:

```bash
bash tests/plugins/test-progressive-disclosure.sh
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `43d18ee` | 2026-10-31 | fix(plan-agent,social-media-tools): remove model pins from skills (9.22.0, 2.25.0) (#668) |
| `02136c1` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `c16fe83` | 2026-10-13 | feat(plan-agent): live UI previews inside plan pages (9.20.0) (#651) |
| `f3be024` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract — lanes in the renderer, authoring, and build (9.14.0–9.17.0) (#628) |
| `3263bbc` | 2026-08-30 | feat(plan-agent): reconcile a plan against what actually shipped (9.11.0) (#613) |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [split-plan-agent-skills.md](plans/split-plan-agent-skills.md)
- Related docs: [split-remaining-plugin-skills.md](split-remaining-plugin-skills.md)
- Changelog: `kit/plugins/plan-agent/CHANGELOG.md` — 7.6.0 entry
