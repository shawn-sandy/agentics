# Add repo discovery and global-dir fallback to implementing-insights

> Makes the `implementing-insights` skill resolve target repos discover-first using `~/.claude/projects/` slugs, and routes workflow-shaped items to `~/.claude/` when the user has no plugin repo — portable to any Claude Code install.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [add-insights-repo-discovery.md](plans/add-insights-repo-discovery.md)
**Type:** feature

## What shipped

- Rewrote Step 3's resolution paragraph in `SKILL.md` as a three-step discovery sequence: inventory from `~/.claude/projects/` slugs, name-suffix matching verified against a real git checkout, then ask-for-directory fallback scanned one level deep.
- Added a plugin-layer fallback to the workflow-shaped bullet: when the user has no personal plugin repo, items route to `~/.claude/` as the next-best fit.
- Removed all machine-specific absolute paths from the skill — resolution is now based on `~/.claude/projects/` which exists on every Claude Code install including Windows (non-alphanumeric characters encoded as `-`).
- Bumped `memory-tools` to `4.3.0` in `.claude-plugin/marketplace.json` (MINOR behavior addition), added the CHANGELOG entry, and synced the plugin README (version line and step list).
- All tests pass: `bash tests/run-all.sh` reports 75 passed, 0 failed, 4 skipped; the version guard passes against `origin/main`.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/memory-tools/skills/implementing-insights/SKILL.md` | Skill instructions | Modified |
| `.claude-plugin/marketplace.json` | Marketplace entry | Modified |
| `kit/plugins/memory-tools/CHANGELOG.md` | Changelog | Modified |
| `kit/plugins/memory-tools/README.md` | Plugin README | Modified |

## How it works

The previous resolution strategy in `implementing-insights` was passive: it read repo names from the insights report and immediately asked the user for a path when any repo wasn't found. This worked on the machine where the skill was authored but failed for marketplace users with no shared directory layout.

The key insight is that `~/.claude/projects/` already exists on every Claude Code install and contains slugged subdirectories for every project the user has worked in — the same projects that appear in usage-insights reports. A repo named in a finding will always have a corresponding slug in that directory.

The new resolution sequence in Step 3 is: first, build an inventory of all `~/.claude/projects/` subdirectories and decode their slugs (non-alphanumeric characters are encoded as `-`); second, match each report-mentioned repo name as a suffix of a decoded slug and verify that it points to a real git checkout; third, only if no match is found after those two steps, ask the user to point at a projects directory and scan one level deep from there.

The ask is now for a directory to search, not for individual repo paths — this means a single user answer can unblock resolution of multiple repos from the same report.

The `~/.claude/` global-dir fallback handles the case where a finding recommends workflow-shaped changes but the user has no personal plugin repo. Without the fallback, those items would stall waiting for a path that doesn't exist for most marketplace users. Routing to `~/.claude/` gives a sensible next-best location that is universally available.

The discovery logic was verified live on the development machine: `~/.claude/projects/` slugs decode to real checkouts, and worktree slugs are distinguishable from repo slugs by the `-claude-worktrees-` marker in the slug.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `f25758e` | 2026-08-19 | feat(memory-tools): implementing-insights discovers repos, global-dir fallback (4.3.0) (#587) |

<!-- generated:end -->

## References

- Plan: [add-insights-repo-discovery.md](plans/add-insights-repo-discovery.md)
