# Remove Unsupported Fields from marketplace.json Plugin Entries

> Cleans unsupported fields (`author`, `license`, `keywords`, `homepage`, `repository`) from all plugin entries in `.claude-plugin/marketplace.json`, leaving only schema-valid fields.

<!-- generated:start -->

**Status:** Shipped 2026-02-23   **Plan:** [cleanup-marketplace-json-unsupported-fields.md](plans/cleanup-marketplace-json-unsupported-fields.md)   **Type:** artifact

## What shipped

- Removed `author`, `license`, `keywords`, `homepage`, and `repository` from all plugin entries in `.claude-plugin/marketplace.json`.
- Each plugin entry reduced to exactly 6 valid fields: `name`, `source`, `version`, `description`, `category`, `tags`.
- Fix unblocked marketplace registration (`/plugin marketplace add`) which was failing on the unsupported fields.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `.claude-plugin/marketplace.json` | Marketplace registry | Modified |

## How it works

The marketplace.json schema allows only `name`, `source`, `version`, `description`, `category`, and `tags` at the plugin entry level. Fields like `author`, `license`, `keywords`, `homepage`, and `repository` are valid in `plugin.json` but not in marketplace entries — including them caused validation failures when Claude Code attempted to register the marketplace.

The cleanup removed the 5 unsupported fields from all five plugin entries that existed at the time (`hello-world`, `dev-tools`, `claude-md-optimizer`, `code-review`, `plan-interview`). The `tags` field was preserved (it is valid in marketplace entries); `keywords` was removed since it duplicates tags and is not in the schema.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `6b9fab3` | 2026-03-26 | Merge pull request #51 from shawn-sandy/docs/plan-interview-upgrade |
| `9c70a52` | 2026-03-30 | chore(docs/plans): add YAML frontmatter status to 83 plan files |

<!-- generated:end -->

## References

- Plan: [cleanup-marketplace-json-unsupported-fields.md](plans/cleanup-marketplace-json-unsupported-fields.md)
