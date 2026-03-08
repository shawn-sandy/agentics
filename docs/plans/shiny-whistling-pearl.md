# Plan: Code Review for PR #37

## Context

PR #37 (`feat(plugins/code-review): add code-reviewer sub-agent`) extracts code-reviewer logic into a dedicated sub-agent and bumps the code-review plugin to v2.2.0. This plan executes the structured code review skill workflow.

## Steps

1. Verify PR eligibility (open, not draft, no prior Claude review)
2. Identify relevant CLAUDE.md files
3. Launch 5 parallel review agents (CLAUDE.md compliance, bug scan, git history, prior PRs, code comments)
4. Score each issue found (0-100 confidence)
5. Filter to issues >= 80 confidence
6. Post review comment on PR via `gh`

## Key Files

- `.claude-plugin/marketplace.json`
- `plugins/code-review/.claude-plugin/plugin.json`
- `plugins/code-review/agents/code-reviewer.md`
- `plugins/code-review/skills/code-review-agent/SKILL.md`
- `plugins/code-review/CHANGELOG.md`
- `plugins/code-review/README.md`
- `docs/evals/eval_set.json`
- `CLAUDE.md`, `.claude/rules/marketplace.md`, `.claude/rules/plugin-patterns.md`
