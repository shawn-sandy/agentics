# Stop paying for a plugin catalog in every session

> Replaced CLAUDE.md's paragraph-length 13-plugin table with a one-line-per-plugin table plus a pointer to README.md, cutting always-loaded context from 1,656 words to under 800.

<!-- generated:start -->

**Status:** Shipped 2026-08-15 **Plan:** [replace-claude-md-plugin-table.md](plans/replace-claude-md-plugin-table.md)
**Type:** docs

## What shipped

- Audited each of the 13 plugin rows in CLAUDE.md against its `kit/plugins/<name>/README.md` and identified any constraint present only in CLAUDE.md (not duplicated in the plugin README).
- Ported any orphaned sentences into the owning plugin README under its existing structure (kept detail discoverable without loading it every session).
- Bumped version in `.claude-plugin/marketplace.json` and added a CHANGELOG entry for every plugin whose README was actually modified (conditional on step 2 finding orphans).
- Rewrote CLAUDE.md's plugin table to `| Plugin | Type | Purpose |` with the purpose held to one line under 15 words, and replaced the removed prose with a single pointer sentence to README.md's generated Plugin Reference Table.
- Added `tests/plugins/test-claude-md-budget.sh` asserting CLAUDE.md is under 800 words, every plugin in `marketplace.json` appears in CLAUDE.md, and no table row exceeds 25 words.
- Wired the new test into `.github/workflows/check-plugin-versions.yml`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `CLAUDE.md` | Repo instructions — collapsed plugin table, added README pointer | Modified |
| `tests/plugins/test-claude-md-budget.sh` | New test — CLAUDE.md word count under 800, all plugins listed, no row over 25 words | Created |
| `.github/workflows/check-plugin-versions.yml` | CI — new step running `test-claude-md-budget.sh` | Modified |
| `.claude-plugin/marketplace.json` | Version bumps for any plugin whose README was modified | Modified |
| `kit/plugins/<name>/README.md` | Plugin READMEs modified for orphaned CLAUDE.md sentences (conditional on step 1 audit) | Modified |
| `kit/plugins/<name>/CHANGELOG.md` | CHANGELOG entries for any plugin whose README was modified | Modified |

## How it works

CLAUDE.md is loaded in full at the start of every Claude Code session before any task context is read. At 1,656 words, with the `artifact-tools` row alone running roughly 250 words describing every skill's internals, the plugin table was the dominant cost. The detail it carried was not unique: `scripts/build-readme-table.mjs` already regenerates a plugin table into README.md from `marketplace.json`, and all 13 plugins have their own READMEs averaging 1,800 words. The CLAUDE.md table was a hand-maintained third copy — which explains why its rows had drifted into essays while the generated README table stayed terse.

Step 1 performed a row-by-row audit, comparing each CLAUDE.md plugin entry against the corresponding `kit/plugins/<name>/README.md`. The goal was to distinguish a genuine gotcha — a non-obvious constraint that exists nowhere else — from a feature restatement that is already covered by the plugin's own documentation. The audit output a scratch file naming every plugin and either "covered" or the specific sentences found only in CLAUDE.md.

Step 2 ported any orphaned sentences into the owning plugin's README under its existing section structure. Moving detail to the README keeps it discoverable — Claude reads the plugin README when it opens that plugin — without paying for it in every session that does not touch that plugin.

Step 2b handled the version-bump consequence. Because `scripts/check-plugin-versions.mjs` counts any path under `kit/plugins/<name>/` as a plugin change (README files included), any plugin whose README was modified in step 2 needed a patch-level version bump and a CHANGELOG entry. If step 2 found no orphans and modified no README, this step was skipped entirely.

Step 3 rewrote CLAUDE.md's plugin section. The new table uses three columns (`Plugin`, `Type`, `Purpose`) with the Purpose field capped at one line and under 15 words. The removed prose was replaced with a single sentence pointing at README.md's generated Plugin Reference Table and at `kit/plugins/<name>/README.md` for per-plugin detail. After this step `wc -w CLAUDE.md` reports under 800 words, down from 1,656.

Step 4 added the objective test. `test-claude-md-budget.sh` counts CLAUDE.md's words with `wc -w`, verifies every plugin name from `marketplace.json` appears in the file, and checks that no table row exceeds 25 words. All three assertions are required to make the test non-trivially correct: the word ceiling alone could pass on a CLAUDE.md that dropped plugins entirely.

## How to use it

The test runs in CI and locally:

```bash
bash tests/plugins/test-claude-md-budget.sh
```

To confirm the test is not a tautology, temporarily pad a plugin row past 25 words, re-run, and confirm exit 1 before reverting. To add a new plugin to CLAUDE.md, add a single row with a purpose under 15 words and run the test to confirm the row budget holds.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `fd41fec` | 2026-08-22 | feat: prove merge readiness locally with a verify gate and verified-change skill (#594) |

<!-- generated:end -->

## References

- Plan: [replace-claude-md-plugin-table.md](plans/replace-claude-md-plugin-table.md)
