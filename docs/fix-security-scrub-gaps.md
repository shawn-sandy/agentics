# Fix Security Scrub Gaps

> Closes four Tier 1 scrub-coverage holes: unscrubbed `share-code`, a hyphen-less `sk-` regex that missed Anthropic keys, a `share-project` gate that bypassed user cancel, and a `settings-backup` scan that only ran on the first backup.

<!-- generated:start -->

**Status:** Shipped 2026-08-18 **Plan:** [fix-security-scrub-gaps.md](plans/fix-security-scrub-gaps.md)
**Type:** fix

## What shipped

- Added Phase 1d Security Scrub to `share-code/SKILL.md`, mirroring `share-selection` Phase 2, with a `GATE RESULT` check
- Fixed the `sk-` pattern to `sk-[A-Za-z0-9-]{20,}` and extended the HIGH-risk table in `scrub-rules.md` and `security-scrub/SKILL.md` with `gho_`, `github_pat_`, `glpat-`, `sk_live_`, `AIza`, Slack webhooks, and a LOW email-PII row
- Replaced `share-project` Phase 4's `SCRUB RESULT`-only branch with the standard `GATE RESULT` block that correctly stops on BLOCKED, CANCELLED, or missing result
- Extended `settings-backup/SKILL.md` to run the secret scan on every backup (not just the first), log matched pattern and file to `.sync-log` in routine mode
- Bumped `social-media-tools` to 2.23.2 and `settings-sync` to 1.1.2 with CHANGELOG entries
- Added `tests/plugins/test-scrub-patterns.sh` with 29 checks covering pattern matches, drift detection, and gate presence

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/social-media-tools/skills/share-code/SKILL.md` | Share-code skill — added Phase 1d security scrub gate | Modified |
| `kit/plugins/social-media-tools/skills/security-scrub/references/scrub-rules.md` | Scrub pattern reference — fixed `sk-` regex and added HIGH/LOW rows | Modified |
| `kit/plugins/social-media-tools/skills/security-scrub/SKILL.md` | Security-scrub skill — Step 2 mirror list updated with new patterns | Modified |
| `kit/plugins/social-media-tools/skills/share-project/SKILL.md` | Share-project skill — Phase 4 gate replaced with standard GATE RESULT block | Modified |
| `kit/plugins/settings-sync/skills/settings-backup/SKILL.md` | Settings-backup skill — scan now runs on every backup with `.sync-log` logging | Modified |
| `tests/plugins/test-scrub-patterns.sh` | Test — 29 checks: pattern matches, regression canary, drift checks, gate presence | Created |

## How it works

A full audit of the repo's plugins against agent-prompting principles at shumer.dev/prompting-ai-agents found four Tier 1 security holes in the sharing and backup pipelines. Three let repo content reach a publicly shared card with either no secret scan or a scan whose result was read incorrectly; the fourth let secrets added after a first backup be pushed unattended forever.

The first hole was `share-code`, the one code-sharing skill with no scrub at all. It also serves as the generic "share this" fallback route. Phase 1d was added to mirror the scrub gate already present in `share-selection` Phase 2: the skill now invokes `social-media-tools:security-scrub` and checks a `GATE RESULT: APPROVED` before proceeding to Phase 2.

The second hole was the `sk-` pattern in the scrub rule table. The old pattern `sk-[A-Za-z0-9]{20,}` (no hyphen) matched OpenAI keys but missed Anthropic keys in the format `sk-ant-api03-…` because the hyphen in `ant-api03` caused the match to fail. The fixed pattern `sk-[A-Za-z0-9-]{20,}` includes the hyphen character class. Six additional HIGH-risk patterns were added for common token formats from GitHub (`gho_`, `github_pat_`), GitLab (`glpat-`), Stripe (`sk_live_`), Google (`AIza`), and Slack webhooks. A LOW-severity email-PII row rounds out the table. Both `scrub-rules.md` and its mirror in `security-scrub/SKILL.md` Step 2 were updated together.

The third hole was in `share-project` Phase 4. The gate branched on `SCRUB RESULT`, but a user pressing Cancel at the WARN dialog produces `GATE RESULT: CANCELLED` — not a `SCRUB RESULT` value. The old logic fell through to the sharing path on a Cancel. The replacement uses the standard `GATE RESULT` block pattern: the skill now STOPs unconditionally on BLOCKED, CANCELLED, or a missing gate result.

The fourth hole was in `settings-backup`. The secret scan was gated on "no prior commits" — meaning it ran on the very first backup and was skipped on every subsequent one. Any secret added to a settings file after the initial backup would be pushed unattended forever. The skill now runs the scan on every backup over every source file, and in routine mode logs the matched pattern and file path to `.sync-log` rather than blocking — maintaining the silent-by-default behaviour while creating a discoverable audit trail.

The test script at `tests/plugins/test-scrub-patterns.sh` carries a regression canary: it explicitly asserts that the old hyphen-less `sk-` pattern does NOT match an `sk-ant-api03` key, confirming the legacy bug. If someone reverts the pattern fix, that canary turns red before any real key could leak. Drift checks assert the fixed patterns appear verbatim in both instruction files. Gate-presence checks assert `share-code` and `share-project` carry the `GATE RESULT` block.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |
| `a63d015` | 2026-09-04 | feat(settings-sync): back up what a restore needs and commit only on real change (1.2.0) (#624) |
| `28c3d70` | 2026-09-03 | fix(settings-sync): add marketplace step to install docs and stop false exec-bit failures (1.1.5) (#618) |

<!-- generated:end -->

## References

- Plan: [fix-security-scrub-gaps.md](plans/fix-security-scrub-gaps.md)
