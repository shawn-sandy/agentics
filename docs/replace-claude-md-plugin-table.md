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

The Claude 5 context-engineering guidance is explicit that CLAUDE.md should carry repository *gotchas*, not obvious facts, and that detail belongs behind progressive disclosure rather than in the always-loaded layer. This repo's CLAUDE.md is 1,656 words and the 13-row plugin table is the bulk of it — the `artifact-tools` row alone runs about 250 words describing every skill's internals. That detail is not unique. `.claude-plugin/marketplace.json` is the source of truth for plugin metadata, `scripts/build-readme-table.mjs` already regenerates a plugin table into README.md from it (with a `--check` mode), and all 13 plugins carry their own `README.md` averaging 1,800 words. The CLAUDE.md table is a hand-maintained third copy, which is exactly why its rows have drifted into essays while the generated one stayed terse. Risk: a row may describe a genuine gotcha that exists nowhere else — a non-obvious constraint rather than a feature list. Mitigated by Step 1, which audits every row against its plugin README before anything is cut, and Step 2, which ports orphaned detail into the owning README first. One wrinkle on version bumps. `changedPlugins()` in `scripts/check-plugin-versions.mjs` matches on `^kit/plugins/([^/]+)/` — it counts *any* path under a plugin directory as a plugin change, README files included. So if Step 2 finds orphaned detail and moves it into a plugin's `README.md`, that plugin needs a `marketplace.json` version bump (patch, docs only) and a `CHANGELOG.md` entry, or CI fails. Step 2b handles this conditionally: zero orphans means zero bumps, which is the likely case since all 13 READMEs already average 1,800 words. CLAUDE.md itself lives at the repo root and never triggers a bump.

The implementation proceeded through the following steps: Audit each of the 13 plugin table rows in CLAUDE.md against that plugin's `kit/plugins/<name>/README.md`, writing the orphan list to a scratch file.; Port each orphaned sentence from Step 1 into the owning plugin's README.md under its existing structure.; Rewrite CLAUDE.md's plugin table to `| Plugin | Type | Purpose |` with the purpose held to one line under 15 words, and replace the removed prose with a single sentence pointing at README.md's generated Plugin Reference Table and at `kit/plugins/<name>/README.md` for detail.; Write `tests/plugins/test-claude-md-budget.sh` asserting CLAUDE.md is under 800 words, that every plugin name in `marketplace.json` appears in CLAUDE.md, and that no table row exceeds 25 words.; Add the new test to `.github/workflows/check-plugin-versions.yml` alongside the existing `tests/plugins/test-build-skill.sh` step..

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates (#573) |

<!-- generated:end -->

## References

- Plan: [replace-claude-md-plugin-table.md](plans/replace-claude-md-plugin-table.md)
