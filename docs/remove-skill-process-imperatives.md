# Earn every NEVER — baseline first, then prune

> Remove process-reminder imperatives from five over-constrained SKILL.md files in `plan-agent`, `git-agent`, and `skill-reviewer`, but only after each skill's behavior is captured as a committed, passing baseline test.

<!-- generated:start -->

**Status:** Shipped 2026-08-12 **Plan:** [remove-skill-process-imperatives](plans/remove-skill-process-imperatives.md)
**Type:** refactor

## What shipped

- Classified all imperatives in five target SKILL.md files as KEEP (safety/scope/irreversibility guards) or DROP (process reminders), committed the KEEP set to `tests/fixtures/imperative-baselines/keep-phrases.txt`.
- Built a behavioral baseline harness (`tests/plugins/test-skill-behavior-baselines.sh`) with fixed scenario inputs per skill and structural `.expected` manifests; the harness exits 1 rather than silently skipping when the `claude` CLI is absent.
- Added an objective test (`tests/plugins/test-imperative-pruning.sh`) asserting every KEEP phrase is literally present, all five `description:` lines are unchanged, all five `.expected` manifests exist, and the behavioral harness passes when the CLI is available.
- Pruned DROP-classified imperatives from five SKILL.md files while keeping all load-bearing safety guards verbatim.
- Wired `test-imperative-pruning.sh` into `.github/workflows/check-plugin-versions.yml`.
- Shipped as plan-agent 7.2.0, git-agent 4.9.0, skill-reviewer 2.4.0 with matching CHANGELOG entries.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `tests/fixtures/imperative-baselines/keep-phrases.txt` | KEEP classification — one literal guard phrase per skill path per line | Created |
| `tests/fixtures/imperative-baselines/branch-agent.expected` | Structural manifest for `branch-agent` baseline | Created |
| `tests/fixtures/imperative-baselines/build.expected` | Structural manifest for `build` baseline | Created |
| `tests/fixtures/imperative-baselines/descriptions.expected` | Golden frontmatter description lines for all five targets | Created |
| `tests/fixtures/imperative-baselines/implementation-plan.expected` | Structural manifest for `implementation-plan` baseline | Created |
| `tests/fixtures/imperative-baselines/optimizing-skill-frontmatter.expected` | Structural manifest for `optimizing-skill-frontmatter` baseline | Created |
| `tests/plugins/test-skill-behavior-baselines.sh` | Local-only behavioral harness; exits 1 when CLI absent | Created |
| `tests/plugins/test-imperative-pruning.sh` | CI-wired objective test for the prune | Created |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Process reminders pruned; gate guards kept | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Process reminders pruned; `## Scope Constraint — Plans Only` kept intact | Modified |
| `kit/plugins/git-agent/skills/ship-autonomous/SKILL.md` | Process reminders pruned; merge and branch-deletion guards kept | Modified |
| `kit/plugins/git-agent/skills/branch-agent/SKILL.md` | Duplicate ordering text pruned; stash and no-force guards kept | Modified |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md` | Process reminders pruned; `disable-model-invocation: false` prohibition kept | Modified |
| `.claude-plugin/marketplace.json` | plan-agent → 7.2.0, git-agent → 4.9.0, skill-reviewer → 2.4.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 7.2.0 entry | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | 4.9.0 entry | Modified |
| `kit/plugins/skill-reviewer/CHANGELOG.md` | 2.4.0 entry | Modified |
| `.github/workflows/check-plugin-versions.yml` | Step added running `bash tests/plugins/test-imperative-pruning.sh` | Modified |

## How it works

**Classifying imperatives before touching any file.** Every line matching `NEVER|ALWAYS|MUST|do not|don't` across the five target skills was classified as KEEP or DROP using a single discriminator: keep an imperative only if violating it fails silently and expensively. The KEEP set was committed to `tests/fixtures/imperative-baselines/keep-phrases.txt` as `<skill path>\t<literal phrase>` lines, where each phrase is a single-line substring greppable by `grep -F`. This committed classification is the contract the objective test enforces.

