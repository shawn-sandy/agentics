---
status: completed
type: feature
created: 2026-08-19
modified: 2026-08-19
repo-name: agentics
---

# Plan: Add the implementing-insights skill to memory-tools

## Context

The 2026-08-19 usage-insights session established a repeatable workflow for acting on
usage-insights reports: triage every recommendation against existing config before
implementing anything, place each open item at the correct config layer (plugin /
user-global / repo), implement one item per PR with worktree isolation for parallel
agents, and clean up afterward. That workflow was first captured as a personal skill at
`~/.claude/skills/implementing-insights/`. Per the config-layer placement rule from that
same session, workflow-shaped behavior belongs in the user's own plugins — versioned and
synced across machines — so the skill moves into `memory-tools`, the plugin that already
owns Claude Code configuration quality (`agentic-memory-management`, `path-rules-advisor`).

## Objective

Ship `implementing-insights` as a third skill in the `memory-tools` plugin, conforming to
this repo's skill-authoring conventions, and remove the personal-skill copy.

## Steps

1. Move `~/.claude/skills/implementing-insights/` to
   `kit/plugins/memory-tools/skills/implementing-insights/` — *Why:* workflow-shaped
   behavior belongs in the versioned plugin, and a leftover personal copy would shadow the
   plugin skill. *Verify:* directory exists in the plugin; personal copy gone.
2. Rewrite `SKILL.md` frontmatter and body to repo conventions: three-part description
   ≤200 chars, `allowed-tools` including `ToolSearch` + `ExitPlanMode`, the verbatim
   plan-mode guard as the first step, a verification-gate line in the reporting step, and
   personal absolute paths generalized — *Why:* `skill-authoring.md` and
   `plugin-patterns.md` require these; the guard and description budget are enforced by
   tests. *Verify:* `tests/plugins/test-exitplanmode-guard.sh` and
   `test-description-budget.sh` pass.
3. Bump `memory-tools` to `4.2.0` in `.claude-plugin/marketplace.json` only (MINOR — new
   skill), extend its description and tags, mirror description/keywords in the plugin's
   `plugin.json` without adding a `version` there — *Why:* marketplace rules put `version`
   solely in `marketplace.json`; a `plugin.json` version silently overrides it.
   *Verify:* `BASE_REF=main node scripts/check-plugin-versions.mjs` passes.
4. Add a `v4.2.0` entry to `kit/plugins/memory-tools/CHANGELOG.md` and document the skill
   in the plugin README (skills table, section, structure tree, current version) — *Why:*
   marketplace rules require a CHANGELOG entry; the README is the per-plugin reference.
   *Verify:* README lists three skills; CHANGELOG top entry is v4.2.0.
5. Run the full suite and open one PR with all changes plus this plan file — *Why:* repo
   convention commits the plan alongside plugin changes; CI enforces the version gate.
   *Verify:* `bash tests/run-all.sh` passes locally; PR opened.

## Tests

> Tier: 2 (non-code — markdown skill content, manifest metadata, docs)

### Objective-Verification Test

- **File:** `tests/run-all.sh` (auto-discovering suite — `test-exitplanmode-guard.sh`,
  `test-description-budget.sh`, and the frontmatter checks sweep every
  `kit/plugins/**/skills/**/SKILL.md`, so the new skill is covered with no CI wiring)
- **Type:** smoke test sweep
- **Asserts:** the new SKILL.md carries the exact plan-mode guard line, a valid
  three-part description within the 200-char budget, and valid frontmatter — i.e. the
  skill loads and conforms; `scripts/check-plugin-versions.mjs` asserts the 4.2.0 bump
  exceeds the base branch.
- **Run:** `bash tests/run-all.sh` and `BASE_REF=main node scripts/check-plugin-versions.mjs`

## Acceptance Criteria

- [x] `kit/plugins/memory-tools/skills/implementing-insights/SKILL.md` exists and passes
      the repo's skill sweeps.
- [x] `~/.claude/skills/implementing-insights/` no longer exists.
- [x] `memory-tools` is `4.2.0` in `marketplace.json` and nowhere else.
- [x] CHANGELOG and plugin README document the new skill.
- [ ] PR is open with all changes in a single commit; CI version gate green or reported.

## Verification

`bash tests/run-all.sh` passes, `BASE_REF=main node scripts/check-plugin-versions.mjs`
passes, `claude plugin validate .` (or the settings-hook validation of
`marketplace.json`) reports no errors, and the PR diff contains the skill, manifest,
CHANGELOG, README, and this plan — nothing else.
