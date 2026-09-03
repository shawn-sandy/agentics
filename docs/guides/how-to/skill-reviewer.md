# How do I... skill-reviewer

Audit, scaffold, and tune Claude Code skills — SKILL.md quality scores, `allowed-tools` permissions, and frontmatter budgets.

Install: `/plugin marketplace add shawn-sandy/agentics`, then `/plugin install skill-reviewer@agentics-kit`

## auditing-allowed-tools

Works out the minimal `allowed-tools:` a SKILL.md needs, and reports which tools a past session actually invoked.

- **Command** — `/skill-reviewer:auditing-allowed-tools [SKILL.md path] [session UUID]`
- **Say it instead** — "audit the allowed-tools on this skill and fix what's missing"
- **What happens** — Runs one of three modes: static audit of a SKILL.md body, session audit of a `.jsonl` transcript, or cross-reference of both. Prints a Detected/Declared/Status table, then offers to add missing tools, replace with the minimal set, or report only.
- **Watch out** — MCP tools are reported but never written into frontmatter, and the skill refuses to auto-apply edits to its own SKILL.md.

## optimizing-skill-frontmatter

Rewrites a skill's `description:` into the three-part format and sets `disable-model-invocation` to match the skill's workflow.

- **Command** — `/skill-reviewer:optimizing-skill-frontmatter`
- **Say it instead** — Not available; this skill is command-only (`disable-model-invocation: true`).
- **What happens** — Takes a path, a plugin name, or "all"; measures every resolved description, rewrites each to a ≤80-char short description plus capability and "Use when…" trigger, applies the edits in place, re-measures, then offers to sweep the rest of the project's skills.
- **Watch out** — It never writes `disable-model-invocation: false` — `true` for workflow skills, field omitted for advisory ones. The 200/80 char limits are budget targets, not platform limits.

## planning-skills

Walks you through designing a new skill and writes the finished folder to disk.

- **Command** — `/skill-reviewer:planning-skills`
- **Say it instead** — "help me scaffold a new skill for reviewing migrations"
- **What happens** — Asks up to four questions about purpose, trigger, tools, and output, picks a design pattern, plans the folder, drafts frontmatter and body outline, then writes `SKILL.md` plus any `references/`, `scripts/`, and `assets/` files into a directory you confirm first.
- **Watch out** — Nothing is written until you approve the target path; the closing summary points you at `reviewing-skills` to audit what was generated.

## reviewing-skills

Scores an existing SKILL.md across five quality dimensions against Anthropic's skill-authoring best practices.

- **Command** — `/skill-reviewer:reviewing-skills`
- **Say it instead** — "review kit/plugins/foo/skills/bar/SKILL.md and score it"
- **What happens** — Measures the file, scores 5 dimensions (max 10) with a grade, optionally adds a Regression Risk section comparing against the last committed version, prints the report in chat, and offers an optimized rewrite that needs a second confirmation before it touches disk.
- **Watch out** — Skills cannot read `$ARGUMENTS` or `$PWD`, so pass an explicit path. Guidelines come from the bundled `references/best-practices.md` unless you say "use latest"; the regression check is skipped outside git or for uncommitted files.

## Related commands

- `/skill-reviewer:check-description` — Measures `description:` frontmatter length across one or more SKILL.md files and warns on anything over the 200-char budget, multi-line, or missing.
