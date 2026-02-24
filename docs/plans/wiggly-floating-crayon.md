# Plan: Document Plugin Version Bump Process

## Context

There is no documented process for updating plugin versions. Developers currently must know from memory that versions appear in two places and must stay in sync. The goal is to add a clear, scannable step-by-step workflow to the existing marketplace rule file so the process is always followed correctly.

## Deliverable

Add a **"Bumping a Plugin Version"** section to `.claude/rules/marketplace.md`.

No scripts, no new files — documentation only.

## Critical Files

- `.claude/rules/marketplace.md` — add the new section here (versioning rules already live here)

## Version Sync Rule (Context)

Every plugin version appears in exactly two places that **must match**:
1. `plugins/<name>/.claude-plugin/plugin.json` → `"version"`
2. `.claude-plugin/marketplace.json` → `plugins[].version` for that plugin entry

Mismatch = install failure.

## Steps to Add

Insert a new `## Bumping a Plugin Version` section into `.claude/rules/marketplace.md` with two subsections:

### When to bump

| Bump | Triggers |
|------|----------|
| **PATCH** | Bug fix in a command/skill/hook, typo or clarification in instructions, correcting metadata (homepage, keywords) |
| **MINOR** | New command added, new skill added, new agent/hook added — all backward compatible |
| **MAJOR** | Removing or renaming a command/skill/agent, changing command argument format, changing skill activation behavior, restructuring plugin directory |

### How to bump

1. **Edit `plugin.json`** — update `"version"` in `plugins/<name>/.claude-plugin/plugin.json`
2. **Edit `marketplace.json`** — update the matching `"version"` in `.claude-plugin/marketplace.json` under the same plugin entry
3. **Update changelog** — add entry to `plugins/<name>/CHANGELOG.md` (create if it doesn't exist)
4. **Verify sync** — run `grep -r '"version"' plugins/<name>/.claude-plugin/ .claude-plugin/marketplace.json` to confirm both values match
5. **Commit** — use `fix(plugins/<name>): bump version to X.Y.Z` (patch), `feat(...)` (minor), or note breaking change in body (major)

## Out of Scope

- `tests/fixtures/` — test fixture plugins; no version bump needed
- Marketplace-level version (`agentics-kit` v2.0.0) — separate from individual plugin versions; not covered here

## Verification

After editing `.claude/rules/marketplace.md`:
- Read the file to confirm the new section is clear and correctly placed
- Check that it cross-references the existing semver rules already in the file
