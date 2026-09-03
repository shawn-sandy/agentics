# How do I... code-review

Reviews code for bugs, security issues, and breaking changes, and can fix a whole branch against the repo's own rules.

Install: `/plugin marketplace add shawn-sandy/agentics`, then `/plugin install code-review@agentics-kit`

## code-review-agent

Reviews the code you point it at and reports prioritized findings with line numbers and suggested fixes.

- **Command** — `/code-review:code-review-agent [file or directory]`
- **Say it instead** — "review the code I just changed"
- **What happens** — With no path it resolves targets in order — `git status --short`, then a `main...HEAD` / `master...HEAD` / `HEAD~1` diff — and asks you to confirm the list before reviewing. Output prints in the session as a summary, complexity rating, breaking changes, critical issues, improvements, and positive observations.
- **Watch out** — Every finding is re-read against the cited lines before reporting, so anything it cannot quote verbatim is dropped or labelled **Unconfirmed**; binaries, lock files, and generated files are skipped, and it will not sweep a whole codebase unless you ask.

## Related commands

- `/code-review:fix-branch [base-branch]` — Reviews every file changed vs the default branch against repo rules, project conventions, and frontmatter constraints, then autonomously applies blocking, major, and minor fixes (left uncommitted). Refuses to run on a dirty working tree, and does not review code logic — that is the `code-review-agent` skill's job.
