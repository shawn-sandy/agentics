# Add insights repo discovery

> Adds a discover-first step to `implementing-insights` that inventories `~/.claude/projects/` slugs, matches them by name before asking the user, and falls back to a plugin-layer lookup when the local inventory is empty.

<!-- generated:start -->

**Status:** Shipped 2026-08-20 **Plan:** [add-insights-repo-discovery.md](plans/add-insights-repo-discovery.md)
**Type:** feature

## What shipped

- Added step 3 discover-first to `implementing-insights`: reads `~/.claude/projects/` slug inventory before asking the user which repo the insight belongs to.
- Name matching: slug is matched against the current working directory's basename and git remote URL before prompting.
- Ask-last: user is prompted only when auto-discovery fails.
- Plugin-layer fallback: when `~/.claude/projects/` is empty or missing, the skill checks the plugin's own project index.
- Bumped memory-tools to 4.3.0 in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/memory-tools/skills/implementing-insights/SKILL.md` | Skill core | Modified |
| `kit/plugins/memory-tools/skills/implementing-insights/references/` | Discovery reference | Modified |
| `kit/plugins/memory-tools/CHANGELOG.md` | Version history | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |

## How it works

The discover-first step reads `~/.claude/projects/` and builds a slug inventory: each subdirectory is a project slug, typically derived from the absolute path of the project root. For a project at `/home/user/myapp`, the slug is typically `-home-user-myapp`.

Name matching compares the slug against two signals: the current directory's basename (`myapp` in the example) and the git remote URL's repository name. A confident match skips the prompt entirely. An ambiguous match (multiple candidates with similar names) falls back to asking the user to pick from the candidates.

The plugin-layer fallback handles fresh installs where `~/.claude/projects/` doesn't exist yet: the plugin maintains a small project index file that grows as the user invokes `implementing-insights` in different repos. This index bootstraps the slug inventory on first use.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [add-insights-repo-discovery.md](plans/add-insights-repo-discovery.md)
