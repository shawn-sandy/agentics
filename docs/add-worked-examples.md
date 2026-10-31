# Add Worked Examples

> Ship one filled worked example everywhere a skill emits structured output from placeholders alone, and close the remaining medium-impact verification gaps across seven plugins.

<!-- generated:start -->

**Status:** Shipped 2026-08-18 **Plan:** [add-worked-examples.md](plans/add-worked-examples.md)
**Type:** chore

## What shipped

- **git-agent 4.19.2** — canonical filled PR body in `ship/references/pr-body.md` (referenced by `pr-agent` and embedded by background agents); filled bug-issue example in `create-issue/references/bug-report.md`; `create-issue` fallback carries the approved draft and adds the "no issue exists until you submit" outcome note
- **social-media-tools 2.23.3** — one worked post per platform in `references/platforms.md` with all posts measured within character limits; `save-artifact` gains a publish-exists check and a gallery-index checksum comparison before reporting success
- **code-testing-agent 3.5.2** — filled `parseDuration` suggestion with a runnable Vitest snippet in `references/output-guide.md`, wired to Step 5
- **content-tools 1.1.1** — worked finished-MDX-post example in `references/post-assembly.md` Phase 8
- **plan-agent 9.4.4** — `markdown-to-html` Step 5b parser gate with `Bash(python3 *)` grant; `build-fleet` verifies subagent-reported PRs via `gh pr view`; `prototype` asserts console output and DOM state instead of a screenshot; `plan-status` executes the spec's objective `Run:` command and drops the invalid `draft` status value
- **memory-tools 4.1.1** — `bin/memory-verify-write` wrapper script plus `scripts/verify_write.py` replace the unrunnable inline gate that previously failed because the Bash tool refuses shell expansion; ledger entries for the known-broken pattern deleted; `allowed-tools` narrowed to the wrapper; mutation-tested both directions
- **team-defaults 0.2.2** — `sync-rules` gained a post-copy `diff -q` verification step and a resolve-plugin-root-first instruction
- Changelog entries and marketplace version bumps for all seven plugins

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/ship/references/pr-body.md` | Canonical filled PR body example | Created |
| `kit/plugins/git-agent/skills/create-issue/references/bug-report.md` | Filled bug-issue example | Created |
| `kit/plugins/git-agent/skills/create-issue/SKILL.md` | Fallback with draft-carry and outcome note | Modified |
| `kit/plugins/social-media-tools/references/platforms.md` | One worked post per platform | Modified |
| `kit/plugins/code-testing-agent/skills/code-testing-agent/references/output-guide.md` | Filled `parseDuration` Vitest example | Modified |
| `kit/plugins/content-tools/references/post-assembly.md` | Finished-MDX-post worked example | Modified |
| `kit/plugins/plan-agent/skills/markdown-to-html/SKILL.md` | Step 5b parser gate with Bash grant | Modified |
| `kit/plugins/plan-agent/skills/build-fleet/SKILL.md` | PR verification via `gh pr view` | Modified |
| `kit/plugins/plan-agent/skills/prototype/SKILL.md` | Console/DOM assertion instead of screenshot | Modified |
| `kit/plugins/plan-agent/skills/plan-status/SKILL.md` | Executes Run: command; drops `draft` status | Modified |
| `kit/plugins/memory-tools/bin/memory-verify-write` | Executable wrapper for write verification | Created |
| `kit/plugins/memory-tools/skills/agentic-memory-management/scripts/verify_write.py` | Python verification script | Created |
| `.claude-plugin/marketplace.json` | Version bumps for seven plugins | Modified |

## How it works

This plan was Tier 4 — the final batch — of the four-tier agent-prompting audit. Tiers 1–3 closed security holes, added verification gates to the highest-impact skills, and made verification a required authoring standard. Tier 4 addressed the remaining two findings from the audit: skills that emit structured output from placeholder schemas with no filled example, and a set of medium-impact verification gaps identified in the audit but deferred from Tiers 2 and 3.

The central principle behind worked examples is that a filled instance beats a bracket-placeholder schema. Skills like `code-review-agent` and `git-agent:ship` had structured output templates (`[Finding title]`, `[PR body]`) with no reference to what a good instance looks like. An agent generating from a placeholder schema has no signal about acceptable length, tone, specificity, or structure. Each filled example was measured against the constraints it references: the social media posts were checked against each platform's character limit, the Vitest snippet was written to be runnable without modification, and the PR body example follows the repo's own conventions.

The memory-tools write gate was the most technically constrained fix. The existing skill had an inline bash gate (`cat file | python3 -c "..."`) that the Bash tool refused to execute because it uses shell expansion — the tool's restriction on shell operators meant the verification step was structurally unrunnable. The fix introduces `bin/memory-verify-write` as a committed executable wrapper and `scripts/verify_write.py` as the implementation; `allowed-tools` is narrowed to `Bash(bin/memory-verify-write *)` so the skill cannot accidentally use the unrunnable form. The guard was mutation-tested in both directions against valid and broken fixtures.

The `plan-agent` batch addressed four distinct gaps. The `markdown-to-html` parser gate at Step 5b validates the generated HTML with Python's `html.parser` before writing — a step that was specified in the design but not implemented. The `build-fleet` PR verification replaces the pattern of trusting subagent-reported PR URLs with a `gh pr view` call against each URL, since subagents can report a URL they intended to create but did not. The `prototype` skill's success condition was a screenshot assertion, which passes even when the prototype has runtime errors; the replacement checks `console.error` output and asserts the expected DOM nodes exist. The `plan-status` skill was calling `Run:` execution as a suggestion rather than executing it, and it accepted `draft` as a valid status value which is not defined in the plan schema.

The `create-issue` fallback change addressed an audit finding about data loss: when issue creation failed or was interrupted, the drafted content was lost. The skill now carries the approved draft in its fallback path and adds an explicit note that no issue exists in GitHub until the user submits it, preventing silent creation failures from being treated as successes.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `56a2ea3` | 2026-09-11 | fix(git-agent): close a completed plan's ticket when its PR merges (#630) |
| `324cc3c` | 2026-08-19 | feat(git-agent): adversarial pre-PR review in PR-opening flows (4.19.3) (#585) |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |

<!-- generated:end -->

## References

- Plan: [add-worked-examples.md](plans/add-worked-examples.md)
- Audit source: <https://shumer.dev/prompting-ai-agents>
- Related: [add-verification-standards.md](add-verification-standards.md) (Tier 3 — authoring standards)
- Related: [add-verification-gates.md](add-verification-gates.md) (Tier 2 — high-blast-radius gates)
