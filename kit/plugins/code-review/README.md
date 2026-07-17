# code-review Plugin

Structured, multi-dimensional code review across quality, bugs, security, best practices, complexity, and breaking changes & regressions. Provides specific, actionable feedback with line numbers and suggested fixes.

## Installation

### Via Marketplace (recommended)

```bash
/plugin install code-review@agentics-kit
```

### Local Development

```bash
claude --plugin-dir ./kit/plugins/code-review
```

## Usage

### Commands

| Command | Invocation | Description |
|---------|-----------|-------------|
| `fix-branch` | `/code-review:fix-branch [base-branch]` | Review all branch changes vs the default branch, then autonomously fix blocking, major, and minor issues until the branch is clean. Leaves fixes uncommitted. |

### Skills

| Skill | Activation | Trigger phrases |
|-------|-----------|-----------------|
| `code-review-agent` | Auto-activated — triggers when user intent matches the description | review code, check for bugs, look over a PR, find security issues, detect breaking changes, check a PR diff |

### Agents

| Agent | Invocation | Description |
|-------|-----------|-------------|
| `agent-code-reviewer` | Delegated — invoked by other agents via `Agent(subagent_type: "code-review:agent-code-reviewer", ...)` | Internal background agent for delegation from other agents or automated workflows. Not for direct user requests — those are handled by the `code-review-agent` skill. |

### Automatic activation (skill)

Describe what you want reviewed:

```
Review this function for bugs
Check this file for security issues
Analyze the code quality in src/api/users.ts
Look for problems in my authentication module
```

### Providing specific code

Paste code directly in your message or reference a file:

```
Review this code: [paste code]
Check src/components/LoginForm.tsx for security issues
```

## Purpose

Code review is most effective when it's structured and consistent. This plugin applies a repeatable checklist across six dimensions so nothing slips through. It automatically resolves which files to review from git status, branch diffs, or explicit paths, and produces a structured report with severity-ranked findings.

## Skills

| Skill | Activation |
|-------|-----------|
| `code-review-agent` | Triggers when the user directly asks to review code, check files for problems, look over a PR or diff, assess quality or complexity, find bugs or security issues, detect breaking changes, or evaluate regression risk. Also triggers for informal requests like "take a look at this." |

All skills declare `allowed-tools` explicitly in their frontmatter for consistent, session-independent tool access.

## Commands

| Command | Invocation |
|---------|-----------|
| `fix-branch` | `/code-review:fix-branch [base-branch]` |

### `fix-branch`

Reviews every file changed on the current branch vs the default remote branch. Classifies findings as blocking / major / minor / unfixable, applies fixes autonomously via `Edit`/`Write`, and stops — leaving fixes uncommitted so you can inspect them with `git diff`.

```bash
# Review branch vs auto-detected default (main/master)
/code-review:fix-branch

# Review branch vs an explicit base
/code-review:fix-branch develop
```

**What it checks:** repo rules (`.claude/rules/*.md`), project conventions (`CLAUDE.md`/`CLAUDE.local.md`), frontmatter validation (SKILL.md, plugin.json, marketplace.json), and plan verification sections for any modified `docs/plans/` files. For `SKILL.md` and agent definition files, it delegates review to the `skill-reviewer` plugin and merges its findings.

**What it does not do:** no logic/security/performance review — use `code-review-agent` for that. No commit or PR — use `/git-agent:commit-agent` and `/git-agent:pr-agent` after reviewing the diff.

## Review Checklist Overview

The skill checks across six dimensions:

1. **Code Quality** — readability, maintainability, naming conventions, DRY principle
2. **Potential Bugs** — common errors, edge cases, async/concurrency issues
3. **Security Vulnerabilities** — input validation, auth/authz, data exposure, dependency risks
4. **Best Practices** — error handling, type safety, performance, documentation
5. **Code Complexity** — structural complexity, coupling/cohesion, cognitive load (Low/Medium/High/Very High rating)
6. **Breaking Changes & Regressions** — public API surface, shared contracts, data/config contracts, regression risk

