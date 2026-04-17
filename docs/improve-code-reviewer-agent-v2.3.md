# Improve code-reviewer Agent (v2.3.0)

> Upgrades the `code-reviewer` sub-agent with official best-practice frontmatter fields — `permissionMode: plan`, `disallowedTools`, `memory: project`, `background: true` — and tightens its tool list and description.

<!-- generated:start -->

**Status:** Shipped 2026-03-08   **Plan:** [improve-code-reviewer-agent-v2.3.md](plans/improve-code-reviewer-agent-v2.3.md)   **Type:** standard

## What shipped

- `WebFetch` and `WebSearch` removed from `tools` — code review has no need for external fetches.
- `permissionMode: plan` added — enforces read-only exploration at the framework level.
- `disallowedTools: Write, Edit, NotebookEdit` added — defense-in-depth block on mutation tools.
- `memory: project` added — enables persistent learning of project-specific patterns stored at `.claude/agent-memory/code-reviewer/`.
- `background: true` added — code reviews run non-blocking so the parent session can continue.
- `tools` format switched from YAML list to comma-separated (`Read, Glob, Grep, Bash`).
- Agent description extended with proactive delegation language: "Use proactively after code changes, branch switches, or before merging."
- Workflow Step 1 corrected: changed "via Grep/Glob" to "via Bash" for `git status` invocation.
- Memory instructions section added to agent prompt body — consult on review start, update after discovering new patterns.
- `code-review` plugin bumped from `2.2.0` to `2.3.0`.

> See [CHANGELOG §2.3.0](../kit/plugins/code-review/CHANGELOG.md) for the authoritative change log entry.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/code-review/agents/agent-code-reviewer.md` | Agent instructions | Modified (frontmatter + prompt body) |
| `kit/plugins/code-review/.claude-plugin/plugin.json` | Plugin manifest | Modified (version removed per hygiene fix) |
| `.claude-plugin/marketplace.json` | Marketplace registry | Modified (version 2.3.0) |
| `kit/plugins/code-review/CHANGELOG.md` | Version history | Modified (2.3.0 entry) |
| `kit/plugins/code-review/README.md` | Plugin documentation | Modified |

## How it works

The `permissionMode: plan` field constrains the agent to read-only exploration at the framework level, independently of which tools are listed. The `disallowedTools` list adds a second layer: even if the agent receives tool access through inheritance, Write/Edit/NotebookEdit calls are blocked. Together these make accidental code modification structurally impossible rather than policy-dependent.

`memory: project` stores reviewer observations in `.claude/agent-memory/code-reviewer/` and loads them at the start of each review. This lets the agent accumulate project-specific knowledge (common patterns, known false positives, team conventions) across sessions without repeating the discovery work each time.

`background: true` means the parent session does not block waiting for the review to complete. The user receives results when the agent finishes, but can continue interacting with Claude in the meantime. This matches the typical code review workflow where a review is initiated and the developer continues writing code.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `6b9fab3` | 2026-03-26 | Merge pull request #51 from shawn-sandy/docs/plan-interview-upgrade |
| `9c70a52` | 2026-03-30 | chore(docs/plans): add YAML frontmatter status to 83 plan files |
| `e15fba2` | 2026-04-04 | refactor: rename agentics/ marketplace subtree to kit/ |

<!-- generated:end -->

## References

- Plan: [improve-code-reviewer-agent-v2.3.md](plans/improve-code-reviewer-agent-v2.3.md)
- Changelog: [kit/plugins/code-review/CHANGELOG.md §2.3.0](../kit/plugins/code-review/CHANGELOG.md)
