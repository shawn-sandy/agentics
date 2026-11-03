# Fix Security Scrub Gaps

> Closes four Tier 1 scrub-coverage holes found in the 2026-08-17 agent-prompting audit: unscrubbed `share-code`, a hyphen-less `sk-` pattern that misses Anthropic keys, a `share-project` gate that ignores the user's Cancel, and a `settings-backup` scan gated on first-backup-only.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [fix-security-scrub-gaps](plans/fix-security-scrub-gaps.md)
**Type:** fix

## What shipped

- Added Phase 1d (Security Scrub) to `share-code/SKILL.md`, mirroring `share-selection`; `share-code` can no longer proceed without a `GATE RESULT: APPROVED`
- Fixed the `sk-` pattern from `sk-[A-Za-z0-9]{20,}` to `sk-[A-Za-z0-9-]{20,}` so `sk-ant-api03-…` Anthropic keys match; extended the table with new HIGH rows (`gho_`, `github_pat_`, `glpat-`, `sk_live_`, `AIza`, Slack webhooks) and a LOW email-PII row
- Replaced `share-project` Phase 4's `SCRUB RESULT`-only branch with the standard `GATE RESULT` block; the skill now STOPs on BLOCKED, CANCELLED, or missing
- Ran the `settings-backup` secret scan on every backup over every source; the scan is no longer gated on "no prior commits"
- Bumped social-media-tools to 2.23.2 and settings-sync to 1.1.2

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/social-media-tools/skills/share-code/SKILL.md` | Skill — scrub gate added | Modified |
| `kit/plugins/social-media-tools/skills/security-scrub/references/scrub-rules.md` | Reference — fixed sk- pattern, new rows | Modified |
| `kit/plugins/social-media-tools/skills/security-scrub/SKILL.md` | Skill — mirror list updated | Modified |
| `kit/plugins/social-media-tools/skills/share-project/SKILL.md` | Skill — GATE RESULT gate | Modified |
| `kit/plugins/settings-sync/skills/settings-backup/SKILL.md` | Skill — every-backup scan | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry — version bumps | Modified |
| `kit/plugins/social-media-tools/CHANGELOG.md` | Release history | Modified |
| `kit/plugins/settings-sync/CHANGELOG.md` | Release history | Modified |
| `tests/plugins/test-scrub-patterns.sh` | Smoke test — pattern and gate assertions | Modified |

## How it works

The 2026-08-17 audit of the repo's plugins against the agent-prompting principles at shumer.dev found three sharing skills that could reach a publicly shared card with either no secret scan or a scan whose result was read wrong, and a backup skill that scanned only on first-run.

`share-code` was the one code-sharing skill with no scrub and the generic "share this" fallback route. Adding Phase 1d with a `social-media-tools:security-scrub` invocation and a `GATE RESULT` check mirrors the pattern that `share-selection` already used.

The `sk-` pattern bug was that `sk-ant-api03-` contains a hyphen after `sk-`, and the original regex `sk-[A-Za-z0-9]{20,}` excluded hyphens from the character class — making every Anthropic API key a false negative. The fix adds `-` to the class. A canary assertion in `test-scrub-patterns.sh` proves the old pattern misses `sk-ant` keys, and the new pattern catches them.

`share-project` branched on `SCRUB RESULT` alone, which is the raw scan output. The standard gate reads `GATE RESULT`, which reflects the user's Cancel decision at the WARN prompt. Replacing the branch with the standard block closes the bypass.

`settings-backup`'s scan was inside a `if not prior_commits:` guard — it ran only on the very first backup, letting secrets added after the initial commit go undetected on every subsequent run. Removing the guard and running the scan on every backup over every source fixes this.

`test-scrub-patterns.sh` asserts each HIGH pattern matches a canonical fake secret via `grep -E`, carries a regression canary for the legacy hyphen-less pattern, and asserts `share-code` and `share-project` both carry the `GATE RESULT` gate.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [fix-security-scrub-gaps](plans/fix-security-scrub-gaps.md)
