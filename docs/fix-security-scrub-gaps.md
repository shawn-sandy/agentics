# Fix security scrub gaps

> Fixes four security scrub gaps: share-code was missing an unscrubbed path (Phase 1d), the `sk-` pattern was missing its hyphen, the share-project GATE RESULT bypass was removed, and settings-backup was only scanning on first backup.

<!-- generated:start -->

**Status:** Shipped 2026-08-17 **Plan:** [fix-security-scrub-gaps.md](plans/fix-security-scrub-gaps.md)
**Type:** fix

## What shipped

- Added Phase 1d to share-code: scrubs the path that was previously passed unscrubbed to the artifact.
- Fixed `sk-` pattern: the regex was matching `sk` without the hyphen, causing false positives on words like "skip" and "task".
- Replaced the `SCRUB RESULT` bypass in share-project with `GATE RESULT`: the bypass was allowing unscrubbed content through when the scrub returned an empty result.
- Fixed settings-backup to scan on every backup, not just the first: the scan was gated on a first-run flag that was never reset.
- Bumped social-media-tools to 2.23.2, settings-sync to 1.1.2 in `.claude-plugin/marketplace.json`.
- Created `tests/test-scrub-patterns.sh` to regression-test all scrub patterns.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/social-media-tools/skills/share-code/` | Phase 1d addition | Modified |
| `kit/plugins/social-media-tools/skills/share-project/` | GATE RESULT fix | Modified |
| `kit/plugins/settings-sync/skills/settings-backup/` | Scan-every-backup fix | Modified |
| `tests/test-scrub-patterns.sh` | Scrub pattern tests | Created |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |

## How it works

The Phase 1d addition closes the gap in share-code where a file's path (not just its content) was passed to the artifact renderer without first being scrubbed. File paths can contain secrets: absolute paths expose home directory usernames; project paths can reveal client names or internal system names.

The `sk-` pattern fix is a precision improvement: API keys like `sk-proj-abc123` start with `sk-` (with hyphen), not `sk` (without). The old pattern matched any word starting with `sk`, producing false positives and training users to ignore scrub warnings.

The `SCRUB RESULT` / `GATE RESULT` distinction matters because the bypass was checking whether the scrub produced output, not whether the original content was clean. When a scrub finds nothing to remove (all clean), `SCRUB RESULT` is empty — and the bypass was treating "empty result" as "skip the gate." `GATE RESULT` checks the gate's pass/fail status directly.

The settings-backup scan fix ensures credentials are never accidentally backed up even after the first run: the first-run guard was protecting against slow startup, not against repeated backups.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [fix-security-scrub-gaps.md](plans/fix-security-scrub-gaps.md)
