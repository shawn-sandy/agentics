# Stop paying 10,776 words for guidance nobody reads yet

> Split five monolithic `plan-agent` skills into small cores plus per-topic reference files, reducing always-loaded context while preserving all behavioral contracts.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [split-plan-agent-skills.md](plans/split-plan-agent-skills.md)
**Type:** refactor

## What shipped

- Split five `plan-agent` skills — `build` (2,907 words), `finalize-plan` (2,764), `documenting-plans` (1,897), `plan-status` (1,681), `setup-sites` (1,527) — into a SKILL.md core under 600 words plus named reference files loaded on demand.
- Created 14 new reference files across the five skill directories (e.g., `build/references/completion-gates.md`, `finalize-plan/references/sweep-mode.md`, `documenting-plans/references/doc-template.md`).
- Added `tests/plugins/test-progressive-disclosure.sh` asserting each core is under 600 words, has at least one `references/*.md`, every reference file on disk is linked from its core, and every `references/<name>.md` link in a core resolves to an existing file.
- Updated `tests/plugins/test-build-skill.sh`, `test-finalize-all-flag.sh`, and `test-setup-sites.sh` so their section-extraction logic resolves headings across SKILL.md and all reference files, keeping all 18 `build` contract-phrase checks intact.
- Wired `test-progressive-disclosure.sh` into `.github/workflows/check-plugin-versions.yml`.
- Bumped plan-agent from 7.5.0 to 7.6.0.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Skill core — reduced to trigger, arguments, re-render subroutine, and step names | Modified |
| `kit/plugins/plan-agent/skills/build/references/invocation.md` | Reference — flag parsing, command vs. model activation | Created |
| `kit/plugins/plan-agent/skills/build/references/resolve-plan.md` | Reference — dirty-tree preflight, directory resolution, discovery offer | Created |
| `kit/plugins/plan-agent/skills/build/references/author-plan-chain.md` | Reference — Step 1b: no-plan delegation contract | Created |
| `kit/plugins/plan-agent/skills/build/references/completion-gates.md` | Reference — Steps 3, 4, 5 verification mechanics | Created |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Skill core — step names only | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/references/resolve-and-modes.md` | Reference — argument parsing, mode selection | Created |
| `kit/plugins/plan-agent/skills/finalize-plan/references/sweep-mode.md` | Reference — `--all` discovery flow | Created |
| `kit/plugins/plan-agent/skills/finalize-plan/references/evidence-analysis.md` | Reference — evidence scoring, findings table | Created |
| `kit/plugins/plan-agent/skills/finalize-plan/references/write-completions.md` | Reference — Step 5 write rules, Step 6 delivery | Created |
| `kit/plugins/plan-agent/skills/documenting-plans/SKILL.md` | Skill core — step names only | Modified |
| `kit/plugins/plan-agent/skills/documenting-plans/references/resolve-and-preconditions.md` | Reference — Steps 0-2: todos, resolution, 30-day gate | Created |
| `kit/plugins/plan-agent/skills/documenting-plans/references/gather-evidence.md` | Reference — Steps 3-7: parse, slug, file inspection, git history | Created |
| `kit/plugins/plan-agent/skills/documenting-plans/references/doc-template.md` | Reference — Step 8 template and Step 9 report table | Created |
| `kit/plugins/plan-agent/skills/plan-status/SKILL.md` | Skill core — step names only | Modified |
| `kit/plugins/plan-agent/skills/plan-status/references/single-file-flow.md` | Reference — Steps 0-4, 6-7: single-file status flow | Created |
| `kit/plugins/plan-agent/skills/plan-status/references/bulk-mode.md` | Reference — `--all` seven-stage flow | Created |
| `kit/plugins/plan-agent/skills/plan-status/references/type-classification.md` | Reference — signal-to-type table | Created |
| `kit/plugins/plan-agent/skills/setup-sites/SKILL.md` | Skill core — step names only | Modified |
| `kit/plugins/plan-agent/skills/setup-sites/references/preflight.md` | Reference — Steps 1-3: git remote, plansDirectory check | Created |
| `kit/plugins/plan-agent/skills/setup-sites/references/scaffold.md` | Reference — Step 4: four idempotent artifacts | Created |
| `kit/plugins/plan-agent/skills/setup-sites/references/enable-and-verify.md` | Reference — Steps 5-7: Pages enablement, verification | Created |
| `tests/plugins/test-progressive-disclosure.sh` | Smoke test — word ceiling and link integrity | Created |
| `.github/workflows/check-plugin-versions.yml` | CI — new test step | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Plugin changelog — 7.6.0 entry | Modified |
| `.claude-plugin/marketplace.json` | Marketplace manifest — plan-agent 7.6.0 | Modified |

## How it works

A SKILL.md body loads in full every time the skill triggers — there is no partial load. `build`'s Step 1b delegation contract (~60 lines) was paid on every ordinary `/plan-agent:build docs/plans/x.md` invocation, even though it only fires when no plan is named. The three completion gates (Steps 3, 4, 5, ~80 lines) were paid before any work had been done and would only be needed at the end of a run.

The split moves each section into a named reference file and replaces it in the core with a step line linking to that file. The model reads the reference when it reaches that step, rather than before it starts. The re-render subroutine (a four-line bash block called by every build step) intentionally stays in the core — pulling it out would add five on-demand fetches of identical content.

Link integrity is enforced in both directions: every file on disk under `references/` must be linked from its SKILL.md, and every `references/<name>.md` string in a SKILL.md must resolve to an existing file. This catches both orphaned reference files and dangling links.

Behavioral contracts are preserved by the updated test suite. `test-build-skill.sh` section extractors were taught to search SKILL.md and all reference files for a given heading, keeping all 18 contract-phrase assertions intact. No assertion was relaxed — each still fails if a guard phrase is dropped from any file in the skill directory.

## How to use it

The split is transparent to users. All five skills activate and behave identically. The only visible change is that the model opens reference files during a run (observable in the tool call log) rather than having all mechanics pre-loaded.

```bash
/plan-agent:build docs/plans/my-plan.md
/plan-agent:finalize-plan
/plan-agent:documenting-plans docs/plans/my-plan.md
/plan-agent:plan-status docs/plans/my-plan.md
/plan-agent:setup-sites
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `43d18eec` | 2026-10-31 | fix(plan-agent,social-media-tools): remove model pins from skills (9.22.0, 2.25.0) (#668) |
| `02136c1d` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `c16fe83f` | 2026-10-13 | feat(plan-agent): live UI previews inside plan pages (9.20.0) (#651) |
| `f3be0249` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract (9.14.0–9.17.0) (#628) |
| `3263bbc9` | 2026-08-30 | feat(plan-agent): reconcile a plan against what actually shipped (9.11.0) (#613) |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [split-plan-agent-skills.md](plans/split-plan-agent-skills.md)
