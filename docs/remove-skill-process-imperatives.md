# Earn every NEVER — baseline first, then prune

> Five skills carried 118 imperatives across 13,758 words, most of them restating process a Claude 5 model infers. Behavioral baselines were committed before a single line was deleted; the prune was 7 insertions and 14 deletions across five files, because prior skill splits had already removed most of the target text.

<!-- generated:start -->

**Status:** Shipped 2026-07-30 **Plan:** [remove-skill-process-imperatives.md](plans/remove-skill-process-imperatives.md)
**Type:** refactor

## What shipped

- Classified every imperative in five SKILL.md files as KEEP or DROP; wrote the KEEP set to `tests/fixtures/imperative-baselines/keep-phrases.txt` as tab-separated `<skill path>\t<literal phrase>` lines.
- Built `tests/plugins/test-skill-behavior-baselines.sh`: a local-only behavioral harness running each skill headless against fixed scenario inputs and asserting structural facts (files written, gates fired, refusals emitted — never prose wording); exits 1 when the `claude` CLI is absent rather than silently skipping.
- Recorded five `.expected` manifests under `tests/fixtures/imperative-baselines/`; committed as `ed6b854` touching no shipped plugin file — the baseline commit precedes every prune.
- Fixed two harness defects discovered during development: headless runs inherited stdin from the caller (wedged when the caller was non-interactive); the watchdog subshell kept the manifest pipe open, pinning every run to the full 900s timeout. Both fixed; runs now complete in ~84s.
- Wrote `tests/plugins/test-imperative-pruning.sh`: the CI-wired structural gate asserting every KEEP phrase is literally present, every description line matches its golden file, all five manifests exist and are non-empty, and the behavioral harness passes when the `claude` CLI is available. Description drift comparison is against `tests/fixtures/imperative-baselines/descriptions.expected` rather than `origin/main`, so a deliberate future description update updates that file in the same commit rather than permanently failing CI.
- Pruned DROP-classified imperatives from all five files: removed "Run Steps 0–5 in strict order" from `ship-autonomous`, "Follow these steps in strict order." from `branch-agent`, Step 0 plan-mode rationale sentences from `build` and `implementation-plan`, and "Follow these steps exactly" / "Count carefully" from `optimizing-skill-frontmatter`. Kept every safety guard: merge-on-green, `--delete-branch`, review-dismissal, stash/pop guards, `## Scope Constraint — Plans Only`, never-hand-edit-HTML, and `disable-model-invocation: false` prohibition.
- Shipped as **plan-agent 7.2.0, git-agent 4.9.0, skill-reviewer 2.4.0** — the originally specified 5.1.0 / 4.8.0 / 2.3.0 were already met or exceeded on `main`; bumping to them would have been a version regression.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `tests/fixtures/imperative-baselines/keep-phrases.txt` | KEEP classification contract | Created |
| `tests/fixtures/imperative-baselines/scenarios/` | Fixed skill inputs | Created |
| `tests/fixtures/imperative-baselines/*.expected` | Recorded structural manifests | Created |
| `tests/fixtures/imperative-baselines/descriptions.expected` | Golden description lines | Created |
| `tests/plugins/test-skill-behavior-baselines.sh` | Local-only behavioral harness | Created |
| `tests/plugins/test-imperative-pruning.sh` | CI-wired structural gate | Created |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Drop Step 0 rationale, re-render asides | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Drop Step 0 rationale, Step 4 restatement | Modified |
| `kit/plugins/git-agent/skills/ship-autonomous/SKILL.md` | Drop "Run Steps 0–5 in strict order" | Modified |
| `kit/plugins/git-agent/skills/branch-agent/SKILL.md` | Drop opening order sentence, Step 6 restatement | Modified |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md` | Drop "Follow these steps exactly", "Count carefully" | Modified |
| `.github/workflows/check-plugin-versions.yml` | Wire test-imperative-pruning.sh | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 7.2.0, git-agent 4.9.0, skill-reviewer 2.4.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 7.2.0 entry | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | 4.9.0 entry | Modified |
| `kit/plugins/skill-reviewer/CHANGELOG.md` | 2.4.0 entry | Modified |

## How it works

**Premise stale, contract intact**: The plan was written before PRs #487/#489 split these skills into cores plus references. At implementation time three of five targets had already shrunk ~80%: `ship-autonomous` from 2,448 to 597 words (20 to 13 imperatives), `branch-agent` from 1,515 to 582, `optimizing-skill-frontmatter` from 3,153 to 579. The real remaining DROP set was five items, not 118.

**Baseline-first discipline**: Manifests were recorded against unmodified skills, independently reproduced 5/5 before any edit, and committed in `ed6b854` touching no shipped plugin file. The behavioral facts held: `implementation-plan` left source files byte-identical with zero writes outside the plans directory; `branch-agent`'s stash and pop returned every file with an empty `git stash list`; `build` promoted `status:` and created only the named file; `optimizing-skill-frontmatter` never emitted `disable-model-invocation: false`; `ship-autonomous` left HEAD, branch, and working tree unchanged.

**Gate proven falsifiable**: Deleting the merge-on-green guard makes `test-imperative-pruning.sh` exit 1 naming that exact phrase; appending one character to a description line makes it exit 1 reporting the drift. Both return to exit 0 on `git checkout --`.

**Abort condition never invoked**: No imperative had to be restored.

## How to use it

The changes are automatic — sessions loading the three updated plugins get the pruned skill bodies. To run the structural gate: `bash tests/plugins/test-imperative-pruning.sh`. To run the behavioral harness (requires the `claude` CLI): `bash tests/plugins/test-skill-behavior-baselines.sh`.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `ed6b854` | 2026-07-30 | test: record behavioral baselines before imperative prune |
| — | 2026-07-30 | refactor: prune DROP-classified imperatives from five SKILL.md files (plan-agent 7.2.0, git-agent 4.9.0, skill-reviewer 2.4.0) |

<!-- generated:end -->

## References

- Plan: [remove-skill-process-imperatives.md](plans/remove-skill-process-imperatives.md)
