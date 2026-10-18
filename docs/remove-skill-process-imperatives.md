# Earn every NEVER — baseline first, then prune

> Removes process-reminder imperatives from five SKILL.md files after recording committed behavioral baselines that prove the pruning changed nothing that matters.

<!-- generated:start -->

**Status:** Shipped 2026-07-30  **Plan:** [remove-skill-process-imperatives.md](plans/remove-skill-process-imperatives.md)
**Type:** refactor

## What shipped

- Added `tests/fixtures/imperative-baselines/keep-phrases.txt` — KEEP-classified guard phrases, one per line with skill path prefix, verified literal-present by `grep -F`.
- Added `tests/fixtures/imperative-baselines/scenarios/` — fixed input files per skill for the behavioral harness.
- Added `tests/fixtures/imperative-baselines/*.expected` — five structural manifests recording which files were written, which gates fired, and which refusals were emitted for each skill against its fixed scenario.
- Added `tests/fixtures/imperative-baselines/descriptions.expected` — golden `description:` lines for each target skill (comparison target for the drift check).
- Added `tests/plugins/test-skill-behavior-baselines.sh` — local-only behavioral harness; runs each skill headless via `claude -p` against its fixed scenario and diffs structural facts against the recorded manifest; exits 1 when the `claude` CLI is absent (never silently skips).
- Added `tests/plugins/test-imperative-pruning.sh` — CI-wired structural gate: asserts every KEEP phrase is literally present, no description line drifted, all five manifests exist and are non-empty.
- Wired `test-imperative-pruning.sh` into `.github/workflows/check-plugin-versions.yml`.
- Pruned DROP-classified process reminders from five SKILL.md files (plan-agent/build, plan-agent/implementation-plan, git-agent/ship-autonomous, git-agent/branch-agent, skill-reviewer/optimizing-skill-frontmatter) — kept every KEEP-classified guard verbatim.
- Bumped plan-agent to `7.2.0`, git-agent to `4.9.0`, skill-reviewer to `2.4.0` in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `tests/fixtures/imperative-baselines/keep-phrases.txt` | KEEP guard list | Created |
| `tests/fixtures/imperative-baselines/scenarios/` | Fixed skill inputs | Created |
| `tests/fixtures/imperative-baselines/*.expected` | Structural manifests | Created |
| `tests/fixtures/imperative-baselines/descriptions.expected` | Description golden file | Created |
| `tests/plugins/test-skill-behavior-baselines.sh` | Behavioral harness | Created |
| `tests/plugins/test-imperative-pruning.sh` | Structural gate | Created |
| `.github/workflows/check-plugin-versions.yml` | CI configuration | Modified |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/git-agent/skills/ship-autonomous/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/git-agent/skills/branch-agent/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md` | Skill instructions | Modified |
| `.claude-plugin/marketplace.json` | Marketplace versions | Modified |

## How it works

The central discriminator: keep an imperative only if violating it fails silently and expensively. Process scaffolding a Claude 5-generation model infers from surrounding context — strict-ordering reminders, Plan Mode exit rationales, re-render reminders that point at a subroutine already in the file — was classified DROP. Safety guards for irreversible or destructive operations — `ship-autonomous`'s merge-on-green rule, branch-agent's stash/pop guards, `implementation-plan`'s `## Scope Constraint — Plans Only` block, `optimizing-skill-frontmatter`'s prohibition on `disable-model-invocation: false` — were classified KEEP.

By the time the plan ran, PRs #487 and #489 had already split the heavy skills into cores plus reference files, reducing the real DROP set to five items rather than 118. The committed baselines proved the remaining prune was behavior-neutral: structural manifests were recorded against unmodified skills, independently reproduced 5/5 before any edit, committed as a separate baseline commit touching no shipped plugin file, and reproduced 5/5 again after the prune.

The behavioral harness exits 1 when the `claude` CLI is absent rather than silently skipping, so the gate cannot self-approve when it cannot run. Two harness defects were fixed during implementation: inherited stdin caused runs to wedge in non-interactive environments, and a watchdog subshell inherited the manifest pipe and held it open for the full timeout.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `67ab9a1` | 2026-08-19 | docs: sync README plugin table with memory-tools 4.3.0 (#588) |

<!-- generated:end -->

## References

- Plan: [remove-skill-process-imperatives.md](plans/remove-skill-process-imperatives.md)