**Recording behavioral baselines before editing.** `tests/plugins/test-skill-behavior-baselines.sh` was built with fixed scenario inputs per skill: a known `todo` plan spec for `build`, a known objective for `implementation-plan`, a known dirty tree in a throwaway `git init` sandbox for `branch-agent` and `ship-autonomous`, and a known SKILL.md copy for `optimizing-skill-frontmatter`. Each skill was run headless via `claude -p --plugin-dir kit/plugins/<plugin>` and the harness recorded only structural facts — files written and their paths, gates that fired, refusals emitted. The baseline commit (`ed6b854`) touched no file under `kit/plugins/`, establishing a green reference point before any prune.

**The objective test.** `tests/plugins/test-imperative-pruning.sh` asserts four things: every `keep-phrases.txt` entry is literally present in its named file (via `grep -F`), each target `description:` frontmatter line is byte-identical to `tests/fixtures/imperative-baselines/descriptions.expected` (the description comparison uses a golden file rather than `git show origin/main` to allow deliberate future updates without blocking CI), all five `.expected` manifests exist and are non-empty, and the behavioral harness passes when `command -v claude` succeeds. The test exits 1 for a dropped guard, a drifted description, and a missing baseline alike — all three failure modes were verified by break-and-revert cycles.

**The prune itself.** Across the five skills the actual DROP set turned out to be five items rather than 118: by implementation time three skills had already shrunk ~80% from earlier PR splits, so several named DROP targets were already gone. The shipped diff is 7 insertions and 14 deletions across five files. Items removed include: Step 0 plan-mode rationale sentences in `build` and `implementation-plan`, `build`'s "Spec edits only" Step 2 aside superseded by the `## Overview` paragraph, `implementation-plan`'s Step 4 `Rename` restatement of the kebab-case convention already given in Step 2, `ship-autonomous`'s "Run Steps 0–5 in strict order", and `branch-agent`'s opening "Follow these steps in strict order" (already restated by `## Step 6: Confirm and STOP`).

**Harness defects fixed during implementation.** Two harness bugs were found and fixed: headless runs inherited the caller's stdin (a closed pipe from non-interactive callers caused `claude` to wedge), fixed by redirecting from `/dev/null`; and the timeout watchdog's `sleep` kept the manifest pipe's write end open, pinning every run for the full 900-second timeout, fixed by moving the watchdog to a separate fd. The `gh_invoked` boolean was replaced by `gh_mutating_invoked` to distinguish read-only pre-flight calls from mutating ones. `BASELINE_ONLY` now exits 1 on unknown scenario names to prevent silent zero-scenario passes.

**Version bump deviation.** The version targets in the plan spec (5.1.0 / 4.8.0 / 2.3.0) were already met or exceeded on `main` by the time the prune ran, so bumping to them would have been a regression. Shipped as plan-agent 7.2.0, git-agent 4.9.0, skill-reviewer 2.4.0.

## How to use it

```bash
# Run the objective test
bash tests/plugins/test-imperative-pruning.sh

# Run the behavioral baseline harness (requires claude CLI)
bash tests/plugins/test-skill-behavior-baselines.sh

# Record new baselines (after approved SKILL.md changes)
bash tests/plugins/test-skill-behavior-baselines.sh --record
```

The `tests/fixtures/imperative-baselines/keep-phrases.txt` file is the machine-readable contract for which guards must remain verbatim in each SKILL.md.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `de3b5a3` | 2026-07-30 | refactor(skills): prune process-reminder imperatives behind recorded behavior baselines (#495) |

<!-- generated:end -->

## References

- Plan: [remove-skill-process-imperatives](plans/remove-skill-process-imperatives.md)
- Changelog: `kit/plugins/plan-agent/CHANGELOG.md` — 7.2.0 entry; `kit/plugins/git-agent/CHANGELOG.md` — 4.9.0 entry; `kit/plugins/skill-reviewer/CHANGELOG.md` — 2.4.0 entry
- Anthropic context engineering guidance: https://claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models
