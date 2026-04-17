# Document Plugin Version Bump Process

> Adds a "Bumping a Plugin Version" section to `.claude/rules/marketplace.md`, documenting the two-file version sync requirement and a clear when-to-bump guide.

<!-- generated:start -->

**Status:** Shipped 2026-02-23   **Plan:** [document-plugin-version-bump-process.md](plans/document-plugin-version-bump-process.md)   **Type:** artifact

## What shipped

- New `## Bumping a Plugin Version` section added to `.claude/rules/marketplace.md`.
- When-to-bump table: PATCH (bug fix, typo, metadata correction), MINOR (new command/skill/agent/hook added), MAJOR (removing/renaming a command/skill/agent, changing argument format or activation behavior).
- How-to-bump steps: edit `plugin.json`, edit `marketplace.json`, update CHANGELOG, verify sync with `grep`, commit with conventional message.
- Out-of-scope notes: `tests/fixtures/` and marketplace-level version are separate concerns.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `.claude/rules/marketplace.md` | Marketplace authoring rules | Modified |

## How it works

The version bump process requires keeping two files in sync: `plugins/<name>/.claude-plugin/plugin.json` (the `"version"` field) and `.claude-plugin/marketplace.json` (the `version` in the matching plugin entry). A mismatch causes install failures when users run `/plugin install`. The documentation codifies this two-file rule and adds a verification step — `grep -r '"version"' plugins/<name>/.claude-plugin/ .claude-plugin/marketplace.json` — so developers can confirm sync before committing.

The when-to-bump table is now referenced by CLAUDE.md and cited in the marketplace rules, making it the authoritative guide for version bump decisions across all plugins in the repo.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `6b9fab3` | 2026-03-26 | Merge pull request #51 from shawn-sandy/docs/plan-interview-upgrade |
| `9c70a52` | 2026-03-30 | chore(docs/plans): add YAML frontmatter status to 83 plan files |

<!-- generated:end -->

## References

- Plan: [document-plugin-version-bump-process.md](plans/document-plugin-version-bump-process.md)
- Rule file: [.claude/rules/marketplace.md](../.claude/rules/marketplace.md)
