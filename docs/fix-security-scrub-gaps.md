# Fix Security Scrub Gaps

> Closes four Tier 1 security holes in the sharing and backup pipelines: unscrubbed `share-code`, a hyphen-less `sk-` pattern that misses Anthropic API keys, `share-project`'s bypass of the Cancel gate, and `settings-backup`'s first-backup-only secret scan.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [fix-security-scrub-gaps.md](plans/fix-security-scrub-gaps.md)
**Type:** fix

## What shipped

- Added Phase 1d (Security Scrub) to `share-code/SKILL.md`, mirroring `share-selection`'s Phase 2; `share-code` can no longer reach its sharing step without a `GATE RESULT: APPROVED`.
- Fixed the `sk-` pattern in `security-scrub/references/scrub-rules.md` and the `security-scrub/SKILL.md` mirror list: `sk-[A-Za-z0-9-]{20,}` (with hyphen) replaces the hyphen-less variant that missed `sk-ant-api03-…` keys. Added HIGH rows for `gho_`, `github_pat_`, `glpat-`, `sk_live_`, `AIza`, and Slack webhooks; added a LOW email-PII row.
- Replaced `share-project` Phase 4's `SCRUB RESULT`-only branch with the standard `GATE RESULT` block; the skill now STOPs on BLOCKED, CANCELLED, or missing result.
- Changed `settings-backup` to run the secret scan on every backup over every Step 3 source (previously gated on "no prior commits"), extended the prefix list, and added matched pattern + file logging to `.sync-log` in routine mode.
- Bumped social-media-tools to 2.23.2 and settings-sync to 1.1.2 in `.claude-plugin/marketplace.json`.
- Added `tests/plugins/test-scrub-patterns.sh` (29 checks) asserting each HIGH pattern matches a canonical fake secret, carrying a regression canary proving the hyphen-less legacy pattern misses `sk-ant` keys, and asserting `share-code` and `share-project` carry the `GATE RESULT` gate.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/social-media-tools/skills/share-code/SKILL.md` | Security scrub phase added | Modified |
| `kit/plugins/social-media-tools/skills/security-scrub/references/scrub-rules.md` | Fixed `sk-` pattern; new HIGH/LOW rows | Modified |
| `kit/plugins/social-media-tools/skills/security-scrub/SKILL.md` | Mirror list updated | Modified |
| `kit/plugins/social-media-tools/skills/share-project/SKILL.md` | Standard GATE RESULT block | Modified |
| `kit/plugins/settings-sync/skills/settings-backup/SKILL.md` | Scan every backup; extended prefix list | Modified |
| `tests/plugins/test-scrub-patterns.sh` | 29-check smoke test | Created |
| `.claude-plugin/marketplace.json` | Version bumps for two plugins | Modified |

## How it works

The four holes were independent file-scoped fixes identified by a full audit of the repo's plugins against agent-prompting principles (context / constraints-as-verification / composition). Each was verified with the `test-scrub-patterns.sh` smoke test as the executable check.

**share-code** was the one code-sharing skill with no scrub — and the generic "share this" fallback route. Adding Phase 1d ensures it runs `social-media-tools:security-scrub` and gates on the structured `GATE RESULT` before proceeding, identical to `share-selection`.

The `sk-` pattern fix was subtle: the original pattern `sk-[A-Za-z0-9]{20,}` (without the hyphen class) matched `sk-abc123` but not `sk-ant-api03-` because the hyphen is a literal character in Anthropic API keys. The fixed pattern `sk-[A-Za-z0-9-]{20,}` adds the hyphen to the character class. The test carries a regression canary that explicitly verifies the old pattern fails to match `sk-ant-api03-…`, preventing a future "simplification" from silently reintroducing the gap.

**share-project** branched on `SCRUB RESULT` (the structured output key) rather than `GATE RESULT` (the approval status after the user interaction). Branching on `SCRUB RESULT` alone skips the user's Cancel response at the WARN gate. The standard `GATE RESULT` block treats CANCELLED as a stop condition.

**settings-backup** scanned only on the first backup ("no prior commits"), leaving secrets added after that first backup to be pushed unattended. Running the scan on every backup over every Step 3 source removes the temporal gap. Logging matched pattern + file to `.sync-log` in routine mode gives the user an audit trail without requiring interactive confirmation.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `2f8b101` | 2026-10-28 | fix(settings-sync): back up each machine to its own branch (1.3.0) (#662) |
| `a63d015` | 2026-09-04 | feat(settings-sync): back up what a restore needs and commit only on real change (1.2.0) (#624) |
| `28c3d70` | 2026-09-03 | fix(settings-sync): add marketplace step to install docs and stop false exec-bit failures (1.1.5) (#618) |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [fix-security-scrub-gaps.md](plans/fix-security-scrub-gaps.md)
- Related: [kit/plugins/social-media-tools/skills/security-scrub/references/scrub-rules.md](../kit/plugins/social-media-tools/skills/security-scrub/references/scrub-rules.md)
