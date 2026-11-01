# Stop paying for a plugin catalog in every session

> Replaced CLAUDE.md's paragraph-length plugin table with a one-line-per-plugin table, cutting always-loaded context from 1,656 words to under 800.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [replace-claude-md-plugin-table.md](plans/replace-claude-md-plugin-table.md)
**Type:** docs

## What shipped

- Audited all 13 plugin table rows in CLAUDE.md against their per-plugin READMEs to find any detail present only in CLAUDE.md (none were orphaned — all coverage existed in the plugin READMEs).
- Rewrote CLAUDE.md's plugin table to `| Plugin | Type | Purpose |` with each purpose capped at ~15 words, plus a pointer to README.md's generated Plugin Reference Table.
- Added `tests/plugins/test-claude-md-budget.sh` asserting CLAUDE.md is under 800 words, every plugin in `marketplace.json` appears in it, and no table row exceeds 25 words.
- Wired the new test into `.github/workflows/check-plugin-versions.yml`.
- CLAUDE.md dropped from 1,656 words to 449 words — well under the 800-word objective.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `CLAUDE.md` | Repo configuration — collapsed plugin table | Modified |
| `tests/plugins/test-claude-md-budget.sh` | Smoke test — CLAUDE.md context budget | Created |
| `.github/workflows/check-plugin-versions.yml` | CI — new test step | Modified |

## How it works

Every Claude Code session loads CLAUDE.md in full before processing any task. The 13-row plugin table had grown to essay length — the `artifact-tools` row alone was ~250 words describing individual skill internals — making the repo's always-loaded context 1,656 words, dominated by data that the plugin READMEs already cover in full.

The plan audited each row against its plugin README before cutting anything. Since all 13 READMEs already averaged 1,800 words and covered every row's content, no information needed to be migrated. The table was rewritten to a single-line format (`| Plugin | Type | Purpose |`) with purposes under 15 words, plus a reference to `README.md`'s generated Plugin Reference Table for detail.

The objective test guards against regression: it fails if CLAUDE.md exceeds 800 words, if any plugin name from `marketplace.json` is missing, or if any row exceeds 25 words. Since CLAUDE.md lives at the repo root (not under `kit/plugins/`), no marketplace version bump was required.

## How to use it

```bash
# Verify CLAUDE.md is within budget
bash tests/plugins/test-claude-md-budget.sh
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [replace-claude-md-plugin-table.md](plans/replace-claude-md-plugin-table.md)
