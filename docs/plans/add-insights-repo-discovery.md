---
status: completed
type: feature
created: 2026-08-20
repo-name: agentics
---

# Plan: Add repo discovery and global-dir fallback to implementing-insights

## Context

The `implementing-insights` skill (memory-tools 4.2.0) resolved target repos passively:
it took repo names from the insights report and, the moment one was not immediately
found, asked the user for a path. It had no way to find local repos on its own, no
heuristic for recommendations that name no repo, and its workflow-behavior layer assumed
every user maintains a personal plugin repo. The skill ships to marketplace users, so
resolution must not assume any machine-specific layout.

## Objective

Make the skill resolve target repos discover-first (ask only as a last resort) and route
workflow-shaped items to `~/.claude/` when the user has no plugin repo of their own —
portable to any Claude Code install, including Windows.

## Steps

1. **Rewrite Step 3's resolution paragraph in `SKILL.md`** as a three-step sequence:
   inventory from `~/.claude/projects/` slugs (worktree slugs filtered, non-alphanumeric
   characters encoded as `-` so it holds on Windows), name-suffix matching verified against a real
   git checkout, then ask-for-directory fallback scanned one level deep.
   *Why:* `~/.claude/projects/` exists on every install and is the same usage data the
   report is generated from, so every repo the report can name has a slug there.
   *Verify:* re-read the step; confirm no machine-specific path appears.
2. **Add the plugin-layer fallback** to Step 3's workflow-shaped bullet: no personal
   plugin repo → route to `~/.claude/` as the next-best fit.
   *Why:* generic plugin users have no plugin repo; without the fallback those items stall.
   *Verify:* re-read the bullet.
3. **Bump memory-tools to 4.3.0** in `.claude-plugin/marketplace.json`, add the
   CHANGELOG entry, and sync the plugin README (version line + step list).
   *Why:* MINOR behavior addition per the marketplace versioning rule.
   *Verify:* `BASE_REF=main node scripts/check-plugin-versions.mjs` passes.

## Tests

**Objective-verification (Tier 2 — markdown/config only):** the repo suite
(`bash tests/run-all.sh`) exercises the changed files — the plan-mode guard grep runs
against this SKILL.md verbatim, the description-budget check re-measures its frontmatter,
and the version-guard test runs the same script that gates the bump. All must stay green
with the rewritten Step 3 in place.

## Acceptance criteria

- [x] The skill builds a repo inventory without any hardcoded or machine-specific path.
- [x] A repo named in a finding resolves via `~/.claude/projects/` before the user is asked.
- [x] The user is asked only to point at a projects directory, never for per-repo paths first.
- [x] Workflow-shaped items route to `~/.claude/` when the user has no plugin repo.
- [x] marketplace.json says 4.3.0 and the CHANGELOG documents both changes.

## Verification

`bash tests/run-all.sh` → 75 passed, 0 failed, 4 skipped. Version guard passes against
origin/main. Discovery source verified live on this machine: `~/.claude/projects/` slugs
decode to real checkouts and worktree slugs are distinguishable by the
`-claude-worktrees-` marker.
