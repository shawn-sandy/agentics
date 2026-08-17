---
status: completed
type: chore
created: 2026-08-17
modified: 2026-08-17
repo-name: agentics
---

# Add Verification Standards

## context

Tier 3 — the leverage point — of the agent-prompting audit run against
<https://shumer.dev/prompting-ai-agents>. Tiers 1–2 fixed nine shipped skills
that could declare success on broken output; this tier fixes why they shipped
that way: neither authoring rule required a verification gate or a worked
example, the skill-quality rubric never scored them, 49 of 77 test files ran
in no CI workflow, and the dist builder exited 0 on a missing plugin. No
follow-up question needed: each step names its file and its check.

## objective

Make verification self-enforcing — the authoring rules require it, the
reviewer scores it, CI runs every test automatically, and the dist build
fails loudly.

## steps

1. **Authoring rule** (`.claude/rules/plugin-patterns.md`): new "The
   verification gate" section — mutating skills define done as
   artifact + check, structured output ships one worked example; names
   memory-tools, completion-gates.md, and settings-restore Step 7 as
   canonical. *Why:* the standard existed only as folklore in the good
   skills. *Verify:* `tests/plugins/test-verification-gate-rule.sh` passes.
2. **Rubric** (`skill-reviewer/.../references/audit-steps.md` Dimension 3 +
   `best-practices.md`): Warning-level Verification gate check; absence in a
   mutating/measuring skill caps Dimension 3 at 1 pt; best-practices gains
   the gate-per-mutation-type table. *Why:* a file-mutating skill with no
   gate could score 10/10. *Verify:* same retention test.
3. **Retention test** (`tests/plugins/test-verification-gate-rule.sh`): holds
   the rule text, the rubric row, and the best-practices section together,
   with a positive canary — same pattern as `test-exitplanmode-guard.sh`.
   *Verify:* the test passes; deleting any of the three phrases fails it.
4. **Test runner** (`tests/run-all.sh` + `check-plugin-versions.yml` +
   `.claude/rules/testing.md`): globs every `test-*.{sh,mjs}` /
   `*.test.mjs` under `tests/`, four documented skips (claude-CLI harness ×2,
   deployed-URL smoke, needs-built-dist); CI's 20 hand-enumerated steps
   replaced by the runner plus one explicit claude-CLI-gated step.
   *Why:* 49 of 77 test files ran in no workflow. *Verify:* `bash
   tests/run-all.sh` → 74 passed, 0 failed, 4 skipped.
5. **Fix the stale render baseline** (`tests/plugins/test-plan-phases.mjs`):
   re-derive `BASELINE_SHA256` for the deliberate 9.1.0 design retune (#537),
   which changed the shared CSS without updating the 8.5.1-era baseline — the
   check had been failing on main since. *Why:* the runner is red on day one
   otherwise. *Verify:* the test reports 14/14.
6. **Dist builder** (`scripts/build-dist.mjs`): a manifest-registered plugin
   whose source directory is missing now sets `process.exitCode = 1` instead
   of printing an ERROR row and exiting 0; header documents `--publish` as
   implemented. *Why:* a dist silently shipped without a plugin.
   *Verify:* `--list` still works; error path sets a non-zero exit.
7. **Bump skill-reviewer** 2.5.1 → 2.5.2 with a changelog entry.
   *Verify:* `BASE_REF=main node scripts/check-plugin-versions.mjs` passes.

## tests

**Objective-verification test** — `tests/plugins/test-verification-gate-rule.sh`
(committed, runnable): eight retention checks over the rule file, the rubric,
and best-practices, plus a positive canary against vacuous passes. The runner
itself is exercised by CI on this very PR — its first live run.

## acceptance-criteria

- [x] plugin-patterns.md requires verification gates and worked examples.
- [x] reviewing-skills scores the gate and caps Dimension 3 without it.
- [x] `bash tests/run-all.sh` runs 74 tests green with 4 documented skips.
- [x] CI runs the runner; a new test file needs no workflow edit.
- [x] test-plan-phases.mjs passes 14/14 (baseline re-derived for #537).
- [x] build-dist.mjs exits non-zero when a registered plugin fails to build.
- [x] skill-reviewer version exceeds origin/main with a changelog entry.

## verification

`bash tests/run-all.sh` (74/0/4) + `bash
tests/plugins/test-verification-gate-rule.sh` + `git fetch origin &&
BASE_REF=main node scripts/check-plugin-versions.mjs` + marketplace.json JSON
parse — all green before the PR opened.

## next-steps

- Tier 4 (composition batch) from the audit:

  ```text
  In the agentics repo, implement Tier 4 of the 2026-08-17 agent-prompting
  audit — the worked-example batch: (1) one filled PR body in
  git-agent/skills/ship/references/pr-body.md referenced by pr-agent,
  agent-pr, and agent-ship; (2) one filled issue body in
  git-agent/skills/create-issue templates; (3) one worked example post per
  platform in social-media-tools/references/platforms.md under Default
  Per-Platform Copy Formats; (4) one completed example suggestion in
  code-testing-agent/.../references/output-guide.md; (5) a worked example of
  the finished MDX post in content-tools/references/post-assembly.md Phase 8.
  Also the remaining medium verification items: save-artifact publish check,
  build-fleet gh verification, create-issue fallback that preserves the
  draft, prototype console-error check, plan-status Run: execution,
  sync-rules post-copy diff, memory-tools bin/ wrapper for its unrunnable
  gate, markdown-to-html parser gate. Bump versions and changelogs per
  plugin.
  ```
