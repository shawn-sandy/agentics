# Fix Security Scrub Gaps

> Close the four Tier 1 scrub-coverage holes: unscrubbed `share-code`, the hyphen-less `sk-` pattern that misses Anthropic keys, `share-project`'s `SCRUB RESUL...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [fix-security-scrub-gaps.md](plans/fix-security-scrub-gaps.md)
**Type:** fix

## What shipped

- Add Phase 1d — Security Scrub to `share-code` (the one code-sharing skill with no scrub, and the generic "share)
- Fix the `sk-` pattern and extend the table — in
- Replace `share-project` Phase 4 — with the standard `GATE RESULT` block (branching on `SCRUB RESULT` alone ignores the user's Cancel at the)
- Run the `settings-backup` secret scan on every backup — over every (the scan was gated on "no prior commits". *Verify:* Step 4 heading)
- Bump versions and changelogs — : social-media-tools 2

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `(see plan)` | — | — |

## How it works

Close the four Tier 1 scrub-coverage holes: unscrubbed `share-code`, the hyphen-less `sk-` pattern that misses Anthropic keys, `share-project`'s `SCRUB RESULT`-only gate that bypasses the user's Cancel, and `settings-backup`'s first-backup-only secret scan.

A full audit of the repo's plugins against the agent-prompting principles at <https://shumer.dev/prompting-ai-agents> (context / constraints-as-verification / composition) found four security holes in the sharing and backup pipelines — the Tier 1 findings of the audit. Three let repo content reach a publicly

The implementation proceeded through these steps: **Add Phase 1d — Security Scrub to `share-code`**; Fix the `sk-` pattern and extend the table: in; Replace `share-project` Phase 4: with the standard `GATE RESULT` block; Run the `settings-backup` secret scan on every backup: over every; Bump versions and changelogs: : social-media-tools 2.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates ( |

<!-- generated:end -->

## References

- Plan: [fix-security-scrub-gaps.md](plans/fix-security-scrub-gaps.md)
