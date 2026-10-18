# Collapse the CLAUDE.md plugin table to one-liner format

> Reduces the always-loaded CLAUDE.md context by collapsing the 13-row paragraph-length plugin table to a one-line-per-plugin format, cutting the always-loaded word count from 1,656 to under 800.

<!-- generated:start -->

**Status:** Shipped 2026-07-27  **Plan:** [replace-claude-md-plugin-table.md](plans/replace-claude-md-plugin-table.md)
**Type:** docs

## What shipped

- Audited each CLAUDE.md plugin row against its `kit/plugins/<name>/README.md` for orphaned sentences not present in the README.
- Ported any orphaned sentences to the relevant plugin READMEs and applied PATCH version bumps to every plugin whose README was modified.
- Rewrote the CLAUDE.md plugin table to a one-liner format: `| Plugin | Type | Purpose |` with a 15-word purpose cap per row, plus a pointer to each plugin's README for full detail.
- Added `tests/plugins/test-claude-md-budget.sh` — asserts the CLAUDE.md word count stays under 800, every marketplace plugin appears in the table, and no row exceeds 25 words.
- Wired `test-claude-md-budget.sh` into `.github/workflows/check-plugin-versions.yml`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `CLAUDE.md` | Root instructions | Modified |
| `kit/plugins/*/README.md` | Plugin documentation | Modified (orphan migrations) |
| `.claude-plugin/marketplace.json` | Marketplace versions | Modified (PATCH bumps) |
| `tests/plugins/test-claude-md-budget.sh` | Budget guard test | Created |
| `.github/workflows/check-plugin-versions.yml` | CI configuration | Modified |

## How it works

Every session that opens any `kit/plugins/**` file auto-loads CLAUDE.md, which means the plugin table's word count burns context on every plugin read. The previous table described each plugin in a short paragraph, totalling 1,656 words across 13 rows — over half the file.

The one-liner format (`| Plugin | Type | Purpose |`) caps each purpose at 15 words. Full detail moved to each plugin's own README, which Claude Code only loads when that plugin's files are open. The net effect: always-loaded context drops below 800 words while per-plugin detail becomes richer and lives closer to the code it describes.

The audit step came first to avoid losing sentences that existed only in CLAUDE.md. Any orphaned description that wasn't reflected in the plugin README was ported there before the CLAUDE.md table was rewritten, so nothing was silently discarded.

The budget test guards against regrowth: it fails the PR if CLAUDE.md exceeds 800 words, if any marketplace plugin is missing from the table, or if any row exceeds 25 words. Wiring it into CI ensures the constraint survives future edits.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|

<!-- generated:end -->

## References

- Plan: [replace-claude-md-plugin-table.md](plans/replace-claude-md-plugin-table.md)
