# Stop paying for a plugin catalog in every session

> Replace CLAUDE.md's paragraph-length plugin table with a one-line-per-plugin table plus a README pointer, cutting always-loaded context from 1,656 words to under 800.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [replace-claude-md-plugin-table.md](plans/replace-claude-md-plugin-table.md)
**Type:** docs

## What shipped

- Audited all 13 plugin table rows in CLAUDE.md against their respective `kit/plugins/<name>/README.md` files; migrated any detail found only in CLAUDE.md into the owning plugin README.
- Rewrote CLAUDE.md's plugin table to `| Plugin | Type | Purpose |` with one line per plugin (purpose under 15 words), replacing the removed prose with a pointer to README.md's generated Plugin Reference Table.
- Added `tests/plugins/test-claude-md-budget.sh` asserting CLAUDE.md stays under 800 words, every plugin name appears, and no table row exceeds 25 words.
- Wired the new test into `.github/workflows/check-plugin-versions.yml`.
- Applied PATCH version bumps to plugins whose READMEs received migrated content, with matching CHANGELOG entries.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `CLAUDE.md` | Repo instructions — plugin table collapsed, README pointer added | Modified |
| `kit/plugins/*/README.md` | Plugin READMEs — received any detail found only in CLAUDE.md | Modified |
| `tests/plugins/test-claude-md-budget.sh` | Objective test — word count, plugin coverage, row-length checks | Created |
| `.github/workflows/check-plugin-versions.yml` | CI — step running `test-claude-md-budget.sh` added | Modified |
| `.claude-plugin/marketplace.json` | Marketplace — PATCH bumps for plugins with modified READMEs | Modified |

## How it works

CLAUDE.md is loaded in full before any task begins, making every word a tax on every session. The 13-row plugin table had grown to essay length — the `artifact-tools` row alone ran ~250 words describing every skill's internals. That detail was a hand-maintained third copy of data already owned by `.claude-plugin/marketplace.json` and already rendered into README.md's generated Plugin Reference Table.

The audit step (Step 1) compared each CLAUDE.md row sentence-by-sentence against its owning plugin README. This distinguished genuine gotchas from feature restatements. Any sentence present only in CLAUDE.md and not found in the plugin README was classified as an orphan requiring migration.

Orphaned sentences were ported into the owning plugin README (Step 2). The README is what Claude reads when it opens that plugin, so migrated detail remains discoverable without being loaded every session. Plugins whose README was modified received a PATCH version bump and CHANGELOG entry, since `changedPlugins()` in `scripts/check-plugin-versions.mjs` matches any path under `kit/plugins/<name>/` and would otherwise fail CI.

CLAUDE.md itself was rewritten (Step 3) to a compact `| Plugin | Type | Purpose |` table with one purpose phrase per plugin, capped at 15 words. A single sentence replaces the removed prose, pointing readers to README.md's generated table and to `kit/plugins/<name>/README.md` for detail.

The objective test (`test-claude-md-budget.sh`) enforces three things: word count under 800, every marketplace plugin name present, and no row over 25 words. The test is designed to fail on violations — temporarily padding a row to 40 words makes it exit 1.

## How to use it

The change is operational — CLAUDE.md now loads faster and the per-plugin READMEs have the full detail. No new user-facing interface was added.

```bash
bash tests/plugins/test-claude-md-budget.sh
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d9fdb0b` | 2026-10-10 | feat(git-agent-launcher): add the kit's first mod (0.1.0) (#648) |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [replace-claude-md-plugin-table.md](plans/replace-claude-md-plugin-table.md)
