# Replace CLAUDE.md plugin table with one-line format

> Replaces the paragraph-style plugin table in CLAUDE.md with a compact one-line table, cutting the file from 1,656 words to under 800 and adding a test to enforce the budget going forward.

<!-- generated:start -->

**Status:** Shipped 2026-07-27 **Plan:** [replace-claude-md-plugin-table.md](plans/replace-claude-md-plugin-table.md)
**Type:** docs

## What shipped

- Replaced the multi-paragraph plugin reference table in `CLAUDE.md` with a compact one-line-per-plugin table.
- Reduced `CLAUDE.md` from 1,656 words to under 800 words.
- Added `tests/plugins/test-claude-md-budget.sh` to enforce the word budget in CI.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `CLAUDE.md` | Project instructions | Modified |
| `tests/plugins/test-claude-md-budget.sh` | Budget test | Created |

## How it works

CLAUDE.md is loaded into every session's context. At 1,656 words, the plugin table alone was consuming a significant fraction of the context budget and slowing session startup. The old format described each plugin with a short paragraph; the new format uses a `| Plugin | Purpose |` table with one row per plugin.

The `test-claude-md-budget.sh` test uses `wc -w` (or Python for portability across locales) to assert the file stays under 800 words. This prevents gradual re-inflation: documentation additions tend to compound over time, and without a mechanical check each small addition seems harmless.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [replace-claude-md-plugin-table.md](plans/replace-claude-md-plugin-table.md)
