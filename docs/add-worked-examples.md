# Add Worked Examples

> Ship one worked example everywhere a skill emits structured output from placeholders alone, and close the remaining medium verification gaps across seven plugins.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [add-worked-examples.md](plans/add-worked-examples.md)
**Type:** chore

## What shipped

- **git-agent 4.19.2**: added a canonical filled PR body to `ship/references/pr-body.md`; added a filled bug-issue example to `create-issue/references/bug-report.md`; create-issue fallback now carries the approved draft and documents the "no issue exists until you submit it" outcome
- **social-media-tools 2.23.3**: added one worked post per platform in `references/platforms.md` (each measured within character limits); `save-artifact` now verifies the published copy exists and the gallery index checksum changed before reporting success
- **code-testing-agent 3.5.2**: added a filled `parseDuration` suggestion with a runnable Vitest snippet to `references/output-guide.md`, referenced from Step 5
- **content-tools 1.1.1**: added a worked finished-MDX-post example to `references/post-assembly.md` Phase 8
- **plan-agent 9.4.4**: `markdown-to-html` Step 5b now runs a parser gate with `python3` grant; `build-fleet` verifies subagent-reported PRs via `gh pr view`; `prototype` asserts console + DOM state instead of a screenshot; `plan-status` executes the spec's objective `Run:` command and drops the invalid `draft` status
- **memory-tools 4.1.1**: replaced the unrunnable inline write gate with `bin/memory-verify-write` + `scripts/verify_write.py`; deleted ledger entries that referenced the broken form; narrowed `allowed-tools` to the wrapper; the guard test mutation-tests the wrapper both directions
- **team-defaults 0.2.2**: `sync-rules` gained a post-copy `diff -q` verification step and the resolve-plugin-root-first instruction
- Changelogs and marketplace bumps for all seven plugins

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/ship/references/pr-body.md` | Canonical filled PR body | Modified |
| `kit/plugins/git-agent/skills/create-issue/references/bug-report.md` | Filled bug-issue example | Modified |
| `kit/plugins/social-media-tools/references/platforms.md` | Worked posts per platform | Modified |
| `kit/plugins/social-media-tools/skills/save-artifact/SKILL.md` | Publish verify + checksum check | Modified |
| `kit/plugins/code-testing-agent/references/output-guide.md` | Filled parseDuration example | Modified |
| `kit/plugins/content-tools/references/post-assembly.md` | Worked Phase 8 example | Modified |
| `kit/plugins/plan-agent/skills/markdown-to-html/SKILL.md` | Python3 parser gate | Modified |
| `kit/plugins/plan-agent/skills/build-fleet/SKILL.md` | gh pr view verification | Modified |
| `kit/plugins/plan-agent/skills/prototype/SKILL.md` | Console + DOM assertion | Modified |
| `kit/plugins/plan-agent/skills/plan-status/SKILL.md` | Run: execution, drop draft | Modified |
| `kit/plugins/memory-tools/bin/memory-verify-write` | Runnable write-gate wrapper | Created (later removed) |
| `kit/plugins/memory-tools/scripts/verify_write.py` | Write verification script | Created |
| `.claude-plugin/marketplace.json` | Seven plugin version bumps | Modified |

## How it works

Tier 4 delivered the composition principle's worked examples — a filled instance beats a bracket-placeholder schema — and closed the medium-impact verification gaps the previous tiers identified but did not reach.

Each worked example was placed in the reference file a skill reads at the step that emits the structured output: the PR body example lives in `ship/references/pr-body.md` where pr-agent, agent-pr, and agent-ship all point; the platform posts live in `references/platforms.md` where `save-artifact` and the social commands read; the parseDuration suggestion lives in `output-guide.md` Step 5 where the reviewer reads for format guidance.

The memory-tools write gate replacement addressed a specific failure mode: the previous gate used a Bash tool expansion (`${TMPFILE}`) that the harness rejects before any permission rule is consulted, making the gate literally unrunnable. The fix replaced it with `bin/memory-verify-write`, a plain wrapper script invoked by bare name, and `scripts/verify_write.py` as the implementation. The guard test (`test-memory-doctor-guard.sh`) mutation-tests the wrapper in both directions — valid input writes and verifies, malformed frontmatter is reported and the file is left untouched.

The plan-agent verification gaps closed in this tier involved runtime execution: `markdown-to-html` Step 5b now runs the generated file through a `python3` parser rather than declaring success on write; `build-fleet` queries `gh pr view` to verify each subagent-reported PR actually exists; `prototype` asserts console errors and DOM state rather than relying on a screenshot the session might not be able to take.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `02136c1` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `d9fdb0b` | 2026-10-10 | feat(git-agent-launcher): add the kit's first mod (0.1.0) (#648) |
| `56a2ea3` | 2026-09-11 | fix(git-agent): close a completed plan's ticket when its PR merges (#630) |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [add-worked-examples.md](plans/add-worked-examples.md)
- Audit series: [add-verification-gates.md](add-verification-gates.md), [add-verification-standards.md](add-verification-standards.md), [add-verification-to-generator-skills.md](add-verification-to-generator-skills.md)
