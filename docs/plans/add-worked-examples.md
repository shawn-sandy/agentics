---
status: completed
type: chore
created: 2026-08-17
modified: 2026-08-17
repo-name: agentics
---

# Add Worked Examples

## context

Tier 4 — the final batch — of the agent-prompting audit run against
<https://shumer.dev/prompting-ai-agents>. Tiers 1–3 (#567, #568, #569) closed
the security holes, added verification gates to the highest-impact skills,
and made the gate an authoring standard. This tier delivers the Composition
principle's worked examples (a filled instance beats a bracket-placeholder
schema) and the remaining medium-impact verification gaps. No follow-up
question needed: each step names its files; the full runner sweep is the
executable check.

## objective

Ship one worked example everywhere a skill emits structured output from
placeholders alone, and close the remaining medium verification gaps
(save-artifact, create-issue, build-fleet, prototype, plan-status,
markdown-to-html, memory-tools' unrunnable gate, sync-rules).

## steps

1. **git-agent 4.19.2** — canonical worked PR body in
   `ship/references/pr-body.md` (pr-agent points; background agents embed);
   filled bug-issue example in `create-issue/references/bug-report.md`;
   create-issue fallback carries the approved draft and gains the
   "no issue exists until you submit it" outcome.
   *Verify:* `test-skill-split-git-social.sh` passes; ship/SKILL.md untouched.
2. **social-media-tools 2.23.3** — one worked post per platform in
   `references/platforms.md` (all measured within character limits);
   save-artifact verifies the published copy exists and the gallery index
   checksum changed before reporting success.
   *Verify:* `test-no-shell-expansion.sh`, `test-scrub-patterns.sh` pass.
3. **code-testing-agent 3.5.2** — filled `parseDuration` suggestion with a
   runnable Vitest snippet in `references/output-guide.md`, referenced from
   Step 5. *Verify:* `test-remaining-skill-splits.sh` passes.
4. **content-tools 1.1.1** — worked finished-MDX-post example in
   `references/post-assembly.md` Phase 8. *Verify:*
   `test-artifact-to-post.sh` passes.
5. **plan-agent 9.4.4** — markdown-to-html Step 5b parser gate (+
   `Bash(python3 *)` grant); build-fleet verifies subagent-reported PRs via
   `gh pr view`; prototype asserts console + DOM state instead of a
   screenshot (read-only browser tools added); plan-status executes the
   spec's objective `Run:` command and drops the invalid `draft` status.
   *Verify:* `test-build-fleet.sh`, `test-prototype-*.sh`,
   `test-plan-phases.mjs` pass.
6. **memory-tools 4.1.1** — `bin/memory-verify-write` +
   `scripts/verify_write.py` replace the unrunnable inline gate (Bash-tool
   expansion refusal); ledger entries deleted; guard test mutation-tests the
   shipped wrapper both directions; allowed-tools narrowed to the wrapper.
   *Verify:* `test-memory-doctor-guard.sh`, `test-no-shell-expansion.sh`
   pass; wrapper proven on valid and broken fixtures.
7. **team-defaults 0.2.2** — sync-rules post-copy `diff -q` verification and
   the resolve-plugin-root-first instruction.
   *Verify:* `test-exitplanmode-guard.sh` passes.
8. **Changelogs + marketplace bumps** for all seven plugins.
   *Verify:* `BASE_REF=main node scripts/check-plugin-versions.mjs` passes.

## tests

**Objective-verification test** — `bash tests/run-all.sh` (the Tier 3
runner): the full suite including every guard test named above, run on the
merged tree before the PR's final push. The memory-tools wrapper carries its
own mutation-tested guard (`test-memory-doctor-guard.sh`), and the expansion
ledger (`test-no-shell-expansion.sh`) asserts the fixed call sites by
presence, not absence.

## acceptance-criteria

- [x] Every audit-flagged placeholder-only output spec has one filled worked
      example wired to the step that reads it.
- [x] save-artifact, build-fleet, prototype, plan-status, markdown-to-html,
      sync-rules verify their own output before declaring done.
- [x] memory-tools' write gate executes (proven both directions) and its
      known-broken ledger entries are gone.
- [x] All seven plugin versions exceed origin/main with changelog entries.
- [x] Full runner sweep green on the merged tree.

## verification

`bash tests/run-all.sh` after merging origin/main +
`BASE_REF=main node scripts/check-plugin-versions.mjs` + marketplace.json
JSON parse — all green before the final push to PR #570.
