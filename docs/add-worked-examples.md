# Add Worked Examples

> Ship one worked example everywhere a skill emits structured output from placeholders alone, and close the remaining medium verification gaps (save-artifact, ...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-worked-examples.md](plans/add-worked-examples.md)
**Type:** chore

## What shipped

- git-agent 4.19.2 — canonical worked PR body in
- social-media-tools 2.23.3 — one worked post per platform in
- code-testing-agent 3.5.2 — filled `parseDuration` suggestion with a
- content-tools 1.1.1 — worked finished-MDX-post example in
- plan-agent 9.4.4 — markdown-to-html Step 5b parser gate (+
- memory-tools 4.1.1 — `bin/memory-verify-write` +
- team-defaults 0.2.2 — sync-rules post-copy `diff -q` verification and
- Changelogs + marketplace bumps — for all seven plugins.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `ship/references/pr-body.md` | Documentation | Modified |
| `create-issue/references/bug-report.md` | Documentation | Modified |
| `test-skill-split-git-social.sh` | Shell script | Modified |
| `references/platforms.md` | Documentation | Modified |
| `test-no-shell-expansion.sh` | Shell script | Modified |
| `test-scrub-patterns.sh` | Shell script | Modified |
| `references/output-guide.md` | Documentation | Modified |
| `test-remaining-skill-splits.sh` | Shell script | Modified |
| `references/post-assembly.md` | Documentation | Modified |
| `test-artifact-to-post.sh` | Shell script | Modified |
| `test-build-fleet.sh` | Shell script | Modified |
| `test-plan-phases.mjs` | Implementation (JavaScript) | Modified |

## How it works

Ship one worked example everywhere a skill emits structured output from placeholders alone, and close the remaining medium verification gaps (save-artifact, create-issue, build-fleet, prototype, plan-status, markdown-to-html, memory-tools' unrunnable gate, sync-rules).

Tier 4 — the final batch — of the agent-prompting audit run against <https://shumer.dev/prompting-ai-agents>. Tiers 1–3 (#567, #568, #569) closed the security holes, added verification gates to the highest-impact skills, and made the gate an authoring standard. This tier delivers the Composition principle's worked examples (a filled instance beats a bracket-placeholder

The implementation proceeded through the following steps: git-agent 4.19.2: canonical worked PR body in; social-media-tools 2.23.3: one worked post per platform in; code-testing-agent 3.5.2: filled `parseDuration` suggestion with a; content-tools 1.1.1: worked finished-MDX-post example in; plan-agent 9.4.4: markdown-to-html Step 5b parser gate (+; memory-tools 4.1.1: `bin/memory-verify-write` +.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates (#573) |

<!-- generated:end -->

## References

- Plan: [add-worked-examples.md](plans/add-worked-examples.md)
