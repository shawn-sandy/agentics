# Stop Paying for a Plugin Catalog in Every Session

> Every session pays for CLAUDE.md before a single word of the task is read. Its 13-row plugin table is a hand-maintained third copy of data that marketplace.json owns and README.md already generates. Cutting it back to one line per plugin frees roughly 900 words of always-loaded context, and we will know it worked when CLAUDE.md drops under 800 words with every plugin still listed.

<!-- generated:start -->

**Status:** Shipped 2026-07-27  **Plan:** [replace-claude-md-plugin-table.md](plans/replace-claude-md-plugin-table.md)
**Type:** docs

## What shipped

- Audited all 13 plugin rows in CLAUDE.md against their `kit/plugins/<name>/README.md` files, identifying any detail present only in CLAUDE.md.
- Ported orphaned sentences into the owning plugin's README so no information was lost; bumped versions and added CHANGELOG entries for every plugin whose README was touched.
- Replaced CLAUDE.md's paragraph-length plugin table with a `| Plugin | Type | Purpose |` table holding one line per plugin (purpose under 15 words) and a pointer to README.md's generated Plugin Reference Table.
- Reduced CLAUDE.md word count from 1,656 to under 800 — freeing ~900 words of always-loaded context without removing any discoverable information.
- Added `tests/plugins/test-claude-md-budget.sh` asserting CLAUDE.md stays under 800 words, that every plugin name in the manifest appears in the table, and that no row exceeds 25 words.
- Wired the new test into `.github/workflows/check-plugin-versions.yml`.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `CLAUDE.md` | Always-loaded project context — collapsed plugin table, added README pointer | Modified |
| `kit/plugins/*/README.md` | Plugin documentation — received any detail found only in CLAUDE.md | Modified |
| `tests/plugins/test-claude-md-budget.sh` | Test — asserts word budget, full plugin coverage, row length | Created |
| `.github/workflows/check-plugin-versions.yml` | CI workflow — new step running the budget test | Modified |

## How it works

`CLAUDE.md` is loaded in full at the start of every Claude Code session, before the first word of a task is processed. The Claude 5 context-engineering guidance is explicit that this file should carry repository gotchas — non-obvious constraints and traps — not feature descriptions or obvious facts. At 1,656 words, the repository's `CLAUDE.md` was dominated by a 13-row plugin table whose longest row ran about 250 words describing `artifact-tools` skill internals in detail. That detail was not unique: `.claude-plugin/marketplace.json` is the source of truth, `scripts/build-readme-table.mjs` already regenerates a table into `README.md` from it, and all 13 plugins carry their own `README.md` files averaging 1,800 words each.

The first step was a row-by-row audit comparing each CLAUDE.md plugin entry against its plugin's README. The audit produced a scratch file naming every plugin as either "covered" or listing the specific sentences present only in CLAUDE.md. Where orphaned detail was found — real constraints that existed nowhere else — it was ported into the plugin's README before anything was cut from CLAUDE.md. Any plugin whose README was modified received a patch-level version bump and a CHANGELOG entry, because `scripts/check-plugin-versions.mjs` treats any path under `kit/plugins/<name>/` as a plugin change.

With zero orphans confirmed, CLAUDE.md's plugin table was collapsed to the `| Plugin | Type | Purpose |` format with the purpose column capped at 15 words, plus a single sentence pointing at README.md's generated Plugin Reference Table and at `kit/plugins/<name>/README.md` for per-plugin detail. The word count dropped below 800 — well within the objective's threshold — while every plugin name still appears in the table.

The new test `tests/plugins/test-claude-md-budget.sh` makes the reduction permanent. It counts words with the same Python-based counter used across the plugin test suite (locale-independent), checks every plugin name from `marketplace.json` against the file, and fails if any row exceeds 25 words. A falsifiability check confirmed: padding a row to 40 words makes it exit 1.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| 0fd7b67 | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |

<!-- generated:end -->

## References

- Plan: [replace-claude-md-plugin-table.md](plans/replace-claude-md-plugin-table.md)
