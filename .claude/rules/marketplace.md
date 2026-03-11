# Marketplace Configuration

## Registering a Plugin

Add plugin entries to `.claude-plugin/marketplace.json`:

```json
{
  "plugins": [
    {
      "name": "my-plugin",
      "version": "1.0.0",
      "description": "Brief description",
      "source": "./plugins/my-plugin",
      "category": "development",
      "tags": ["relevant", "tags"]
    }
  ]
}
```

**Version location:** For relative-path plugins (like all plugins in this repo), set `version` only in `marketplace.json`. Do NOT add `version` to `plugin.json` — per [official docs](https://code.claude.com/docs/en/plugin-marketplaces), `plugin.json` silently overrides the marketplace version, creating a maintenance risk.

## Standard Categories

- `development` — Developer tools and utilities
- `productivity` — Workflow and efficiency tools
- `learning` — Educational and tutorial plugins
- `testing` — Testing and QA tools
- `documentation` — Documentation generators
- `security` — Security analysis and auditing

## Tagging Strategy

Tags must be:
- Specific and descriptive (not generic like "tool" or "helper")
- Searchable terms users would type when looking for this plugin
- Related to plugin functionality or use case

Example: `["formatting", "code-quality", "prettier", "eslint"]`

## Versioning (Semantic Versioning)

- **MAJOR** (`2.0.0`) — Breaking changes to plugin structure or behavior
- **MINOR** (`1.1.0`) — New features, backward compatible
- **PATCH** (`1.0.1`) — Bug fixes, backward compatible

## Bumping a Plugin Version

For relative-path plugins, the version lives in one place only:

- `.claude-plugin/marketplace.json` → `plugins[].version` for that plugin entry

Do **not** add `version` to `plugin.json` for relative-path plugins. If both files declare a version, `plugin.json` silently wins, making the marketplace version misleading.

### When to bump

| Bump | Triggers |
|------|----------|
| **PATCH** | Bug fix in a command/skill/hook, typo or clarification in instructions, correcting metadata (homepage, keywords) |
| **MINOR** | New command added, new skill added, new agent/hook added — all backward compatible |
| **MAJOR** | Removing or renaming a command/skill/agent, changing command argument format, changing skill activation behavior, restructuring plugin directory |

> **Out of scope:** `tests/fixtures/` plugins do not need version bumps. The marketplace-level version (`agentics-kit` v2.0.0) is separate from individual plugin versions and is not covered here.

### How to bump

1. **Edit `marketplace.json`** — update `"version"` in `.claude-plugin/marketplace.json` under the plugin entry
2. **Update changelog** — add an entry to `plugins/<name>/CHANGELOG.md` (create the file if it doesn't exist)
3. **Verify** — confirm the version is set only in `marketplace.json`:
   ```bash
   grep '"version"' .claude-plugin/marketplace.json | grep <name>
   ```
4. **Commit** — use a conventional commit message:
   - Patch: `fix(plugins/<name>): bump version to X.Y.Z`
   - Minor: `feat(plugins/<name>): bump version to X.Y.Z`
   - Major: `feat(plugins/<name>)!: bump version to X.Y.Z` with a `BREAKING CHANGE:` note in the body

## Common Pitfalls

- Invalid `source` paths — must be relative or absolute and must exist on disk
- Duplicate plugin names in the same marketplace
- Missing `marketplace.json` in `.claude-plugin/` directory
- Setting `version` in both `plugin.json` and `marketplace.json` — for relative-path plugins, set it only in `marketplace.json`
