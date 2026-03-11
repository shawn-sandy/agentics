# Plan: Fix Plugin Version Hygiene

## Context

The repo's version management contradicts [official Anthropic docs](https://code.claude.com/docs/en/plugin-marketplaces). Currently, every plugin has `version` in **both** `plugin.json` and `marketplace.json`, and our rules enforce keeping them in sync. But the official docs explicitly warn:

> "When possible, avoid setting the version in both places. The plugin manifest always wins silently, which can cause the marketplace version to be ignored. **For relative-path plugins, set the version in the marketplace entry.**"

All 12 plugins use relative paths (`./plugins/...`), so the correct approach is: **version lives only in `marketplace.json`**.

## Current State

- 12 plugins with version duplicated in both `plugin.json` and `marketplace.json`
- `.claude/rules/marketplace.md` incorrectly enforces dual-version sync
- `CLAUDE.md` references version matching as a convention
- `hello-world` is missing a `CHANGELOG.md`

## Steps

### 1. Remove `version` from all `plugin.json` files (12 files)

Remove the `"version"` field from each plugin's `.claude-plugin/plugin.json`. The version will be managed solely in `marketplace.json`.

Files to edit:
- `plugins/hello-world/.claude-plugin/plugin.json`
- `plugins/dev-tools/.claude-plugin/plugin.json`
- `plugins/claude-md-optimizer/.claude-plugin/plugin.json`
- `plugins/code-review/.claude-plugin/plugin.json`
- `plugins/plan-interview/.claude-plugin/plugin.json`
- `plugins/wcag-compliance-reviewer/.claude-plugin/plugin.json`
- `plugins/skill-reviewer/.claude-plugin/plugin.json`
- `plugins/code-testing-agent/.claude-plugin/plugin.json`
- `plugins/git-agent/.claude-plugin/plugin.json`
- `plugins/agent-creator/.claude-plugin/plugin.json`
- `plugins/react-perf-analyzer/.claude-plugin/plugin.json`
- `plugins/marketplace-builder/.claude-plugin/plugin.json`

### 2. Update `.claude/rules/marketplace.md`

Rewrite the version management sections to align with official docs:

- **"Registering a Plugin" example**: keep `version` in the marketplace entry (already correct)
- **Remove** the "Version Synchronization" note that says versions must match in both files
- **Rewrite "Bumping a Plugin Version"** section:
  - Change "appears in exactly two places" to "lives in `marketplace.json`"
  - Remove step 1 ("Edit `plugin.json`") from the "How to bump" steps
  - Update the verify command to only check `marketplace.json`
  - Add a note: for relative-path plugins, do NOT add version to `plugin.json` (per official docs)
- **Update "Common Pitfalls"**:
  - Remove "Version mismatch between `marketplace.json` and `plugin.json`"
  - Add "Setting version in both `plugin.json` and `marketplace.json` — for relative-path plugins, set it only in `marketplace.json`"

### 3. Update `CLAUDE.md`

Remove or update the convention about version matching between `marketplace.json` and `plugin.json`.

### 4. Add missing `CHANGELOG.md` for `hello-world`

Create `plugins/hello-world/CHANGELOG.md` with a `v1.0.0` initial release entry.

## Verification

1. Run `claude plugin validate .` to confirm all plugins still validate
2. Verify no `plugin.json` contains a `"version"` field:
   ```bash
   grep -r '"version"' plugins/*/.claude-plugin/plugin.json
   ```
   (should return no results)
3. Verify all versions still present in `marketplace.json`:
   ```bash
   grep '"version"' .claude-plugin/marketplace.json
   ```
4. Confirm `hello-world` has a CHANGELOG: `ls plugins/hello-world/CHANGELOG.md`
