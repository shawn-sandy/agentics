# Stop paying for a plugin catalog in every session

> Replace CLAUDE.md's paragraph-length plugin table with a one-line-per-plugin table plus a pointer to README.md's generated table, cutting always-loaded context from 1,656 words to under 800.

<!-- generated:start -->

**Status:** Shipped 2026-08-12 **Plan:** [replace-claude-md-plugin-table](plans/replace-claude-md-plugin-table.md)
**Type:** docs

## What shipped

- Audited all 13 plugin table rows in `CLAUDE.md` against per-plugin `README.md` files; any detail found only in `CLAUDE.md` was ported to the owning plugin's README before the row was cut.
- Collapsed `CLAUDE.md`'s plugin table to `| Plugin | Type | Purpose |` format with purpose held to one line under 15 words.
- Replaced the removed prose with a single sentence pointing at README.md's generated Plugin Reference Table and at `kit/plugins/<name>/README.md` for per-plugin detail.
- Reduced `CLAUDE.md` from 1,656 words to 441 words (confirmed by `wc -w`).
- Added `tests/plugins/test-claude-md-budget.sh` asserting CLAUDE.md stays under 800 words with every plugin named.
- Wired the new test into `.github/workflows/check-plugin-versions.yml`.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `CLAUDE.md` | Plugin table collapsed; README pointer added | Modified |
| `kit/plugins/*/README.md` | Received orphaned detail from CLAUDE.md rows (where applicable) | Modified |
| `tests/plugins/test-claude-md-budget.sh` | Smoke test — under 800 words, all plugins named, no row over 25 words | Created |
| `.github/workflows/check-plugin-versions.yml` | CI step added for the new test | Modified |

## How it works

**Row-by-row audit before cutting anything.** Each of the 13 plugin table rows in `CLAUDE.md` was compared against the owning plugin's `kit/plugins/<name>/README.md`. For each row, the audit produced either "covered" (the detail already exists in the plugin README) or a list of sentences present only in `CLAUDE.md`. Only after this audit was any text moved or removed.

**Porting orphaned detail.** Any sentence found only in `CLAUDE.md` was ported into the owning plugin's `README.md` under its existing structure. Because `scripts/check-plugin-versions.mjs` treats any path under `kit/plugins/<name>/` as a plugin change (including `README.md`), each plugin whose README was modified received a PATCH bump in `.claude-plugin/marketplace.json` with a matching CHANGELOG entry. Plugins whose READMEs were already comprehensive required no README edits and no bumps.

**Collapsing the table.** Once all orphaned detail was ported, `CLAUDE.md`'s plugin table was rewritten to a compact `| Plugin | Type | Purpose |` format. Each Purpose cell is held to one line under 15 words — enough for Claude to pick the right plugin; all further detail is on demand via the generated Plugin Reference Table in `README.md` and via each plugin's own README.

**Adding the guard test.** `tests/plugins/test-claude-md-budget.sh` asserts three things: `CLAUDE.md` word count is under 800, every plugin name in `marketplace.json` appears in `CLAUDE.md`, and no table row exceeds 25 words. The test was verified as non-tautological by temporarily padding a row past 25 words and confirming exit 1 before reverting. The 800-word ceiling is the objective's own threshold, so the test fails exactly when the objective fails.

**CI wiring.** The new test was added to `.github/workflows/check-plugin-versions.yml` alongside the existing plugin test steps, ensuring the word budget is enforced on every PR.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `df49b6d` | 2026-08-12 | feat(settings-sync): restore onto a new machine via clone URL (1.1.0) (#548) |

<!-- generated:end -->

## References

- Plan: [replace-claude-md-plugin-table](plans/replace-claude-md-plugin-table.md)
- Context engineering guidance: https://claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models
- Generated plugin table script: `scripts/build-readme-table.mjs`
