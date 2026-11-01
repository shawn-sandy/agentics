# Fix Security Scrub Gaps

> Closes four Tier 1 security holes found in the sharing and backup pipelines: unscrubbed share-code, a hyphen-less `sk-` pattern missing Anthropic keys, share-project's bypassed Cancel gate, and settings-backup's first-backup-only secret scan.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [fix-security-scrub-gaps.md](plans/fix-security-scrub-gaps.md)
**Type:** fix

## What shipped

- Added a blocking `security-scrub` Phase 1d to `share-code/SKILL.md`, mirroring `share-selection`'s gate — `share-code` was the only code-sharing skill with no scrub.
- Fixed the `sk-` regex pattern in `security-scrub/references/scrub-rules.md` and the SKILL.md mirror list: changed to `sk-[A-Za-z0-9-]{20,}` (with hyphen) so `sk-ant-api03-…` Anthropic keys are detected.
- Added HIGH-severity rows to the scrub table: `gho_`, `github_pat_`, `glpat-`, `sk_live_`, `AIza`, Slack webhooks, and a LOW email-PII row.
- Replaced `share-project`'s Phase 4 branch-on-`SCRUB RESULT` with the standard `GATE RESULT` block, so a user's Cancel at the WARN gate is honored rather than ignored.
- Extended `settings-backup` Step 4 to run the secret scan on every backup (not only when no prior commits exist) over every source, and to log matched pattern + file to `.sync-log` in routine mode.
- Bumped social-media-tools to 2.23.2 and settings-sync to 1.1.2 in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/social-media-tools/skills/share-code/SKILL.md` | Share-code skill | Modified |
| `kit/plugins/social-media-tools/skills/security-scrub/references/scrub-rules.md` | Scrub pattern table | Modified |
| `kit/plugins/social-media-tools/skills/security-scrub/SKILL.md` | Security-scrub skill | Modified |
| `kit/plugins/settings-sync/skills/settings-backup/SKILL.md` | Settings-backup skill | Modified |
| `.claude-plugin/marketplace.json` | Version bumps | Modified |
| `tests/plugins/test-scrub-patterns.sh` | Objective test | Created |

## How it works

The audit was triggered by a review of the repo's plugins against agent-prompting principles (context, constraints-as-verification, composition). Three holes let repo content reach a shared card with either no scan or a scan whose result was misread; the fourth let secrets added after a first backup be pushed unattended.

The hyphen-less `sk-` pattern (`sk-[A-Za-z0-9]{20,}`) cannot match `sk-ant-api03-…` because the hyphen after the prefix prefix is a literal character, not matched by `[A-Za-z0-9]`. The fix adds the hyphen to the character class.

`share-project`'s Phase 4 previously branched on the raw `SCRUB RESULT` string from security-scrub's output. The standard `GATE RESULT` gate returned by security-scrub includes the user's decision (Approved/Cancelled/Blocked) — reading `SCRUB RESULT` directly bypasses the Cancel path entirely.

The settings-backup scan was gated on `no prior commits` because the intent was one-time setup, but that means any secret added after the first backup is pushed silently on every subsequent run. The fix promotes the scan to run unconditionally on every backup.

`tests/plugins/test-scrub-patterns.sh` includes a regression canary that proves the pre-fix hyphen-less pattern misses `sk-ant` keys — a test that would have caught the original bug.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [fix-security-scrub-gaps.md](plans/fix-security-scrub-gaps.md)