## Agent (Internal)

The plugin includes an `agent-code-reviewer` sub-agent for delegation from other agents or automated workflows. This agent is **not intended for direct user requests** — those are handled by the `code-review-agent` skill above. The agent runs in read-only mode (`permissionMode: plan`) with project-scoped persistent memory and background execution. It uses confidence-based filtering to surface only high-priority findings.

| Field | Value |
|-------|-------|
| Model | Sonnet |
| Tools | Read, Glob, Grep, Bash |
| Disallowed Tools | Write, Edit, NotebookEdit |
| Permission Mode | `plan` (enforced read-only) |
| Max Turns | 10 |
| Memory | Project-scoped (`.claude/agent-memory/agent-code-reviewer/`) |
| Background | Yes (non-blocking) |

### When to use the agent

The agent is designed for three scenarios:

1. **Delegation from another agent** — a parent agent spawns `agent-code-reviewer` to get a code quality assessment as part of a larger workflow
2. **Second opinion** — an agent performing a different task (e.g., feature development) delegates a review to check its own output
3. **Proactive sweeps** — triggered after a branch switch, merge, or batch of commits to catch issues early without blocking the user

### Delegating to the agent

Other agents or skills can invoke the agent using the `Agent` tool:

```
Agent(
  subagent_type: "code-review:agent-code-reviewer",
  prompt: "Review the changed files on this branch for bugs and security issues."
)
```

The agent runs in the background (`background: true`) and returns a structured report when complete. Because it uses `permissionMode: plan`, it cannot modify any files — it only reads and reports.

### Agent memory

The agent maintains project-scoped memory across sessions. It learns recurring patterns, project conventions, and known false positives so that repeated reviews become more accurate over time. Memory is stored in `.claude/agent-memory/agent-code-reviewer/`.

### Example: skill review (user-initiated)

**User prompt:**

```text
Take a look at src/auth/login.ts — anything wrong with this code?
```

**Skill output:**

```markdown
### Summary
Authentication handler for user login. Overall quality is good with one
critical security issue in token handling.

### Complexity Rating
**Medium** — Moderate branching with OAuth and password flows, but
well-structured with clear separation.

### Breaking Changes & Regressions
No breaking changes or regression risks identified.

### Critical Issues
**Hardcoded JWT secret** — `src/auth/login.ts:42`
The signing key is hardcoded as a string literal instead of loaded from
environment variables. This exposes the secret in source control.

Fix: `const secret = process.env.JWT_SECRET`

### Improvements
- `src/auth/login.ts:28` — `validatePassword` silently returns `false`
  on error. Consider logging the failure reason for debugging.

### Positive Observations
- Clean separation between OAuth and password authentication paths
- Input validation runs before any database queries
```

### Example: agent review (delegated from another agent)

A feature development agent delegates a review after generating code:

```text
Agent(
  subagent_type: "code-review:agent-code-reviewer",
  prompt: "Review src/auth/login.ts and src/auth/oauth.ts for security
           issues and breaking changes. Focus on the changes made in
           the current branch.",
  run_in_background: true
)
```

The agent returns the same structured report format but filters more aggressively — only high-confidence findings appear. The calling agent receives the report and can act on it without user intervention.

The `prompt` parameter is a free-form string — the calling agent can compose it dynamically with any context it has: file paths from `git diff`, user-provided arguments, error messages, or results from previous steps. There is no formal parameter injection (like `$ARGUMENTS` in commands); the calling agent simply builds the prompt string at runtime.

### Review output format

Reviews are structured as:

1. **Summary** — brief overview of code purpose and overall quality
2. **Complexity Rating** — Low/Medium/High/Very High with a one-sentence rationale
3. **Breaking Changes & Regressions** — changes that break callers, alter contracts, or risk regressions
4. **Critical Issues** — bugs, security vulnerabilities, data loss risks (must fix)
5. **Improvements** — non-critical quality and maintainability suggestions
6. **Positive Observations** — what the code does well
