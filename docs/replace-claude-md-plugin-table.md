# Stop paying for a plugin catalog in every session

> CLAUDE.md's 13-row paragraph-length plugin table was a hand-maintained third copy of data that `marketplace.json` owns. Replacing it with a one-line-per-plugin table cut always-loaded context from 1,656 words to 441.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [replace-claude-md-plugin-table.md](plans/replace-claude-md-plugin-table.md)
**Type:** docs

## What shipped

- Audited all 13 plugin table rows in CLAUDE.md against each plugin's `kit/plugins/<name>/README.md`, identifying any detail present only in CLAUDE.md (orphaned sentences) and not covered by the owning README.
- Ported any orphaned detail into the owning plugin's README.md under its existing structure so the information stays discoverable without loading every session.
- Bumped `.claude-plugin/marketplace.json` patch version and added `CHANGELOG.md` entries for every plugin whose README was modified in the porting step.
- Rewrote CLAUDE.md's plugin table to `| Plugin | Type | Purpose |` with each purpose held to one line under 15 words; replaced the removed prose with a pointer to README.md's generated Plugin Reference Table.
- Added `tests/plugins/test-claude-md-budget.sh` asserting CLAUDE.md is under 800 words, every plugin name in `marketplace.json` appears in it, and no table row exceeds 25 words.
- Wired the new test into `.github/workflows/check-plugin-versions.yml`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `CLAUDE.md` | Plugin table collapsed to one line per plugin; total word count reduced from 1,656 to 441 | Modified |
| `kit/plugins/*/README.md` | Received any detail found only in CLAUDE.md | Modified (conditionally) |
| `tests/plugins/test-claude-md-budget.sh` | Smoke test: CLAUDE.md under 800 words, all plugins listed, no row over 25 words | Created |
| `.github/workflows/check-plugin-versions.yml` | Added step running `test-claude-md-budget.sh` | Modified |
| `.claude-plugin/marketplace.json` | Patch bumps for any plugin with a modified README | Modified (conditionally) |

## How it works

CLAUDE.md is loaded in full at the start of every session — there is no partial load. At 1,656 words, the 13-row plugin table was the bulk of it; the `artifact-tools` row alone ran about 250 words describing every skill's internals. That detail exists in three places: `marketplace.json` (source of truth for metadata), `README.md` (generated from the marketplace via `scripts/build-readme-table.mjs`), and CLAUDE.md (hand-maintained third copy). Hand-maintained copies drift; the CLAUDE.md rows had grown into essays while the generated table stayed terse.

The Anthropic context-engineering guidance (Rule from "The new rules of context engineering for Claude 5 generation models") is explicit: CLAUDE.md should carry repository gotchas, not obvious facts. Detail belongs behind progressive disclosure — the per-plugin README loads only when that plugin's files are opened.

The audit step (Step 1) was safety-critical: a row that documents a real constraint found nowhere else must be preserved, not discarded. Only a row-by-row comparison distinguishes a genuine gotcha from a feature restatement. The audit result determined whether Step 2 (porting) had any work to do; if zero orphans, zero bumps were needed.

`changedPlugins()` in `scripts/check-plugin-versions.mjs` treats any path under `kit/plugins/<name>/` as a plugin change, README files included. Any README modified in Step 2 therefore required a patch bump in `marketplace.json` and a `CHANGELOG.md` entry — Step 2b handled this conditionally.

The CLAUDE.md table currently reads at 441 words, well under the 800-word target. The new table carries one row per plugin with a purpose description under 15 words, plus a pointer to README.md's generated Plugin Reference Table and the instruction to check `kit/plugins/<name>/README.md` for detail.

`test-claude-md-budget.sh` was designed to be falsifiable: padding a row to 40 words makes it exit 1, temporarily reducing the word count below the threshold and re-running confirms exit 0.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |

<!-- generated:end -->

## References

- Plan: [replace-claude-md-plugin-table.md](plans/replace-claude-md-plugin-table.md)
