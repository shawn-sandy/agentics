---
paths:
  - "kit/plugins/**"
  - ".claude-plugin/**"
---

# Marketplace Configuration

Register a plugin by copying an existing entry in
`.claude-plugin/marketplace.json` and editing it. Set `version` there and
**never** in `plugin.json` — for relative-path plugins the manifest silently
overrides the marketplace value.

## Categories

Pick one: `development`, `productivity`, `learning`, `testing`,
`documentation`, `security`.

Tags must be specific and searchable. Not "tool", not "helper".

## Versioning

Bump `version` manually in the same PR that changes a plugin; the new value
must exceed the PR's base branch. `.github/workflows/check-plugin-versions.yml`
enforces it. Locally:

```bash
git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs
```

The script compares against `origin/${BASE_REF}` directly, hence the fetch.
There is no automatic post-merge bump — what the PR sets is what ships.

| Bump | When |
|------|------|
| **PATCH** | Bug fix, typo, metadata correction |
| **MINOR** | New command, skill, agent, or hook |
| **MAJOR** | Removing or renaming a component, or changing argument format or activation behavior |

Also add a `kit/plugins/<name>/CHANGELOG.md` entry. Conventional commit
messages (`feat(...)`, `fix(...)`) are convention only — nothing reads them.

`scripts/merge-marketplace.mjs` (registered via `.gitattributes`) resolves
version conflicts by keeping the higher semver, and merges unrelated additions
cleanly.

## Pitfalls

- `path` in a `git-subdir` source that does not match a real directory
- Duplicate plugin names within one marketplace
- Missing `marketplace.json` in `kit/.claude-plugin/`

Removed plugins are gated in `removed-plugins.md`, which is always loaded.
