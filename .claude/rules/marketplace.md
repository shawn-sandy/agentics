---
paths:
  - "kit/plugins/**"
  - ".claude-plugin/**"
---

# Marketplace Configuration

## Registering a Plugin

Add plugin entries to `.claude-plugin/marketplace.json`:

```json
{
  "plugins": [
    {
      "name": "my-plugin",
      "source": {
        "source": "git-subdir",
        "url": "shawn-sandy/agentics",
        "path": "kit/plugins/my-plugin"
      },
      "version": "1.0.0",
      "description": "Brief description",
      "category": "development",
      "tags": ["relevant", "tags"]
    }
  ]
}
```

**Version:** Set `version` only in `marketplace.json`. Do NOT add it to `plugin.json` — `plugin.json` silently overrides the marketplace version.

## Standard Categories

- `development` — Developer tools and utilities
- `productivity` — Workflow and efficiency tools
- `learning` — Educational and tutorial plugins
- `testing` — Testing and QA tools
- `documentation` — Documentation generators
- `security` — Security analysis and auditing

## Tagging

Tags must be specific, searchable, and related to plugin functionality. Avoid generic terms like "tool" or "helper".

## Versioning

**Bump the `version` field in `marketplace.json` manually** as part of any PR that changes a plugin. The new value must be higher than the value on the PR's base branch (usually `main`). A CI version guard enforces this: `.github/workflows/check-plugin-versions.yml` runs `scripts/check-plugin-versions.mjs` on every pull request, comparing against the branch the PR targets. Run it locally with `BASE_REF=main node scripts/check-plugin-versions.mjs`, setting `BASE_REF` to your target branch if it is not `main`. The script compares against `origin/${BASE_REF}` directly, so run `git fetch origin` first if that remote-tracking ref isn't up to date locally. There is still no automatic post-merge bump — what you set in the PR is what ships.

| Bump | When |
|------|------|
| **PATCH** | Bug fix, typo, metadata correction |
| **MINOR** | New command, skill, agent, or hook added |
| **MAJOR** | Removing/renaming a command/skill/agent, changing argument format or activation behavior |

### What you do

1. Edit the plugin's `version` in `.claude-plugin/marketplace.json` to the next semver value (see the table above).
2. Add an entry to `kit/plugins/<name>/CHANGELOG.md` describing the change.
3. Use conventional commit messages (`feat(...)`, `fix(...)`) so the history stays readable — these are no longer wired to any automatic bump, but remain the project convention.

### Merge driver

The `scripts/merge-marketplace.mjs` merge driver (registered via `.gitattributes`) handles version merge conflicts in `marketplace.json` — when two branches bump the same plugin, it keeps the higher semver. It also resolves non-version conflicts, e.g. two branches adding different new plugins or updating metadata fields.

## Removed Plugins — Do Not Re-Add

See `removed-plugins.md`, which is always loaded so the confirmation gate applies even when no plugin file is open.

## Common Pitfalls

- Invalid `path` in `git-subdir` source — must match actual directory in the repo
- Duplicate plugin names in the same marketplace
- Missing `marketplace.json` in `kit/.claude-plugin/`
- Setting `version` in both `plugin.json` and `marketplace.json`
