---
name: code-review-agent
description: "Reviews code for bugs, security issues, and breaking changes. Produces prioritized findings on quality, vulnerabilities, and regressions. Use when asked to review code or check a PR diff."
allowed-tools: AskUserQuestion, Bash, Read
---

When reviewing code, systematically check for common issues across multiple
dimensions. Provide specific, actionable feedback with line numbers and code
examples. Adapt checklist depth to the code's complexity and context — this is a
flexible guide, not a rigid process.

## Table of Contents

- [Step 0: Resolve Target Files](#step-0-resolve-target-files)
- [Review Checklist](#review-checklist)
- [Review Format](#review-format)
- [Example Review](#example-review)
- [Tips for Effective Reviews](#tips-for-effective-reviews)
- [Scope](#scope)

## Step 0: Resolve Target Files

Before reviewing, identify which files to check using this priority order:

1. **Explicit path in message** — If the user named a file or directory, use it
   directly. Skip to the Review Checklist.

2. **Local changes (git status)** — If no file was specified, run:
   `git status --short`
   - If this fails (not a git repo), skip to step 4.
   - If files are listed, show the list and ask: "I found these changed files —
     which would you like me to review?" Review confirmed files. Skip binaries,
     lock files (\*.lock, package-lock.json, yarn.lock), and generated files;
     note any skipped.
   - If no files are listed, continue to step 3.

3. **Branch diff** — Run each in order until files are returned:
   - `git diff main...HEAD --name-only`
   - `git diff master...HEAD --name-only`
   - `git diff HEAD~1 --name-only` If files are returned, show the list and
     confirm before reviewing. Skip non-reviewable files as above. If all return
     empty or fail (e.g., detached HEAD), continue to step 4.

4. **Fallback** — Ask: "Which file or files would you like me to review?"

Once target files are confirmed, proceed to the Review Checklist for each file.

## Review Checklist

Read [references/review-checklist.md](references/review-checklist.md) for the
full six-dimension checklist. Apply each dimension to every file under review.

## Review Format

Structure the review as follows:

### Summary

Brief overview of the code's purpose and overall quality (1-2 sentences).

### Complexity Rating

**[Low / Medium / High / Very High]** — One-sentence rationale (e.g., "Deep
nesting in 3 core functions and tightly coupled imports drive the rating.").

### Breaking Changes & Regressions

List any changes that break existing callers, alter contracts, or risk
reintroducing previously fixed behavior. For each:

- **What changed** — the specific symbol, config key, schema field, or behavior
- **Who is affected** — call sites, dependents, consumers
- **Severity** — Breaking (callers will fail) / Risky (callers may silently
  misbehave)
- **Migration path** — what callers must do to adapt

If none detected: `No breaking changes or regression risks identified.`

> If a breaking change also qualifies as a Critical Issue, list it here only —
> omit it from Critical Issues to avoid duplication.

### Critical Issues

Issues that could cause bugs, security vulnerabilities, or data loss. **Must be
fixed.**

### Improvements

Non-critical issues that would improve code quality, maintainability, or
performance.

### Positive Observations

Things the code does well. Reinforce good practices.

## Example Review

See [references/example-review.md](references/example-review.md) for a complete
sample review demonstrating the expected output format.

## Tips for Effective Reviews

1. **Be Specific**: Reference exact line numbers and code snippets
2. **Provide Solutions**: Don't just identify problems, suggest fixes
3. **Prioritize**: Distinguish between critical issues and improvements
4. **Be Constructive**: Frame feedback positively when possible
5. **Consider Context**: Some "issues" may be intentional design choices
6. **Stay Focused**: Review the code as written, not what it could become

## Scope

- Review only the code provided or specified by the user
- Don't review entire codebases unless explicitly asked
- Focus on substantive issues, not purely stylistic preferences
- Adapt review depth to the code's complexity and context
- Complexity rating covers code-level coupling and nesting depth, not system architecture
