# Fix Plugin Version Hygiene

> Removes the `version` field from all 12 `plugin.json` files so that version is managed solely in `marketplace.json`, aligning with official Anthropic documentation; updates authoring rules and CLAUDE.md to reflect the single-source policy.

<!-- generated:start -->

**Status:** Shipped 2026-03-11   **Plan:** [fix-plugin-version-hygiene.md](plans/fix-plugin-version-hygiene.md)   **Type:** standard

## What shipped

- `"version"` field removed from all 12 `plugin.json` files — version is now managed exclusively in `marketplace.json`.
- `.claude/rules/marketplace.md` rewritten: removed the "Version Synchronization" note requiring both files match; updated "Bumping a Plugin Version" to show only `marketplace.json` edits; updated verify command to check only `marketplace.json`; added "Common Pitfall" warning against setting version in both files.
- `CLAUDE.md` convention updated to reflect single-source version management.
- `hello-world/CHANGELOG.md` created with initial `v1.0.0` entry (previously missing).

> This plan supersedes the two-file sync rule introduced in `document-plugin-version-bump-process`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `plugins/hello-world/.claude-plugin/plugin.json` | Plugin manifest | Modified (version removed) |
| `plugins/dev-tools/.claude-plugin/plugin.json` | Plugin manifest | Modified (version removed) |
| `plugins/claude-md-optimizer/.claude-plugin/plugin.json` | Plugin manifest | Modified (version removed) |
| `plugins/code-review/.claude-plugin/plugin.json` | Plugin manifest | Modified (version removed) |
| `plugins/plan-interview/.claude-plugin/plugin.json` | Plugin manifest | Modified (version removed) |
| `plugins/wcag-compliance-reviewer/.claude-plugin/plugin.json` | Plugin manifest | Modified (version removed) |
| `plugins/skill-reviewer/.claude-plugin/plugin.json` | Plugin manifest | Modified (version removed) |
| `plugins/code-testing-agent/.claude-plugin/plugin.json` | Plugin manifest | Modified (version removed) |
| `plugins/git-agent/.claude-plugin/plugin.json` | Plugin manifest | Modified (version removed) |
| `plugins/agent-creator/.claude-plugin/plugin.json` | Plugin manifest | Modified (version removed) |
| `plugins/react-perf-analyzer/.claude-plugin/plugin.json` | Plugin manifest | Modified (version removed) |
| `plugins/marketplace-builder/.claude-plugin/plugin.json` | Plugin manifest | Modified (version removed) |
| `.claude/rules/marketplace.md` | Marketplace authoring rules | Modified |
| `CLAUDE.md` | Project instructions | Modified |
| `plugins/hello-world/CHANGELOG.md` | Version history | Created |

## How it works

The official Anthropic plugin marketplace documentation states that for relative-path plugins (all 12 plugins in this repo use `git-subdir` sources), version should be set only in `marketplace.json`. When `plugin.json` also declares a version, it silently overrides the marketplace version during install, potentially causing the marketplace-pinned version to be ignored without any warning.

Prior to this fix, all plugins had `"version"` in both files and the repo's authoring rules actively enforced keeping them in sync. This plan removed the source of conflict by deleting the `version` field from every `plugin.json`, making `marketplace.json` the single authoritative source. The authoring rules were updated to document this policy and flag dual-version declarations as a common pitfall.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `6b9fab3` | 2026-03-26 | Merge pull request #51 from shawn-sandy/docs/plan-interview-upgrade |
| `9c70a52` | 2026-03-30 | chore(docs/plans): add YAML frontmatter status to 83 plan files |
| `e15fba2` | 2026-04-04 | refactor: rename agentics/ marketplace subtree to kit/ |

<!-- generated:end -->

## References

- Plan: [fix-plugin-version-hygiene.md](plans/fix-plugin-version-hygiene.md)
- Supersedes: [document-plugin-version-bump-process.md](document-plugin-version-bump-process.md)
