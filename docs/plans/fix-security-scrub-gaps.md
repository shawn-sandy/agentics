---
status: completed
type: fix
created: 2026-08-17
modified: 2026-08-17
repo-name: agentics
---

# Fix Security Scrub Gaps

## context

A full audit of the repo's plugins against the agent-prompting principles at
<https://shumer.dev/prompting-ai-agents> (context / constraints-as-verification /
composition) found four security holes in the sharing and backup pipelines —
the Tier 1 findings of the audit. Three let repo content reach a publicly
shared card with either no secret scan or a scan whose result was read wrong;
the fourth let secrets added after a first backup be pushed unattended forever.
No follow-up question needed: all four fixes are file-scoped edits to skill
markdown named below, with the scrub pattern test as the executable check.

## objective

Close the four Tier 1 scrub-coverage holes: unscrubbed `share-code`, the
hyphen-less `sk-` pattern that misses Anthropic keys, `share-project`'s
`SCRUB RESULT`-only gate that bypasses the user's Cancel, and
`settings-backup`'s first-backup-only secret scan.

## steps

1. **Add Phase 1d — Security Scrub to `share-code`**
   (`kit/plugins/social-media-tools/skills/share-code/SKILL.md`), mirroring
   `share-selection` Phase 2, and add `Skill` to `allowed-tools`.
   *Why:* the one code-sharing skill with no scrub, and the generic "share
   this" fallback route. *Verify:* the SKILL.md contains the
   `social-media-tools:security-scrub` invocation and a `GATE RESULT` check.
2. **Fix the `sk-` pattern and extend the table** in
   `security-scrub/references/scrub-rules.md` and the Step 2 mirror list in
   `security-scrub/SKILL.md`: `sk-[A-Za-z0-9-]{20,}` plus new HIGH rows
   (`gho_`, `github_pat_`, `glpat-`, `sk_live_`, `AIza`, Slack webhooks) and a
   LOW email-PII row. *Why:* `sk-ant-api03-…` scanned clean.
   *Verify:* `tests/plugins/test-scrub-patterns.sh` passes.
3. **Replace `share-project` Phase 4** with the standard `GATE RESULT` block.
   *Why:* branching on `SCRUB RESULT` alone ignores the user's Cancel at the
   WARN gate. *Verify:* Phase 4 STOPs on BLOCKED/CANCELLED/missing.
4. **Run the `settings-backup` secret scan on every backup** over every
   Step 3 source, extend its prefix list, and log matched pattern + file to
   `.sync-log` in routine mode
   (`kit/plugins/settings-sync/skills/settings-backup/SKILL.md`).
   *Why:* the scan was gated on "no prior commits". *Verify:* Step 4 heading
   reads "every backup" and names the `.sync-log` detail requirement.
5. **Bump versions and changelogs**: social-media-tools 2.23.0 → 2.23.2
   (2.23.1 is on a separate in-flight branch), settings-sync 1.1.1 → 1.1.2.
   *Verify:* `BASE_REF=main node scripts/check-plugin-versions.mjs` passes.

## tests

**Objective-verification test** — `tests/plugins/test-scrub-patterns.sh`
(committed, runnable, no fixtures needed): asserts each HIGH pattern matches a
canonical fake secret of its family via `grep -E`, carries a regression canary
proving the hyphen-less legacy pattern misses `sk-ant` keys, asserts the fixed
patterns exist verbatim in both instruction files (drift check), and asserts
`share-code` and `share-project` carry the `GATE RESULT` gate.

## acceptance-criteria

- [x] `share-code` cannot reach Phase 2 without a `GATE RESULT: APPROVED`.
- [x] A fake `sk-ant-api03-…` key matches the HIGH `sk-` pattern.
- [x] `share-project` STOPs on `GATE RESULT: CANCELLED`.
- [x] `settings-backup` Step 4 runs on every backup and logs matches in
      routine mode.
- [x] Both plugin versions exceed `origin/main` and changelogs document the
      changes.

## verification

`bash tests/plugins/test-scrub-patterns.sh` (29 checks),
`bash tests/plugins/test-no-shell-expansion.sh` (no new expansion call sites),
`bash tests/plugins/test-exitplanmode-guard.sh` (guards intact),
`git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs`,
and JSON validation of `.claude-plugin/marketplace.json`.

## next-steps

- Tier 2 of the audit (skills that declare success without verifying their own
  output) — largest blast radius first:

  ```text
  In the agentics repo, implement the Tier 2 verification fixes from the
  2026-08-17 agent-prompting audit: (1) settings-restore re-runs its diff
  procedure after restoring and reports FAILED entries instead of planned
  counts; (2) code-review and its background agent re-read every cited
  file:line and attach a verbatim snippet before reporting a finding;
  (3) ship/agent-ship check gh pr view --json state and only STOP on OPEN;
  (4) review-plan detects spec-backed plans and edits the .md spec, not the
  rendered HTML. Bump versions and changelogs per plugin.
  ```
