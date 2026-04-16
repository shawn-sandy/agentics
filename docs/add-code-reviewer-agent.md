# Add Code Reviewer Agent to code-review Plugin

> Adds a dedicated `code-reviewer` agent to the `code-review` plugin, enabling sub-agent invocation with confidence-based issue filtering.

<!-- generated:start -->

**Status:** Shipped 2026-03-08   **Plan:** [add-code-reviewer-agent.md](plans/add-code-reviewer-agent.md)   **Type:** feature

## What shipped

- New agent `kit/plugins/code-review/agents/agent-code-reviewer.md` added (shipped as `agent-code-reviewer` rather than `code-reviewer` — see name change plans).
- Agent uses read-only tools (`Read`, `Glob`, `Grep`, `WebFetch`, `WebSearch`), `sonnet` model, and a 10-turn limit.
- System prompt includes Role, Behavior, Workflow, Output Format, and Scope sections, reusing the review checklist structure from the existing skill.
- `code-review` plugin bumped from `2.1.1` → `2.2.0`.

> See [CHANGELOG §2.2.0](../kit/plugins/code-review/CHANGELOG.md#220---2026-03-08) for the authoritative feature list.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/code-review/agents/agent-code-reviewer.md` | Agent definition — code reviewer | Created |
| `kit/plugins/code-review/CHANGELOG.md` | Plugin changelog | Modified |
| `.claude-plugin/marketplace.json` | Marketplace registry — version bump 2.1.1 → 2.2.0 | Modified |

## How it works

The agent complements the existing `code-review-agent` skill by providing the same review capabilities in an agent context. Where the skill activates inline during a conversation, the agent can be invoked as a sub-process from other agents or commands — useful for automated pipelines that need code review results without interrupting the primary conversation flow.

The agent body follows a four-step workflow: resolve which files to review, analyze them against the full review checklist (quality, bugs, security, best practices, complexity, breaking changes), filter findings by confidence to surface only high-priority issues, and format the output using the same structured report as the skill (Summary, Complexity Rating, Breaking Changes, Critical Issues, Improvements, Positive Observations).

Tool access is deliberately constrained to read-only operations (`Read`, `Glob`, `Grep`, `WebFetch`, `WebSearch`) to keep the agent safe for sub-agent contexts. The `sonnet` model and 10-turn cap balance review depth with cost and latency.

The agent name shipped as `agent-code-reviewer` rather than the plan's proposed `code-reviewer` — this was a subsequent rename to match the project's naming conventions for agent files.

## How to use it

**Sub-agent invocation** — the agent can be called from other agents or command wrappers:

```
Agent({ subagent_type: "code-reviewer", prompt: "Review the files in src/api/" })
```

**Direct activation** — triggers on requests like "review my code", "find bugs in this file", or "check for security issues".

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `6b9fab3` | 2026-03-26 | Merge pull request #51 from shawn-sandy/docs/plan-interview-upgrade |
| `9c70a52` | 2026-03-30 | chore(docs/plans): add YAML frontmatter status to 83 plan files |
| `e15fba2` | 2026-04-04 | refactor: rename agentics/ marketplace subtree to kit/ |

<!-- generated:end -->

## References

- Plan: [add-code-reviewer-agent.md](plans/add-code-reviewer-agent.md)
- Changelog: [CHANGELOG §2.2.0](../kit/plugins/code-review/CHANGELOG.md#220---2026-03-08)
