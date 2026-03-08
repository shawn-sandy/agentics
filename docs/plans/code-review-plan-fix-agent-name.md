# Plan: Code Review for fix/agent-name PR

## Context
User requested a code review of the PR on branch `fix/agent-name`.

## Steps
1. Find and validate the PR (check open, not draft, not automated)
2. Identify relevant CLAUDE.md files
3. Get PR summary
4. Run 5 parallel review agents (CLAUDE.md compliance, bugs, git history, past PRs, code comments)
5. Score issues for confidence
6. Filter to high-confidence issues (score >= 80)
7. Re-check PR eligibility
8. Post review comment via `gh`
