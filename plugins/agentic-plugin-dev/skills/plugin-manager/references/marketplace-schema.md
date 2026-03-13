# Marketplace Schema Reference

Official docs: <https://code.claude.com/docs/en/plugin-marketplaces>

Use `WebFetch` on the URL above for the latest spec if the user requests "use latest docs".

## Marketplace File

**Location:** `.claude-plugin/marketplace.json`

### Top-Level Fields

| Field | Required | Type | Constraint |
|-------|----------|------|------------|
| `name` | Yes | string | Marketplace identifier |
| `version` | Yes | string | Semantic version of the marketplace itself |
| `description` | Yes | string | What this marketplace provides |
| `owner` | No | object | `{ "name": "...", "email": "..." }` |
| `plugins` | Yes | array | Array of plugin entries |

### Plugin Entry Fields

| Field | Required | Type | Constraint |
|-------|----------|------|------------|
| `name` | Yes | string | Plugin name. Must match `plugin.json` `name` field. Unique within marketplace. |
| `source` | Yes | string | Relative or absolute path to plugin directory |
| `version` | Yes | string | Semantic version (`X.Y.Z`). This is the authoritative version for relative-path plugins. |
| `description` | Yes | string | Brief description |
| `category` | Yes | string | One of the standard categories (see below) |
| `tags` | Yes | string[] | Searchable terms. Specific, not generic. |

## Standard Categories

| Category | Use For |
|----------|---------|
| `development` | Developer tools and utilities |
| `productivity` | Workflow and efficiency tools |
| `learning` | Educational and tutorial plugins |
| `testing` | Testing and QA tools |
| `documentation` | Documentation generators |
| `security` | Security analysis and auditing |

## Version Bump Triggers

| Bump | When |
|------|------|
| **PATCH** (`0.0.x`) | Bug fix in command/skill/hook, typo correction, metadata fix |
| **MINOR** (`0.x.0`) | New command, skill, agent, or hook added (backward compatible) |
| **MAJOR** (`x.0.0`) | Removing/renaming command/skill/agent, changing argument format, restructuring plugin directory |

## Commit Message Format

After bumping, suggest (do NOT execute):

- Patch: `fix(plugins/[name]): bump version to X.Y.Z`
- Minor: `feat(plugins/[name]): bump version to X.Y.Z`
- Major: `feat(plugins/[name])!: bump version to X.Y.Z` with `BREAKING CHANGE:` note

## Version Placement Rule

For relative-path plugins (source starts with `./` or is a local path):
- Set `version` ONLY in `marketplace.json`
- Do NOT add `version` to `plugin.json`
- Reason: `plugin.json` silently overrides the marketplace version, creating maintenance risk

## Validation Checklist

- [ ] JSON is valid (no trailing commas)
- [ ] No duplicate plugin names
- [ ] All `source` paths exist on disk
- [ ] All versions are valid semver (`X.Y.Z`)
- [ ] All categories are from the standard list
- [ ] Tags are specific and searchable (not generic like "tool" or "helper")
