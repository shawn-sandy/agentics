# Plan: Rename code-share Skills to `share-*` Prefix

## Context

The `code-share` plugin (in `kit/plugins/social-media-tools/`) has 8 skills whose names follow inconsistent conventions — some suffix with `-share` (e.g. `code-share`, `blog-share`), others are mixed (`github-code-share`, `scan-for-shares`). Goal: rename all share-type skills to a consistent `share-*` prefix (e.g. `share-code`, `share-blog`) while keeping the plugin name `code-share` unchanged.

## Skill Renames (git mv)

| Old Directory | New Directory |
|---|---|
| `skills/code-share/` | `skills/share-code/` |
| `skills/selection-share/` | `skills/share-selection/` |
| `skills/blog-share/` | `skills/share-blog/` |
| `skills/video-share/` | `skills/share-video/` |
| `skills/github-code-share/` | `skills/share-github/` |
| `skills/project-share/` | `skills/share-project/` |
| `skills/scan-for-shares/` | `skills/share-scan/` |

**Not renamed:** `skills/social-share/` (router, stays as-is) and `skills/security-scrub/` (pipeline utility, not a share type).

## Reference Updates

All internal invocations use `Skill(skill: "code-share:<skill-name>", ...)`. These must be updated after renames:

### `skills/social-share/SKILL.md`
Router references target skills by exact name in its classification phase and dispatch template. Update:
- `github-code-share` → `share-github`
- `video-share` → `share-video`
- `blog-share` → `share-blog`
- `selection-share` → `share-selection`
- `project-share` → `share-project`
- `code-share` (fallback) → `share-code`

### `agents/agent-social-share.md`
Example skill names in the dispatch documentation:
- `code-share`, `blog-share`, `project-share` → `share-code`, `share-blog`, `share-project`

### `agents/agent-digest.md`
- `code-share:scan-for-shares` → `code-share:share-scan`

### `commands/digest.md`
- `code-share:scan-for-shares` → `code-share:share-scan`

## Files to Rename

```
skills/code-share/        → skills/share-code/
skills/selection-share/   → skills/share-selection/
skills/blog-share/        → skills/share-blog/
skills/video-share/       → skills/share-video/
skills/github-code-share/ → skills/share-github/
skills/project-share/     → skills/share-project/
skills/scan-for-shares/   → skills/share-scan/
```

## Files to Modify

```
skills/social-share/SKILL.md         ← update 6 skill name refs + dispatch template
agents/agent-social-share.md         ← update example skill name refs
agents/agent-digest.md               ← scan-for-shares → share-scan
commands/digest.md                   ← scan-for-shares → share-scan
CHANGELOG.md                         ← v1.0.0 entry
.claude-plugin/marketplace.json      ← version bump 0.9.0 → 1.0.0
```

All paths relative to `kit/plugins/social-media-tools/`.

## Version Bump

Per project conventions, renaming skills is a **major** change → `0.9.0` → `1.0.0`.

Commit message:
```
feat(kit/plugins/social-media-tools)!: rename skills to share-* prefix

BREAKING CHANGE: skill names changed to share-* prefix. share-code,
share-blog, share-video, share-github, share-selection, share-project,
share-scan. Internal dispatch updated throughout. Plugin name unchanged.
```

## Verification

1. `ls kit/plugins/social-media-tools/skills/` — confirm `share-*` directories present, old names gone
2. `grep -r "scan-for-shares\|code-share:code-share\|blog-share\|video-share\|selection-share\|github-code-share\|project-share" kit/plugins/social-media-tools/` — should return no matches (old names eliminated)
3. `cat .claude-plugin/marketplace.json | python3 -m json.tool` — confirm JSON valid and version is `1.0.0`
