# Fix security scrub gaps

> Four Tier 1 security holes in the sharing and backup pipelines — an unscrubbed skill, a pattern that misses Anthropic keys, a gate that ignored user cancels, and a scan gated on first run only — are all closed.

<!-- generated:start -->

**Status:** Shipped 2026-08-17 **Plan:** [fix-security-scrub-gaps.md](plans/fix-security-scrub-gaps.md)
**Type:** fix

## What shipped

- Added Phase 1d Security Scrub to `share-code/SKILL.md`: the one code-sharing skill that had no scrub now invokes `social-media-tools:security-scrub` and gates on `GATE RESULT: APPROVED` before proceeding.
- Fixed the `sk-` pattern in `security-scrub/references/scrub-rules.md` and its mirror in `security-scrub/SKILL.md`: extended to `sk-[A-Za-z0-9-]{20,}` to match `sk-ant-api03-…` Anthropic keys; added new HIGH rows for `gho_`, `github_pat_`, `glpat-`, `sk_live_`, `AIza`, and Slack webhooks; added a LOW email-PII row.
- Replaced `share-project` Phase 4's `SCRUB RESULT`-only branch with the standard `GATE RESULT` block that also stops on `CANCELLED` and on a missing result.
- Extended `settings-backup/SKILL.md`: the secret scan now runs on every backup over all Step 3 sources; matched pattern and file are logged to `.sync-log` in routine mode; the first-backup-only gate is removed.
- Added `tests/plugins/test-scrub-patterns.sh`: 29 checks asserting each HIGH pattern matches a canonical fake secret, a regression canary proving the old hyphen-less `sk-` pattern misses Anthropic keys, and drift checks confirming the patterns exist verbatim in both instruction files.
- Bumped social-media-tools to 2.23.2 and settings-sync to 1.1.2.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/social-media-tools/skills/share-code/SKILL.md` | Phase 1d scrub gate | Modified |
| `kit/plugins/social-media-tools/skills/security-scrub/references/scrub-rules.md` | Extended patterns + new rows | Modified |
| `kit/plugins/social-media-tools/skills/security-scrub/SKILL.md` | Mirror list updated | Modified |
| `kit/plugins/social-media-tools/skills/share-project/SKILL.md` | Standard GATE RESULT block | Modified |
| `kit/plugins/settings-sync/skills/settings-backup/SKILL.md` | Every-backup scan + sync-log | Modified |
| `tests/plugins/test-scrub-patterns.sh` | 29-check pattern suite | Created |
| `kit/plugins/social-media-tools/CHANGELOG.md` | 2.23.2 entry | Modified |
| `kit/plugins/settings-sync/CHANGELOG.md` | 1.1.2 entry | Modified |
| `.claude-plugin/marketplace.json` | social-media-tools 2.23.2, settings-sync 1.1.2 | Modified |

## How it works

**share-code gap**: The scrub gate was present in `share-selection` but not in `share-code`, which is the generic "share this" fallback route. `share-code` now has an identical Phase 1d that blocks on anything other than `GATE RESULT: APPROVED`.

**sk- pattern gap**: The original pattern `sk-[A-Za-z0-9]{20,}` missed keys with hyphens in the payload (e.g. `sk-ant-api03-…`). The fixed pattern adds `-` to the character class. The test suite carries a regression canary that explicitly confirms the old pattern fails on a canonical Anthropic key format.

**share-project cancel bypass**: The old `SCRUB RESULT` branch only checked for `BLOCKED`; a user pressing Cancel returned `CANCELLED` and fell through to the publish step. The standard `GATE RESULT` block stops on `BLOCKED`, `CANCELLED`, or any missing/unrecognised value.

**settings-backup first-run-only scan**: The scan was gated on "no prior commits", so backups after the first never ran the scan. The scan now runs unconditionally; in routine mode, matches are appended to `.sync-log` rather than interrupting the backup.

## How to use it

The fixes apply automatically for anyone with social-media-tools and settings-sync installed. No invocation change needed.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| — | 2026-08-17 | fix: close four Tier 1 scrub gaps — share-code gate, sk- pattern, share-project cancel, settings-backup scan (social-media-tools 2.23.2, settings-sync 1.1.2) |

<!-- generated:end -->

## References

- Plan: [fix-security-scrub-gaps.md](plans/fix-security-scrub-gaps.md)
