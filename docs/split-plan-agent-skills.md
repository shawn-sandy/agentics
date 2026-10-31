# Split plan-agent skills into cores and references

> Splits five monolithic plan-agent skills (build, finalize-plan, documenting-plans, plan-status, setup-sites) into lean cores under 600 words with detail in references/, and adds a bidirectional link integrity test.

<!-- generated:start -->

**Status:** Shipped 2026-08-01 **Plan:** [split-plan-agent-skills.md](plans/split-plan-agent-skills.md)
**Type:** refactor

## What shipped

- Split `build`, `finalize-plan`, `documenting-plans`, `plan-status`, and `setup-sites` into cores + `references/` files.
- All cores under 600 words after the split.
- Added `tests/plugins/test-progressive-disclosure.sh` with bidirectional link integrity checks.
- Bumped plan-agent to 7.6.0 in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Build core | Modified |
| `kit/plugins/plan-agent/skills/build/references/` | Build references | Created |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Finalize core | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/references/` | Finalize references | Created |
| `kit/plugins/plan-agent/skills/documenting-plans/SKILL.md` | Documenting core | Modified |
| `kit/plugins/plan-agent/skills/documenting-plans/references/` | Documenting references | Created |
| `kit/plugins/plan-agent/skills/plan-status/SKILL.md` | Plan-status core | Modified |
| `kit/plugins/plan-agent/skills/plan-status/references/` | Plan-status references | Created |
| `kit/plugins/plan-agent/skills/setup-sites/SKILL.md` | Setup-sites core | Modified |
| `kit/plugins/plan-agent/skills/setup-sites/references/` | Setup-sites references | Created |
| `tests/plugins/test-progressive-disclosure.sh` | Link integrity test | Created |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Version history | Modified |

## How it works

Each skill was split following the progressive-disclosure pattern: the core keeps activation conditions, the first 1–2 steps, and any mandatory checks (plan-mode guard, security gates). Everything a model reads during execution goes into `references/*.md` files that the core links by name.

The `test-progressive-disclosure.sh` test enforces bidirectional link integrity: every `references/` file that a core links to must exist, and every `references/` file must be linked from somewhere. This catches two failure modes — a reference file that's created but never linked (dead code), and a core that links to a non-existent file (broken reference).

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [split-plan-agent-skills.md](plans/split-plan-agent-skills.md)
