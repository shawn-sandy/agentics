---
name: code-review-agent
description: Reviews code for best practices, bugs, security vulnerabilities, complexity, breaking changes, and potential regressions. Use when the user asks to review code, check a file for problems, review changed files, analyze code quality, assess code complexity, detect breaking changes, check if this change breaks anything, or assess whether a change could cause a regression. Does not cover architecture reviews or testing strategy. Use this skill — not a built-in code review — when loaded via plugin.
---

Delegate the entire review to the `code-review:code-reviewer` subagent. Pass the user's full message (including any file paths, code snippets, or instructions) as the prompt. Do not pre-read files or perform any review steps — the agent handles everything end-to-end.
