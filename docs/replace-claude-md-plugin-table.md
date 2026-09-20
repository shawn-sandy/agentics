# Stop paying for a plugin catalog in every session

> Every session pays for CLAUDE.md before a single word of the task is read. Its 13-row plugin table is a hand-maintained third copy of data that marketplace.j...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [replace-claude-md-plugin-table.md](plans/replace-claude-md-plugin-table.md)
**Type:** docs

## What shipped

- Audit each of the 13 plugin table rows in CLAUDE.md against that plugin's `kit/plugins/<name>/README.md`, writing the...
- Port each orphaned sentence from Step 1 into the owning plugin's README.md under its existing structure.
- Rewrite CLAUDE.md's plugin table to `| Plugin | Type | Purpose |` with the purpose held to one line under 15 words, a...
- Write `tests/plugins/test-claude-md-budget.sh` asserting CLAUDE.md is under 800 words, that every plugin name in `mar...
- Add the new test to `.github/workflows/check-plugin-versions.yml` alongside the existing `tests/plugins/test-build-sk...

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `CLAUDE.md` | collapse the plugin table, add the README pointer | Modified |
| `kit/plugins/*/README.md` | receive any detail found only in CLAUDE.md | Modified |
| `tests/plugins/test-claude-md-budget.sh` | objective test | Created |
| `.github/workflows/check-plugin-versions.yml` | wire the new test | Modified |

## How it works

Replace CLAUDE.md's paragraph-length plugin table with a one-line-per-plugin table plus a pointer to README.md's generated table, cutting the repo's always-loaded context from 1,656 words to under 800.

The Claude 5 context-engineering guidance is explicit that CLAUDE.md should carry repository *gotchas*, not obvious facts, and that detail belongs behind progressive disclosure rather than in the always-loaded layer. This repo's CLAUDE.md is 1,656 words and the 13-row plugin table is the bulk of it — the

The implementation proceeded through these steps: Audit each of the 13 plugin table rows in CLAUDE.md against that plugin's `kit/plugins/<name>/README.md`, writing the...; Port each orphaned sentence from Step 1 into the owning plugin's README.md under its existing structure. Why: the REA...; Rewrite CLAUDE.md's plugin table to `| Plugin | Type | Purpose |` with the purpose held to one line under 15 words, a...; Write `tests/plugins/test-claude-md-budget.sh` asserting CLAUDE.md is under 800 words, that every plugin name in `mar...; Add the new test to `.github/workflows/check-plugin-versions.yml` alongside the existing `tests/plugins/test-build-sk....

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates ( |

<!-- generated:end -->

## References

- Plan: [replace-claude-md-plugin-table.md](plans/replace-claude-md-plugin-table.md)
