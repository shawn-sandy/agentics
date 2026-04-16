# Extract Deep Grill into Standalone Skill

> Extracts the deep-grill session from plan-interview's Step 4 into a standalone `deep-grill` skill and command, making it independently invocable on any plan file; plan-interview steps renumbered to 4–6.

<!-- generated:start -->

**Status:** Shipped 2026-03-28   **Plan:** [extract-deep-grill-into-standalone-skill.md](plans/extract-deep-grill-into-standalone-skill.md)   **Type:** standard

## What shipped

- New `kit/plugins/plan-interview/skills/deep-grill/SKILL.md` — standalone deep-grill skill with 4-step workflow: resolve plan, read plan and build design tree, walk branches with focused questions, present summary.
- New `kit/plugins/plan-interview/commands/deep-grill.md` — command mirror using `$ARGUMENTS` for file path; enables `/plan-interview:deep-grill [path]`.
- `skills/plan-interview/SKILL.md` — Step 4 (deep grill) replaced with a callout to the standalone skill; former Steps 5–7 renumbered to Steps 4–6.
- `README.md` — `deep-grill` command and skill rows added to Components table; Deep Grill usage section added.
- `CHANGELOG.md` — `[1.10.0] - 2026-03-28` entry added.
- `marketplace.json` — `plan-interview` version bumped from `1.9.1` to `1.10.0`.

> See [CHANGELOG §1.10.0](../kit/plugins/plan-interview/CHANGELOG.md) for the authoritative change log entry.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/plan-interview/skills/deep-grill/SKILL.md` | Standalone deep-grill skill | Created |
| `kit/plugins/plan-interview/commands/deep-grill.md` | Explicit invocation command | Created |
| `kit/plugins/plan-interview/skills/plan-interview/SKILL.md` | Main interview skill | Modified (Step 4 replaced, Steps 5–7 → 4–6) |
| `kit/plugins/plan-interview/README.md` | Plugin documentation | Modified |
| `kit/plugins/plan-interview/CHANGELOG.md` | Version history | Modified (1.10.0 entry) |
| `.claude-plugin/marketplace.json` | Marketplace registry | Modified (version 1.10.0) |

## How it works

Before this change, the deep grill was only accessible as an optional Step 4 inside a full plan interview session. Extracting it makes the grill independently invocable on any plan file at any time — useful when a plan already exists and the user wants to probe decision nodes without running the full interview.

The standalone skill uses the same plan resolution algorithm as `plan-interview` and `plan-status`: check `$ARGUMENTS`, then scan `docs/plans/`, then ask. It builds a design tree by reading the plan's decision nodes and offers to grill all branches or a selection. The codebase exploration uses Read/Glob/Grep but no Write/Edit — the skill is strictly read-only per its `allowed-tools` frontmatter.

The plan-interview skill's Step 4 section was replaced with a short callout note directing users to the standalone skill. Steps that were formerly numbered 5, 6, and 7 became 4, 5, and 6, with internal cross-references updated accordingly.

## How to use it

```bash
# Auto-activation (description matching):
# "deep grill this plan", "walk through decisions", "examine each branch"

# Explicit command:
/plan-interview:deep-grill docs/plans/my-plan.md
```

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `6b9fab3` | 2026-03-26 | Merge pull request #51 from shawn-sandy/docs/plan-interview-upgrade |
| `9c70a52` | 2026-03-30 | chore(docs/plans): add YAML frontmatter status to 83 plan files |
| `e15fba2` | 2026-04-04 | refactor: rename agentics/ marketplace subtree to kit/ |

<!-- generated:end -->

## References

- Plan: [extract-deep-grill-into-standalone-skill.md](plans/extract-deep-grill-into-standalone-skill.md)
- Changelog: [kit/plugins/plan-interview/CHANGELOG.md §1.10.0](../kit/plugins/plan-interview/CHANGELOG.md)
- Skill: [kit/plugins/plan-interview/skills/deep-grill/SKILL.md](../kit/plugins/plan-interview/skills/deep-grill/SKILL.md)
