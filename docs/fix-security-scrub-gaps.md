# Fix Security Scrub Gaps

> Close four Tier 1 scrub-coverage holes that let repo content reach publicly shared cards without a proper secret scan.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [fix-security-scrub-gaps.md](plans/fix-security-scrub-gaps.md)
**Type:** fix

## What shipped

- Added Phase 1d Security Scrub to `share-code` (the only code-sharing skill with no scrub), mirroring the `share-selection` pattern, so code can no longer reach a shared card without a `GATE RESULT: APPROVED` (closes the most-used fallback share route).
- Fixed the `sk-` regex pattern to `sk-[A-Za-z0-9-]{20,}` so Anthropic API keys (`sk-ant-api03-…`) no longer scan clean, and extended the HIGH-severity table in `scrub-rules.md` with GitHub tokens (`gho_`, `github_pat_`), GitLab tokens (`glpat-`), Stripe live keys (`sk_live_`), Google API keys (`AIza`), Slack webhooks, and a LOW email-PII row.
- Replaced `share-project` Phase 4's `SCRUB RESULT`-only branch with the standard `GATE RESULT` block so a user's Cancel at the WARN gate now stops the flow rather than being silently bypassed.
- Extended `settings-backup`'s secret scan to run on every backup (not just the first), scanning every Step 3 source, and logging matched pattern and file to `.sync-log` in routine mode.
- Bumped social-media-tools to 2.23.2 and settings-sync to 1.1.2 with matching changelog entries.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/social-media-tools/skills/share-code/SKILL.md` | Share-code skill — added Phase 1d security scrub | Modified |
| `kit/plugins/social-media-tools/skills/security-scrub/SKILL.md` | Security scrub skill — updated HIGH pattern list | Modified |
| `kit/plugins/social-media-tools/skills/security-scrub/references/scrub-rules.md` | Scrub rules reference — fixed `sk-` pattern, added new HIGH/LOW rows | Modified |
| `kit/plugins/social-media-tools/skills/share-project/SKILL.md` | Share-project skill — replaced Phase 4 SCRUB RESULT gate | Modified |
| `kit/plugins/settings-sync/skills/settings-backup/SKILL.md` | Settings backup skill — universal scan, `.sync-log` logging | Modified |
| `tests/plugins/test-scrub-patterns.sh` | Objective test — 29 pattern and gate checks | Created |

## How it works

The security scrub pipeline in `social-media-tools` works by invoking the `security-scrub` skill before any content is written to a shared card. Prior to this fix, `share-code/SKILL.md` was the only sharing skill that never invoked it — a gap discovered in a full audit against agent-prompting principles. The fix adds a Phase 1d block to `share-code/SKILL.md` that invokes `social-media-tools:security-scrub` and checks `GATE RESULT`, matching the pattern already in `share-selection/SKILL.md`.

The `sk-` pattern fix addresses a concrete bypass: the hyphen-less legacy pattern `sk-[A-Za-z0-9]{20,}` did not match `sk-ant-api03-…` keys because Anthropic key slugs contain hyphens after `sk-`. The corrected pattern `sk-[A-Za-z0-9-]{20,}` catches these. The extended table in `scrub-rules.md` and its mirror in `security-scrub/SKILL.md` adds six new HIGH-severity prefixes covering the most common token families found in real leaked-secret corpora.

The `share-project` Phase 4 rewrite addresses a logic flaw: the original branching read `SCRUB RESULT` directly, which has only two values (CLEAN / BLOCKED), so a user who pressed Cancel at the WARN gate produced a `SCRUB RESULT` that was neither CLEAN nor BLOCKED — and the skill continued anyway. The standard `GATE RESULT` block has three values (APPROVED / BLOCKED / CANCELLED) and the fix stops on all non-APPROVED outcomes.

`settings-backup/SKILL.md` previously ran its secret scan only when there were no prior commits — meaning the very first backup was scanned and every subsequent one was not. The fix removes that gate and runs the scan over every Step 3 source on every run, appending matched pattern and file to `.sync-log` in routine mode so the audit trail is available without being noisy.

`tests/plugins/test-scrub-patterns.sh` (29 checks) is the objective test. It uses `grep -E` to assert each HIGH pattern matches a canonical fake secret of its family, carries a regression canary proving the hyphen-less legacy pattern misses `sk-ant` keys, checks that the fixed patterns appear verbatim in both instruction files (drift guard), and verifies that both `share-code` and `share-project` carry the `GATE RESULT` gate.

## How to use it

No user-facing surface changes. The security scrub now fires automatically whenever a user invokes `/social-media-tools:share-code`, `/social-media-tools:share-project`, or `/social-media-tools:share-selection`. The `settings-backup` skill scans on every run; matches appear in `.sync-log` inside the backup repo.

Run the pattern test locally:
```bash
bash tests/plugins/test-scrub-patterns.sh
```

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| 0fd7b67 | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |

<!-- generated:end -->

## References

- Plan: [fix-security-scrub-gaps.md](plans/fix-security-scrub-gaps.md)
