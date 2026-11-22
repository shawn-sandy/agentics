# Stop paying for a plugin catalog in every session

> Every session paid for CLAUDE.md before a single word of the task was read. Its 13-row plugin table was a hand-maintained third copy of data that `marketplace.json` owns and README.md already generates. Replacing it with a one-line-per-plugin table cut the always-loaded context from 1,656 words to under 800.

<!-- generated:start -->

**Status:** Shipped 2026-07-27 **Plan:** [replace-claude-md-plugin-table.md](plans/replace-claude-md-plugin-table.md)
**Type:** docs

## What shipped

- Audited all 13 plugin table rows in CLAUDE.md against their `kit/plugins/<name>/README.md`, identifying orphaned sentences present only in CLAUDE.md.
- Ported any orphaned detail into the owning plugin's `README.md` before cutting.
- Rewrote CLAUDE.md's plugin section as a `| Plugin | Type | Purpose |` table with each purpose held to one line under 15 words, plus a pointer to README.md's generated Plugin Reference Table and to `kit/plugins/<name>/README.md` for detail.
- Added `tests/plugins/test-claude-md-budget.sh`: asserts CLAUDE.md is under 800 words, every plugin in `marketplace.json` appears in the table, and no row exceeds 25 words.
- Wired the new test into `.github/workflows/check-plugin-versions.yml`.
- For any plugin whose README was modified, bumped its version in `.claude-plugin/marketplace.json` by a patch level and added a `CHANGELOG.md` entry noting the migrated documentation.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `CLAUDE.md` | Plugin table collapsed, README pointer added | Modified |
| `kit/plugins/*/README.md` | Received any detail found only in CLAUDE.md | Modified (conditional) |
| `tests/plugins/test-claude-md-budget.sh` | Budget and coverage objective test | Created |
| `.github/workflows/check-plugin-versions.yml` | Wire test-claude-md-budget.sh | Modified |
| `.claude-plugin/marketplace.json` | Patch bumps for plugins with modified READMEs | Modified (conditional) |

## How it works

**Always-loaded cost**: CLAUDE.md is loaded before every session. Its plugin table had grown to essay length — the `artifact-tools` row alone ran ~250 words describing every skill's internals, a hand-maintained third copy of data already in `marketplace.json` and each plugin's README.

**Progressive disclosure**: The new one-line table gives Claude enough to pick the right plugin; `kit/plugins/<name>/README.md` carries everything else and is loaded only when that plugin is opened. The generated Plugin Reference Table in README.md is the source of truth for plugin metadata.

**Budget gate**: `test-claude-md-budget.sh` uses `wc -w` to enforce the 800-word threshold, `grep` to confirm every marketplace plugin appears, and a word-count-per-row check for the 25-word row ceiling. Temporarily padding a row to 40 words makes it exit 1, confirming the check is not a tautology.

## How to use it

CLAUDE.md is loaded automatically. To verify the budget is maintained: `bash tests/plugins/test-claude-md-budget.sh`. To add a new plugin, add one row under 25 words to the table and update `marketplace.json`.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| — | 2026-07-27 | docs: replace paragraph-length CLAUDE.md plugin table with one-line-per-plugin table, add budget test |

<!-- generated:end -->

## References

- Plan: [replace-claude-md-plugin-table.md](plans/replace-claude-md-plugin-table.md)
