# Stop paying for a plugin catalog in every session

> Replaces CLAUDE.md's paragraph-length 13-row plugin table with a one-line-per-plugin table plus a pointer to README.md's generated table, cutting always-loaded context from 1,656 words to under 800.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [replace-claude-md-plugin-table](plans/replace-claude-md-plugin-table.md)
**Type:** docs

## What shipped

- Audited all 13 plugin table rows in CLAUDE.md against each plugin's `kit/plugins/<name>/README.md`, identifying orphaned detail
- Ported each orphaned sentence from the CLAUDE.md table into the owning plugin's README.md under its existing structure
- Rewrote CLAUDE.md's plugin table to `| Plugin | Type | Purpose |` with one line per plugin (≤15 words per purpose)
- Added a sentence pointing at README.md's generated Plugin Reference Table and at each `kit/plugins/<name>/README.md` for detail
- Bumped plugins whose README.md received migrated content (patch level, docs-only change)
- Created `tests/plugins/test-claude-md-budget.sh` asserting CLAUDE.md stays under 800 words, names every registered plugin, and limits table rows to 25 words
- Added the new test to `.github/workflows/check-plugin-versions.yml`

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `CLAUDE.md` | Repo root — collapsed plugin table, README pointer | Modified |
| `kit/plugins/*/README.md` | Plugin docs — received migrated detail | Modified |
| `kit/plugins/*/CHANGELOG.md` | Release history — docs-only patch bumps | Modified |
| `tests/plugins/test-claude-md-budget.sh` | Smoke test — word count, plugin coverage, row budget | Created |
| `.github/workflows/check-plugin-versions.yml` | CI — new budget test step | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry — patch bumps for touched plugins | Modified |

## How it works

The Claude 5 context-engineering guidance is explicit that CLAUDE.md should carry repository *gotchas*, not obvious facts, and that detail belongs behind progressive disclosure rather than in the always-loaded layer. CLAUDE.md's 13-row plugin table had drifted into essays — the `artifact-tools` row alone ran ~250 words describing every skill's internals — while the generated table in README.md and each plugin's own README averaged 1,800 words of current documentation.

The audit process: for each of the 13 rows, every sentence in the CLAUDE.md row was compared against that plugin's README to determine whether the detail was "covered" (the README already said it) or "orphaned" (the README did not). Only orphaned sentences were ported; covered sentences were simply dropped. After porting, a re-run of the audit confirmed zero orphans remained.

The re-rewritten CLAUDE.md table uses a three-column `| Plugin | Type | Purpose |` format. Each purpose is held to one line under 15 words — enough for Claude to select the right plugin at invocation time. Everything beyond that lives in the README, which Claude can read on demand when it opens a plugin.

`test-claude-md-budget.sh` enforces the objective's own threshold (800 words) rather than the current word count, making the test fail whenever CLAUDE.md regresses to the old verbosity, not just when it changes. The test also verifies that every plugin name from `marketplace.json` appears in the table (no dropped rows) and that no table row exceeds 25 words (no row re-expanding into prose). Wiring it into CI means a future CLAUDE.md edit that exceeds the budget fails the pipeline before merge.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [replace-claude-md-plugin-table](plans/replace-claude-md-plugin-table.md)
