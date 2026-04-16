# Add `update-plan-status` command to plan-interview plugin

> Adds a batch `update-plan-status` command that processes an entire plans directory in 2-3 interactions, replacing the per-file plan-status workflow with a summary-first, bulk-approval UX.

<!-- generated:start -->

**Status:** Shipped 2026-03-29   **Plan:** [add-update-plan-status-command.md](plans/add-update-plan-status-command.md)   **Type:** standard

## What shipped

- New `kit/plugins/plan-interview/commands/update-plan-status.md` — 7-step batch command with triage, git date collection, codebase evidence analysis, type classification, and hybrid write strategy.
- Triage groups: A (no frontmatter), B (frontmatter, no status), C (has status — skip unless `--force`), D (completed — skip unless `--force`), E (legacy `status: artifact` — always process).
- Stricter batch token filter vs. single-file plan-status: only project-relevant prefixes (`plugins/`, `src/`, `.claude/`, `docs/`, `tests/`) and PascalCase/camelCase identifiers; version strings, JSON values, API routes, and git refs excluded.
- Zero-signal files default to `todo` automatically (no per-file prompt in batch mode).
- Type classification: 30+ days old → default `type: artifact`; otherwise → `type: standard`. No per-file prompt before Step 6 review.
- Three approval modes: Write all, Write with overrides (by category or file number), Export only.
- Hybrid write strategy: files without frontmatter use `Bash` bulk prepend; files with existing frontmatter use `Edit` for precision.
- `plan-interview` plugin bumped to `1.12.0`.

> See [CHANGELOG §1.12.0](../kit/plugins/plan-interview/CHANGELOG.md#1120---2026-03-29) for the authoritative feature list.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/plan-interview/commands/update-plan-status.md` | Command definition — update-plan-status | Created |
| `kit/plugins/plan-interview/README.md` | Plugin documentation | Modified |
| `kit/plugins/plan-interview/CHANGELOG.md` | Plugin changelog | Modified |
| `.claude-plugin/marketplace.json` | Marketplace registry — version bump to 1.12.0 | Modified |

## How it works

The command opens by resolving the target directory (argument, `plansDirectory` setting, or `docs/plans/` fallback) and triaging all `.md` files by reading the first 10 lines of each. The triage table tells users exactly how many files fall into each group before any analysis begins.

Git dates are collected in a single batch `Bash` call rather than one `git log` per file — critical for directories with 80+ plan files. The same git-only strategy as `plan-status` applies: `--follow --diff-filter=A` for creation date, `-1` for most recent modification, today's date as fallback for untracked files.

Codebase evidence analysis uses a stricter token filter than the single-file skill. The key additions: tokens must have project-relevant path prefixes or be PascalCase/camelCase identifiers longer than 3 characters; version strings like `"1.0.0"`, JSON field names, API routes like `GET /api/...`, git refs like `HEAD~1`, and single generic words are excluded. This reduces false positives in batch mode where per-file correction is impractical.

The Step 6 summary table shows all results before any writes occur, with flags: `30d+ old` (auto-classified as artifact), `no signals` (zero-evidence, defaulted to `todo`), and `docs plan` (documentation-type plans where scoring may be inaccurate). The override system lets users correct specific categories or individual files by number before committing to writes.

The hybrid write strategy addresses a performance problem: calling `Edit` 81 times for frontmatter-less files is slow. Instead, files without existing frontmatter are handled with a `Bash` shell loop that prepends the YAML block in one call. Files with existing frontmatter use `Edit` for precise field-level updates.

## How to use it

```
/plan-interview:update-plan-status
/plan-interview:update-plan-status docs/plans/
/plan-interview:update-plan-status docs/plans/ --force
```

The `--force` flag re-analyzes files that already have a status set.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `c070f86` | 2026-03-29 | refactor(plugins/plan-interview): rename status-sweep to update-plan-status |
| `56e7c41` | 2026-03-29 | feat(plugins/plan-interview): add batch-status command (v1.12.0) |
| `e15fba2` | 2026-04-04 | refactor: rename agentics/ marketplace subtree to kit/ |

<!-- generated:end -->

## References

- Plan: [add-update-plan-status-command.md](plans/add-update-plan-status-command.md)
- Changelog: [CHANGELOG §1.12.0](../kit/plugins/plan-interview/CHANGELOG.md#1120---2026-03-29)
