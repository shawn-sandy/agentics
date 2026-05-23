# Plan: Move ship-autonomous into the git-agent Plugin

## Context

`ship-autonomous` is currently at `.claude/skills/ship-autonomous/SKILL.md` —
a project-level skill that is not installable by anyone else. This is an
anti-pattern: the skill is an orchestrator built entirely on top of
`git-agent` sub-skills (`branch-agent`, `commit-agent`, `pr-agent`) and is
conceptually part of the same git workflow family. Keeping it at the project
level siloes it from the plugin it depends on and prevents distribution.

The previous fix (adding `ToolSearch`/`ExitPlanMode` to `allowed-tools` and
inserting Step 0) was already committed. The new task is to relocate the skill
into `kit/plugins/git-agent/skills/ship-autonomous/SKILL.md` so it ships with
the plugin and can be installed by any user of the marketplace.

The existing `ship` skill in the plugin covers the basic flow (branch → commit
→ push → PR). `ship-autonomous` is a distinct superset: it adds CI polling,
a bounded autofix loop (lint/typecheck/peer-deps), and a review-request step.
They are complementary and should coexist.

## Files to Change

| Action | Path |
|--------|------|
| **Create** | `kit/plugins/git-agent/skills/ship-autonomous/SKILL.md` |
| **Delete** | `.claude/skills/ship-autonomous/SKILL.md` (and empty dir) |
| **Update** | `kit/plugins/git-agent/README.md` — add skill to Skills table and add a component docs section |
| **Update** | `.claude-plugin/marketplace.json` — bump git-agent version `3.7.1 → 3.8.0` |
| **Update** | `kit/plugins/git-agent/CHANGELOG.md` — add `3.8.0` entry |

## Skill Content

The SKILL.md content stays identical to the already-fixed version at
`.claude/skills/ship-autonomous/SKILL.md` (which already has Step 0,
`ToolSearch`, and `ExitPlanMode` in `allowed-tools`). No edits to the skill
body are needed — just the file move.

## README Update

Add a row to the Skills table in `kit/plugins/git-agent/README.md`:

```
| `ship-autonomous` | Supervised full pipeline: branch (if on default), commit, open PR, poll CI, auto-fix lint/typecheck/peer-deps (≤3 iterations), request review | "ship it autonomously", "ship and watch CI", "ship and fix what breaks" |
```

Add a component docs section describing the CI autofix loop and escalation
conditions (mirrors the existing `ship` section style).

## Version Bump

New skill → minor bump: `3.7.1 → 3.8.0` in `.claude-plugin/marketplace.json`.

CHANGELOG entry:

```markdown
## [3.8.0] - 2026-05-23

### Added
- `ship-autonomous` skill: supervised full-pipeline ship with CI polling,
  bounded autofix loop (lint/typecheck/peer-deps, ≤3 iterations), and
  review-request step; replaces the project-level `.claude/skills/ship-autonomous/`
```

## Verification

1. `git diff HEAD -- kit/plugins/git-agent/skills/ship-autonomous/SKILL.md` —
   confirm skill file exists in the plugin
2. Confirm `.claude/skills/ship-autonomous/` directory is gone
3. `cat .claude-plugin/marketplace.json | jq '.plugins[] | select(.name=="git-agent") | .version'`
   — should return `"3.8.0"`
4. Load the plugin locally and say "ship it autonomously" — skill activates
   without permission prompts and exits plan mode in Step 0
