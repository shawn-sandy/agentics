# Add repo discovery and global-dir fallback to implementing-insights

> Makes the `implementing-insights` skill resolve target repos discover-first (asking only as a last resort) and routes workflow-shaped items to `~/.claude/` when the user has no plugin repo — portable to any Claude Code install including Windows.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [add-insights-repo-discovery.md](plans/add-insights-repo-discovery.md)
**Type:** feature

## What shipped

- Rewrote Step 3's resolution paragraph in `SKILL.md` as a three-step sequence: inventory from `~/.claude/projects/` slugs, name-suffix matching verified against a real git checkout, then ask-for-directory fallback scanned one level deep
- Worktree slugs filtered out by detecting the `-claude-worktrees-` marker; non-alphanumeric characters decoded from the `-` encoding used in `~/.claude/projects/` slug format (portable to Windows)
- Plugin-layer fallback added: when the user has no personal plugin repo, workflow-shaped items route to `~/.claude/` as the next-best fit
- `memory-tools` bumped to `4.3.0` in `.claude-plugin/marketplace.json`
- CHANGELOG entry and plugin README sync (version line + step list)

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/memory-tools/skills/implementing-insights/SKILL.md` | Skill instructions — rewritten Step 3 repo resolution | Modified |
| `.claude-plugin/marketplace.json` | Marketplace entry — memory-tools 4.3.0 | Modified |
| `kit/plugins/memory-tools/CHANGELOG.md` | Release notes — 4.3.0 entry | Modified |
| `kit/plugins/memory-tools/README.md` | Plugin documentation — version line + step list updated | Modified |

## How it works

The key improvement is using `~/.claude/projects/` as the discovery source. This directory exists on every Claude Code install and contains slugs for every repo the user has worked in — crucially, the same repos that usage-insights reports are generated from. Any repo a report names has a matching slug in `~/.claude/projects/`.

Slug decoding handles the `~/.claude/projects/` encoding: path separators and non-alphanumeric characters are encoded as `-`, so `/Users/name/devbox/myrepo` becomes `-Users-name-devbox-myrepo`. Worktree slugs are excluded by detecting `-claude-worktrees-` in the slug, since worktrees should not be used as the implementation target.

The fallback chain is: (1) inventory from `~/.claude/projects/` slugs → (2) name-suffix matching against git checkouts → (3) ask the user to point at a projects directory (scanned one level deep). The user is asked for a directory path, never for per-repo paths, which is both more ergonomic and more portable.

The `~/.claude/` fallback for workflow-shaped items means generic marketplace users who have no plugin repo of their own are not stuck. Skills, hooks, and rules that belong at the user-global layer go to `~/.claude/` where they will be available in all sessions.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `7a4214f` | 2026-09-26 | feat(memory-tools): implementing-insights publishes a live record per item (4.4.0) (#638) |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [add-insights-repo-discovery.md](plans/add-insights-repo-discovery.md)
