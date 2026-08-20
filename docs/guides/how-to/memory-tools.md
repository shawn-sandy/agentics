# How do I... memory-tools

Audit and reshape Claude Code project memory — CLAUDE.md files, the path-scoped rule files in `.claude/rules/`, and usage-insights follow-through.

Install: `/plugin install memory-tools@agentics-kit`

## agentic-memory-management

Scores a CLAUDE.md against Claude Code best practices and offers a tightened rewrite.

- **Command** — `/memory-tools:agentic-memory-management`
- **Say it instead** — "audit my CLAUDE.md and tell me what to cut"
- **What happens** — Resolves the target (explicit path, then `CLAUDE.md`, `.claude/CLAUDE.md`, `~/.claude/CLAUDE.md`), reports line count, instruction estimate, section inventory, a secrets scan, and one-level `@import` totals, then scores 6 dimensions out of 12 with a grade and top-3 recommendations. An optimized version appears in chat before anything is written.
- **Watch out** — The rewrite overwrites the audited file in place, so commit or back it up first; it takes two explicit confirmations, defers all writes while plan mode is active, and verifies the result with `memory-verify-write`.

## path-rules-advisor

Generates path-scoped rule files under `.claude/rules/` so instructions load only for the files they apply to.

- **Command** — `/memory-tools:path-rules-advisor [<glob-pattern> - <rule description>]`
- **Say it instead** — "add a rule that every file under src/api validates its input"
- **What happens** — With an argument it runs Mode A: parses the glob and description, infers a `<segment>-rules.md` filename, and drafts the file. With no argument it runs Mode B, analyzing the project and CLAUDE.md to propose which rule files are worth extracting.
- **Watch out** — Two hard stops before any write: creating `.claude/rules/` and each individual file, plus a third if the filename already exists. Every written file is checked with `memory-verify-write` — stop and restore from backup if it exits non-zero.

## implementing-insights

Triages a usage-insights report against existing config and implements only the genuinely open recommendations across local repos.

- **Command** — `/memory-tools:implementing-insights`
- **Say it instead** — "implement the findings from this insights report"
- **What happens** — Parses the report (file path, artifact URL, or pasted content) into numbered items, buckets each against existing config (already implemented / conflicts with a rule / genuinely open), places open items at the right config layer (plugin, `~/.claude/`, or the target repo), then implements one item per change — one PR per repo change — and closes with a verified outcome ledger.
- **Watch out** — Report content is treated as untrusted data; nothing is written before the triage table and an explicit approval gate, and PRs are never merged without approval in the current turn.
