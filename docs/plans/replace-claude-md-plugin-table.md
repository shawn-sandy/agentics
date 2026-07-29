---
status: completed
type: docs
created: 2026-07-27
effort: low
glance: Every session pays for CLAUDE.md before a single word of the task is read. Its 13-row plugin table is a hand-maintained third copy of data that marketplace.json owns and README.md already generates. Cutting it back to one line per plugin frees roughly 900 words of always-loaded context, and we will know it worked when CLAUDE.md drops under 800 words with every plugin still listed.
---

# Plan: Stop paying for a plugin catalog in every session

## Objective

Replace CLAUDE.md's paragraph-length plugin table with a one-line-per-plugin
table plus a pointer to README.md's generated table, cutting the repo's
always-loaded context from 1,656 words to under 800.

## Context

The Claude 5 context-engineering guidance is explicit that CLAUDE.md should
carry repository *gotchas*, not obvious facts, and that detail belongs behind
progressive disclosure rather than in the always-loaded layer. This repo's
CLAUDE.md is 1,656 words and the 13-row plugin table is the bulk of it — the
`artifact-tools` row alone runs about 250 words describing every skill's
internals.

That detail is not unique. `.claude-plugin/marketplace.json` is the source of
truth for plugin metadata, `scripts/build-readme-table.mjs` already
regenerates a plugin table into README.md from it (with a `--check` mode), and
all 13 plugins carry their own `README.md` averaging 1,800 words. The CLAUDE.md
table is a hand-maintained third copy, which is exactly why its rows have
drifted into essays while the generated one stayed terse.

Risk: a row may describe a genuine gotcha that exists nowhere else — a
non-obvious constraint rather than a feature list. Mitigated by Step 1, which
audits every row against its plugin README before anything is cut, and Step 2,
which ports orphaned detail into the owning README first.

One wrinkle on version bumps. `changedPlugins()` in
`scripts/check-plugin-versions.mjs` matches on `^kit/plugins/([^/]+)/` — it
counts *any* path under a plugin directory as a plugin change, README files
included. So if Step 2 finds orphaned detail and moves it into a plugin's
`README.md`, that plugin needs a `marketplace.json` version bump (patch, docs
only) and a `CHANGELOG.md` entry, or CI fails. Step 2b handles this
conditionally: zero orphans means zero bumps, which is the likely case since
all 13 READMEs already average 1,800 words.

CLAUDE.md itself lives at the repo root and never triggers a bump.

## Files

- CLAUDE.md (modified) — collapse the plugin table, add the README pointer
- kit/plugins/*/README.md (modified) — receive any detail found only in CLAUDE.md
- tests/plugins/test-claude-md-budget.sh (new) — objective test
- .github/workflows/check-plugin-versions.yml (modified) — wire the new test

## Steps

1. [x] Audit each of the 13 plugin table rows in CLAUDE.md against that plugin's `kit/plugins/<name>/README.md`, writing the orphan list to a scratch file. Why: a row that documents a real constraint found nowhere else must be preserved, and only a row-by-row comparison distinguishes that from a feature restatement. Verify: the scratch file names every plugin and, for each, either "covered" or the specific sentences present only in CLAUDE.md.
2. [x] Port each orphaned sentence from Step 1 into the owning plugin's README.md under its existing structure. Why: the README is what Claude reads when it opens that plugin, so detail moved there stays discoverable without being loaded every session. Verify: re-run the Step 1 audit and confirm zero orphans remain.
2b. [x] For every plugin whose README.md was actually modified in Step 2, bump that plugin's version in `.claude-plugin/marketplace.json` by a patch level and add a `CHANGELOG.md` entry noting the migrated documentation; if Step 2 modified no README, skip this step entirely. Why: `changedPlugins()` treats any path under `kit/plugins/<name>/` as a plugin change, so an unbumped README edit fails the version guard in CI. Verify: `BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0, and `git diff --name-only main -- 'kit/plugins/*/README.md'` lists exactly the plugins bumped.
3. [x] Rewrite CLAUDE.md's plugin table to `| Plugin | Type | Purpose |` with the purpose held to one line under 15 words, and replace the removed prose with a single sentence pointing at README.md's generated Plugin Reference Table and at `kit/plugins/<name>/README.md` for detail. Why: one line per plugin is enough for Claude to pick the right plugin; the generated table and per-plugin READMEs carry everything else on demand. Verify: `wc -w CLAUDE.md` reports under 800, and every plugin in `.claude-plugin/marketplace.json` still appears in the table.
4. [x] Write `tests/plugins/test-claude-md-budget.sh` asserting CLAUDE.md is under 800 words, that every plugin name in `marketplace.json` appears in CLAUDE.md, and that no table row exceeds 25 words. Why: 800 is the objective's own threshold, so the test fails whenever the objective fails — a looser ceiling would let the suite pass on a CLAUDE.md that never met the goal. Verify: `bash tests/plugins/test-claude-md-budget.sh` exits 0; temporarily padding a row to 40 words makes it exit 1.
5. [x] Add the new test to `.github/workflows/check-plugin-versions.yml` alongside the existing `tests/plugins/test-build-skill.sh` step. Why: a test that only runs locally stops running. Verify: the workflow file names `test-claude-md-budget.sh` and `yamllint` or a YAML parse of the file succeeds.

