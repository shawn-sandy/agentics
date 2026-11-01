# Add Worked Examples

> Ship one worked example everywhere a skill emits structured output from placeholders alone, and close the remaining medium verification gaps from the agent-prompting audit.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [add-worked-examples.md](plans/add-worked-examples.md)
**Type:** chore

## What shipped

- **git-agent 4.19.2**: added a canonical worked PR body to `ship/references/pr-body.md` (referenced by pr-agent and embedded by background agents); added a filled bug-issue example to `create-issue/references/bug-report.md`; made create-issue's fallback carry the approved draft so no work is lost on failure.
- **social-media-tools 2.23.3**: added one worked post per platform to `references/platforms.md`, measured to fit within character limits; added a verify step to `save-artifact` that confirms the published copy exists and the gallery index checksum changed before reporting success.
- **code-testing-agent 3.5.2**: added a filled `parseDuration` suggestion with a runnable Vitest snippet to `references/output-guide.md`, referenced from Step 5.
- **content-tools 1.1.1**: added a worked finished-MDX-post example in `references/post-assembly.md` Phase 8.
- **plan-agent 9.4.4**: added a parser gate to `markdown-to-html` Step 5b (plus `Bash(python3 *)` grant); added `gh pr view` verification to `build-fleet`; changed `prototype` to assert console + DOM state instead of a screenshot; made `plan-status` execute the spec's objective `Run:` command and drop the invalid `draft` status.
- **memory-tools 4.1.1**: replaced the unrunnable inline write gate (which used Bash-tool `${VAR}` expansion that the harness rejects) with `bin/memory-verify-write` and `scripts/verify_write.py`; removed broken ledger entries; narrowed `allowed-tools` to the wrapper.
- **team-defaults 0.2.2**: added post-copy `diff -q` verification to `sync-rules` and the resolve-plugin-root-first instruction.
- Bumped all seven plugins with marketplace and CHANGELOG entries.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/ship/references/pr-body.md` | Canonical worked PR body | Created |
| `kit/plugins/git-agent/skills/create-issue/references/bug-report.md` | Filled bug-issue example | Created |
| `kit/plugins/memory-tools/bin/memory-verify-write` | Runnable write-gate wrapper | Created (later removed) |
| `kit/plugins/memory-tools/scripts/verify_write.py` | Write verification script | Created (later removed) |
| `.claude-plugin/marketplace.json` | Seven plugin version bumps | Modified |

## How it works

The plan's framing was "a filled instance beats a bracket-placeholder schema." Every skill that emits structured output (a PR body, an issue, a social post, a test suggestion) had a template with `[brackets]` where examples belonged. A reader following the template produces output shaped like the template rather than shaped like the target.

The worked examples are filled: the PR body in `pr-body.md` reads like a real PR, the social posts in `platforms.md` are measured against each platform's actual character limit, and the Vitest snippet in `output-guide.md` runs without modification.

The memory-tools fix addressed a known-broken verification gate. The prior inline gate used `${SCRIPT_PATH}` in a Bash command, which the harness rejects before any permission rule is consulted. The gate was present in the file but unreachable — verified by the existing `test-no-shell-expansion.sh` ledger. The replacement routes through `bin/memory-verify-write`, a bare-name wrapper following the same pattern as `plan-agent-hub` and `plan-agent-render`.

The medium verification gaps (save-artifact, build-fleet, prototype, plan-status, markdown-to-html, sync-rules) each had a specific failure mode: save-artifact could report success while the gallery index remained stale; build-fleet trusted subagent-reported PR URLs without querying `gh`; prototype checked a screenshot rather than observable DOM + console state; plan-status had an invalid `draft` status value that could silently no-op; markdown-to-html's generated HTML could be malformed with no parse check; sync-rules could copy files and report success without confirming the destination matched the source.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `7a4214ff` | 2026-09-26 | feat(memory-tools): implementing-insights publishes a live record per item (4.4.0) (#638) |
| `56a2ea36` | 2026-09-11 | fix(git-agent): close a completed plan's ticket when its PR merges (#630) |
| `02136c1d` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [add-worked-examples.md](plans/add-worked-examples.md)
- Related: [add-verification-gates.md](add-verification-gates.md) — Tier 2; applied gates to the five highest-blast-radius skills
- Related: [add-verification-standards.md](add-verification-standards.md) — Tier 3; made gates an authoring standard
