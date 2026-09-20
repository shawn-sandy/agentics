# Stop paying for a plugin catalog in every session

> Every session pays for CLAUDE.md before a single word of the task is read. Its 13-row plugin table is a hand-maintained third copy of data that marketplace.j...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [replace-claude-md-plugin-table.md](plans/replace-claude-md-plugin-table.md)
**Type:** docs

## What shipped

- Audit each of the 13 plugin table rows in CLAUDE.md against that plugin's `kit/plugins/<name>/README.md`, writing the orphan list to a scratch file.
- Port each orphaned sentence from Step 1 into the owning plugin's README.md under its existing structure.
- Rewrite CLAUDE.md's plugin table to `| Plugin | Type | Purpose |` with the purpose held to one line under 15 words, and replace the removed prose with a single sentence pointing at README.md's generated Plugin Reference Table and at `kit/plugins/<name>/README.md` for detail.
- Write `tests/plugins/test-claude-md-budget.sh` asserting CLAUDE.md is under 800 words, that every plugin name in `marketplace.json` appears in CLAUDE.md, and that no table row exceeds 25 words.
- Add the new test to `.github/workflows/check-plugin-versions.yml` alongside the existing `tests/plugins/test-build-skill.sh` step.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `CLAUDE.md` | collapse the plugin table, add the README pointer | Modified |
| `kit/plugins/*/README.md` | receive any detail found only in CLAUDE.md | Modified |
| `tests/plugins/test-claude-md-budget.sh` | objective test | Created |
| `.github/workflows/check-plugin-versions.yml` | wire the new test | Modified |

## How it works

Replace CLAUDE.md's paragraph-length plugin table with a one-line-per-plugin table plus a pointer to README.md's generated table, cutting the repo's always-loaded context from 1,656 words to under 800.

The Claude 5 context-engineering guidance is explicit that CLAUDE.md should carry repository *gotchas*, not obvious facts, and that detail belongs behind progressive disclosure rather than in the always-loaded layer. This repo's CLAUDE.md is 1,656 words and the 13-row plugin table is the bulk of it — the `artifact-tools` row alone runs about 250 words describing every skill's

The implementation proceeded through the following steps: Audit each of the 13 plugin table rows in CLAUDE.md against that plugin's `kit/plugins/<name>/README.md`, writing the orphan list to a scratch file. Why: a row that documents a real constraint found nowhere else must be preserved, and only a row-by-row comparison distinguishes that from a feature restatement. Verify: the scratch file names every plugin and, for each, either "covered" or the specific sentences present only in CLAUDE.md.; Port each orphaned sentence from Step 1 into the owning plugin's README.md under its existing structure. Why: the README is what Claude reads when it opens that plugin, so detail moved there stays discoverable without being loaded every session. Verify: re-run the Step 1 audit and confirm zero orphans remain.; Rewrite CLAUDE.md's plugin table to `| Plugin | Type | Purpose |` with the purpose held to one line under 15 words, and replace the removed prose with a single sentence pointing at README.md's generated Plugin Reference Table and at `kit/plugins/<name>/README.md` for detail. Why: one line per plugin is enough for Claude to pick the right plugin; the generated table and per-plugin READMEs carry everything else on demand. Verify: `wc -w CLAUDE.md` reports under 800, and every plugin in `.claude-plugin/marketplace.json` still appears in the table.; Write `tests/plugins/test-claude-md-budget.sh` asserting CLAUDE.md is under 800 words, that every plugin name in `marketplace.json` appears in CLAUDE.md, and that no table row exceeds 25 words. Why: 800 is the objective's own threshold, so the test fails whenever the objective fails — a looser ceiling would let the suite pass on a CLAUDE.md that never met the goal. Verify: `bash tests/plugins/test-claude-md-budget.sh` exits 0; temporarily padding a row to 40 words makes it exit 1.; Add the new test to `.github/workflows/check-plugin-versions.yml` alongside the existing `tests/plugins/test-build-skill.sh` step. Why: a test that only runs locally stops running. Verify: the workflow file names `test-claude-md-budget.sh` and `yamllint` or a YAML parse of the file succeeds..

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates (#573) |

<!-- generated:end -->

## References

- Plan: [replace-claude-md-plugin-table.md](plans/replace-claude-md-plugin-table.md)
