# Fix Security Scrub Gaps

> Close the four Tier 1 scrub-coverage holes: unscrubbed `share-code`, the hyphen-less `sk-` pattern that misses Anthropic keys, `share-project`'s `SCRUB RESUL...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [fix-security-scrub-gaps.md](plans/fix-security-scrub-gaps.md)
**Type:** fix

## What shipped

- Add Phase 1d — Security Scrub to `share-code` — (`kit/plugins/social-media-tools/skills/share-code/SKILL.md`), mirroring `share-selection` Phase 2, and add `Skill` to `allowed-tools`.
- Fix the `sk-` pattern and extend the table — in `security-scrub/references/scrub-rules.md` and the Step 2 mirror list in `security-scrub/SKILL.md`: `sk-[A-Za-z0-9-]{20,}` plus new HIGH rows (`gho_`, `github_pat_`, `glpat-`, `sk_live_`, `AIza`, Slack webhooks) and a LOW email-PII row.
- Replace `share-project` Phase 4 — with the standard `GATE RESULT` block.
- Run the `settings-backup` secret scan on every backup — over every Step 3 source, extend its prefix list, and log matched pattern + file to `.sync-log` in routine mode (`kit/plugins/settings-sync/skills/settings-backup/SKILL.md`).
- Bump versions and changelogs — : social-media-tools 2.23.0 → 2.23.2 (2.23.1 is on a separate in-flight branch), settings-sync 1.1.1 → 1.1.2.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/social-media-tools/skills/share-code/SKILL.md` | Skill instructions | Modified |
| `security-scrub/references/scrub-rules.md` | Documentation | Modified |
| `security-scrub/SKILL.md` | Skill instructions | Modified |
| `tests/plugins/test-scrub-patterns.sh` | Test suite | Modified |
| `kit/plugins/settings-sync/skills/settings-backup/SKILL.md` | Skill instructions | Modified |

## How it works

Close the four Tier 1 scrub-coverage holes: unscrubbed `share-code`, the hyphen-less `sk-` pattern that misses Anthropic keys, `share-project`'s `SCRUB RESULT`-only gate that bypasses the user's Cancel, and `settings-backup`'s first-backup-only secret scan.

A full audit of the repo's plugins against the agent-prompting principles at <https://shumer.dev/prompting-ai-agents> (context / constraints-as-verification / composition) found four security holes in the sharing and backup pipelines — the Tier 1 findings of the audit. Three let repo content reach a publicly shared card with either no secret scan or a scan whose result was read wrong;

The implementation proceeded through the following steps: **Add Phase 1d — Security Scrub to `share-code`**; Fix the `sk-` pattern and extend the table: in; Replace `share-project` Phase 4: with the standard `GATE RESULT` block; Run the `settings-backup` secret scan on every backup: over every; Bump versions and changelogs: : social-media-tools 2.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates (#573) |

<!-- generated:end -->

## References

- Plan: [fix-security-scrub-gaps.md](plans/fix-security-scrub-gaps.md)