## Tests

Tier 2 — This plan doesn't change application code
- Objective: CLAUDE.md is under the context budget while still naming every plugin. File: tests/plugins/test-claude-md-budget.sh; Type: smoke; Asserts: CLAUDE.md word count is under 800 (the objective's own threshold), every plugin in marketplace.json appears in it, and no table row exceeds 25 words; Run: bash tests/plugins/test-claude-md-budget.sh

## Acceptance Criteria

- [x] `wc -w CLAUDE.md` reports fewer than 800 words
- [x] Every plugin name in `.claude-plugin/marketplace.json` appears in CLAUDE.md's table
- [x] No CLAUDE.md plugin table row exceeds 25 words
- [x] The Step 1 audit file shows zero orphaned sentences after Step 2
- [x] `bash tests/plugins/test-claude-md-budget.sh` exits 0
- [x] `.github/workflows/check-plugin-versions.yml` runs the new test
- [x] No file under `kit/plugins/` changed except `README.md` files and, where Step 2b applied, their sibling `CHANGELOG.md`
- [x] `BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0 — every plugin with a modified README carries a version bump, and none was bumped without one

## Verification

Run `wc -w CLAUDE.md` and confirm the count is under 800, down from 1,656.
Run `bash tests/plugins/test-claude-md-budget.sh` and confirm exit 0, then
pad one table row past 25 words, re-run, and confirm exit 1 before reverting
the padding — this proves the check is not a tautology.

Then confirm no information was lost: for three plugins picked at random, take
a capability that the old CLAUDE.md row described and grep for it in that
plugin's `README.md`. All three must be found. Finally run
`git diff --stat` and confirm the only changed paths are `CLAUDE.md`, plugin
`README.md` files, the new test, and the workflow.

## Next Steps

- Generate the CLAUDE.md table instead of hand-maintaining it
  The table will drift again the moment a plugin is added. `scripts/build-readme-table.mjs` already reads marketplace.json and supports `--check`; a compact output mode could own the CLAUDE.md table too.
  ```text
  In the agentics repo, extend scripts/build-readme-table.mjs with a
  --compact --target CLAUDE.md mode that regenerates the one-line plugin
  table in CLAUDE.md from .claude-plugin/marketplace.json, matching the
  existing --check semantics (exit 1 when out of date). Wire the --check
  invocation into .github/workflows/check-plugin-versions.yml. Add a
  CHANGELOG.md entry at the repo root. Verify by running the script, then
  running it with --check and confirming exit 0, then hand-editing one row
  and confirming --check exits 1.
  ```

## Resources

- The new rules of context engineering for Claude 5 generation models — https://claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models — the source of the "CLAUDE.md carries gotchas, not obvious facts" guidance this plan applies
- scripts/build-readme-table.mjs — existing canonical generator for the README plugin table, including its `--check` mode
