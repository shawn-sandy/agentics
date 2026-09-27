# Add repo discovery and global-dir fallback to implementing-insights

> Upgrades the `implementing-insights` skill (memory-tools 4.3.0) to resolve target repos discover-first using `~/.claude/projects/` slugs and route workflow items to `~/.claude/` when no personal plugin repo exists.

<!-- generated:start -->

**Status:** Shipped 2026-08-19 **Plan:** [add-insights-repo-discovery.md](plans/add-insights-repo-discovery.md)
**Type:** feature

## What shipped

- Rewrote Step 3's resolution paragraph with a three-step sequence: inventory from `~/.claude/projects/` slugs → name-suffix matching against a real git checkout → ask-for-directory fallback scanned one level deep.
- Added a plugin-layer fallback for workflow-shaped items: users with no personal plugin repo have their items routed to `~/.claude/` instead of stalling.
- Bumped memory-tools from 4.2.0 to 4.3.0 in `.claude-plugin/marketplace.json` with CHANGELOG entry and synced plugin README.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/memory-tools/skills/implementing-insights/SKILL.md` | Core skill — repo resolution Step 3 | Modified |
| `.claude-plugin/marketplace.json` | Plugin version registry | Modified |
| `kit/plugins/memory-tools/CHANGELOG.md` | Release notes | Modified |
| `kit/plugins/memory-tools/README.md` | Plugin docs | Modified |

## How it works

The `implementing-insights` skill takes a usage-report and implements every genuinely open recommendation in the right config layer. The central challenge is resolving which local repo each recommendation refers to, without asking the user per-repo.

**Inventory from `~/.claude/projects/`**: every Claude Code project session writes a `.jsonl` file under a per-project directory in `~/.claude/projects/`. The skill reads the first `"cwd"` value from a session file in each directory to get the real path, so it builds an inventory of repos the user has actually opened — exactly the set the insights report can name.

**Name-suffix matching**: once the inventory is built, the skill matches a recommendation's target repo by checking whether the resolved path's basename exactly equals the repo name. A suffix match is deliberately rejected (`plugins` must not resolve to `acss-plugins`). Two checkouts sharing a basename → ask.

**Ask-for-directory fallback**: only when a repo still cannot be resolved does the skill ask the user to point at a directory, then scans one level deep for `.git`. This is the last resort, not the first move.

**Plugin-layer fallback**: for workflow-shaped items (how PRs, plans, or reviews happen), the skill routes to the user's own plugin repo. If the user has no plugin repo, the fallback is `~/.claude/` — machine-wide settings are the next-best fit and stop the item from stalling.

**Portability**: no machine-specific paths appear in the SKILL.md. The inventory is rebuilt from scratch on every run, so the skill works on any Claude Code install including Windows (where the projects directory uses the same encoding).

## How to use it

Invoke as `/memory-tools:implementing-insights` (or let it activate via description match when you mention implementing insights findings). Pass a report as a file path, artifact URL, or pasted content.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `7a4214f` | 2026-09-26 | feat(memory-tools): implementing-insights publishes a live record per item (4.4.0) (#638) |
| `19174f7` | 2026-08-23 | fix(memory-tools): stricter repo resolution in implementing-insights (4.3.1) (#597) |
| `f25758e` | 2026-08-19 | feat(memory-tools): implementing-insights discovers repos, global-dir fallback (4.3.0) (#587) |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [add-insights-repo-discovery.md](plans/add-insights-repo-discovery.md)
