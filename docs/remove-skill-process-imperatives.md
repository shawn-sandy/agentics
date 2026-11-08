# Earn every NEVER — baseline first, then prune

> Remove process-reminder imperatives from five over-constrained SKILL.md files in plan-agent, git-agent, and skill-reviewer, backed by committed behavioral baselines recorded before any imperative was removed.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [remove-skill-process-imperatives.md](plans/remove-skill-process-imperatives.md)
**Type:** refactor

## What shipped

- Classified all 118 imperatives across five target skills as KEEP or DROP using the discriminator "violating it fails silently and expensively"; committed the KEEP set to `tests/fixtures/imperative-baselines/keep-phrases.txt`.
- Built `tests/plugins/test-skill-behavior-baselines.sh` with fixed-input scenarios per skill, asserting only structural facts (files written, gates fired, refusals emitted) rather than prose — recorded five `.expected` manifests before any edits.
- Added a CLI-absent gate that exits 1 rather than silently skipping.
- Wrote `tests/plugins/test-imperative-pruning.sh` as the objective CI gate, asserting KEEP phrases present, description byte-identity, manifests exist, and behavioral harness passes.
- Pruned DROP-classified imperatives from `plan-agent:build`, `plan-agent:implementation-plan`, `git-agent:ship-autonomous`, `git-agent:branch-agent`, and `skill-reviewer:optimizing-skill-frontmatter` — 7 insertions and 14 deletions across five files.
- Bumped plan-agent to 7.2.0, git-agent to 4.9.0, and skill-reviewer to 2.4.0 (originally targeted 5.1.0/4.8.0/2.3.0 but those versions were already on `main`).
- Wired `test-imperative-pruning.sh` into `.github/workflows/check-plugin-versions.yml`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `tests/fixtures/imperative-baselines/keep-phrases.txt` | KEEP classification — `<skill path>\t<literal phrase>` per line | Created |
| `tests/fixtures/imperative-baselines/scenarios/` | Fixed scenario inputs per skill (plan spec, dirty-tree script, SKILL.md) | Created |
| `tests/fixtures/imperative-baselines/*.expected` | Recorded structural manifests, one per target skill | Created |
| `tests/plugins/test-skill-behavior-baselines.sh` | Local-only behavioral harness; exits 1 when CLI absent | Created |
| `tests/plugins/test-imperative-pruning.sh` | CI-wired objective gate; asserts KEEP phrases, description drift, manifests | Created |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Skill instructions — process reminders pruned, gate guards kept | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill instructions — `## Scope Constraint — Plans Only` block intact | Modified |
| `kit/plugins/git-agent/skills/ship-autonomous/SKILL.md` | Skill instructions — merge/branch-deletion guards kept | Modified |
| `kit/plugins/git-agent/skills/branch-agent/SKILL.md` | Skill instructions — stash and no-force guards kept | Modified |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md` | Skill instructions — `disable-model-invocation: false` prohibition kept | Modified |
| `.claude-plugin/marketplace.json` | Marketplace — plan-agent 7.2.0, git-agent 4.9.0, skill-reviewer 2.4.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Changelog — 7.2.0 entry | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Changelog — 4.9.0 entry | Modified |
| `kit/plugins/skill-reviewer/CHANGELOG.md` | Changelog — 2.4.0 entry | Modified |
| `.github/workflows/check-plugin-versions.yml` | CI — step running `test-imperative-pruning.sh` added | Modified |

## How it works

The motivation was Anthropic's "The new rules of context engineering" article, which reported removing 80%+ of Claude Code's own system prompt with no measurable loss. The safety concern is that this repo's skills include irreversible operations — `ship-autonomous` ends in a squash merge, `branch-agent` manages uncommitted work via stash — where a dropped sentence could cause a destroyed working tree.

The sequencing was the safety mechanism. Baselines were captured and committed as a single commit (`ed6b854`) that touched no shipped plugin file. Each skill received one fixed input scenario (a known plan spec for `build`, a known dirty-tree git sandbox for `branch-agent` and `ship-autonomous`, etc.). The harness recorded only structural facts: files written and their paths, gates that fired, refusals emitted — never prose wording.

By the time the plan ran, three of the five target skills had already been split into cores plus reference files by earlier PRs. `ship-autonomous` had shrunk from 2,448 to 597 words, `branch-agent` from 1,515 to 582, and `optimizing-skill-frontmatter` from 3,153 to 579 — with many named DROP targets already gone. The real remaining DROP set was five items rather than 118, so the actual prune was 7 insertions and 14 deletions.

For each skill, only process-scaffolding text was removed: ordering statements like "Run Steps 0–5 in strict order", step-0 rationale sentences explaining why plan mode must be exited, and duplicate restatements of rules already carried in `## Overview`. Every KEEP-classified guard was verified to remain in place via `grep -F` in `keep-phrases.txt`.

Behavioral neutrality was proven rather than inferred: baselines were independently reproduced 5/5 before editing and 5/5 again after the prune. The load-bearing facts held — `implementation-plan` wrote nothing outside `docs/plans/`, `branch-agent`'s stash returned every file with its contents, `ship-autonomous` left `HEAD` unchanged.

## How to use it

The pruning is transparent to users. The skills behave identically and the safety guards remain. To verify the gates hold at any time:

```bash
bash tests/plugins/test-imperative-pruning.sh
```

The behavioral harness requires the `claude` CLI and exits 1 without it:

```bash
bash tests/plugins/test-skill-behavior-baselines.sh
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `43d18ee` | 2026-10-31 | fix(plan-agent,social-media-tools): remove model pins from skills (9.22.0, 2.25.0) (#668) |
| `8a8a392` | 2026-10-31 | fix(git-agent): remove model pins from skills (4.25.0) (#667) |
| `174d0ef` | 2026-10-27 | fix(marketplace): resolve claude.ai plugin validation issues (#660) |
| `02136c1` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `c16fe83` | 2026-10-13 | feat(plan-agent): live UI previews inside plan pages (9.20.0) (#651) |
| `3056b57` | 2026-09-28 | fix: retire dated prompt patterns in plan-agent and git-agent (#641) |
| `9277c9f` | 2026-09-18 | feat(git-agent): commit and ship paths handle lint-gate blocks (4.21.0) (#635) |
| `f3be024` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract — lanes in the renderer, authoring, and build (9.14.0–9.17.0) (#628) |
| `4f72700` | 2026-08-27 | feat(git-agent): add a context guard to ship-autonomous (#608) |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [remove-skill-process-imperatives.md](plans/remove-skill-process-imperatives.md)
- Related docs: [split-plan-agent-skills.md](split-plan-agent-skills.md), [split-remaining-plugin-skills.md](split-remaining-plugin-skills.md)
