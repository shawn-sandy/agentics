---
name: agentic-memory-doctor
description: "Audits and optimizes CLAUDE.md project memory files. Checks adherence to Claude Code best practices and produces actionable fixes. Use when the user asks to audit, optimize, or diagnose a CLAUDE.md."
allowed-tools: AskUserQuestion, Glob, Grep, Read, Write
---

Audit and optimize a CLAUDE.md / project memory file against Claude Code best practices.

> **Optimization principle** — Keep only rules that would change Claude's behavior versus its
> built-in defaults; cut everything else. Tighten the rules that survive so each load-bearing
> instruction reads crisply: verb-first, one idea per bullet, no hedging. This principle governs
> both the audit (what to flag) and the rewrite (what to keep or cut in Step 5).

> **Freedom level: Rigid** — Execute all six steps in the order listed. Do not skip, combine,
> or reorder them.
> **Plan-mode pre-check** — If the system indicates plan mode is active when reaching Step 5,
> defer all write-related prompts and actions (Steps 5–6, including rule-file creation and
> CLAUDE.md overwrites) until the user exits plan mode. Read-only steps (1–4) may proceed in plan mode.
> **Operational rules** — Audit only the file specified. Do not scan the entire project unless
> asked. Steps 5 and 6 are opt-in — do not rewrite the file without explicit confirmation.
> Memory load order: project rules → project memory → user memory → `CLAUDE.local.md`. Combined
> instruction count across all loaded files is what matters. Use `@path/to/file` import syntax to
> reference external docs without embedding their full content.

## When not to use

Does not cover SKILL.md files, slash commands, or general markdown.

## Table of Contents

- [Step 1 — Resolve the target file](#step-1--resolve-the-target-file)
- [Step 2 — Read and measure](#step-2--read-and-measure)
- [Step 3 — Run the 6-dimension audit](#step-3--run-the-6-dimension-audit)
- [Step 4 — Present the scored report](#step-4--present-the-scored-report)
- [Step 5 — Offer an optimized version](#step-5--offer-an-optimized-version)
- [Step 6 — Offer to write the optimized file](#step-6--offer-to-write-the-optimized-file)

---

## Step 1 — Resolve the target file

Determine which CLAUDE.md to audit using this priority order:

1. Explicit path provided in the user's message (if present)
2. `CLAUDE.md` in the current working directory (primary project location)
3. `.claude/CLAUDE.md` in the current working directory (alternate, checked if primary absent)
4. `~/.claude/CLAUDE.md` (global user-level)

If both `CLAUDE.md` and `.claude/CLAUDE.md` exist, audit `CLAUDE.md` (root takes priority) and note that the alternate location was skipped.

Tell the user which file will be audited before continuing. If none of the four locations has a file and no argument was given, stop and ask the user to provide a path.

If a path was given but the file does not exist, stop and report the error clearly.

---

## Step 2 — Read and measure

Read the target file in full (`Read`), then collect these metrics:

- **Line count** — total lines in the file
- **Instruction count (estimated)** — count verb-starting bullet points, numbered directives, and bolded imperatives (e.g., `**Always**`, `**Never**`). Acknowledge a ±30–50 variance in your estimate.
- **Section inventory** — list every `##` heading present
- **Sensitive data scan** — use `Grep -nE` on the target file with the pattern `sk-|ghp_|AKIA|xoxb-|-----BEGIN|[A-Z_]+=[[:alnum:]_]{20,}`. Report each match with its line number and a masked value (never print full secret text). Masking rule: if token length ≥ 8, show first 4 + `***` + last 4 (e.g. `sk-a***b3x4`); if length 4–7, show first 2 + `***` + last 2; if length < 4, show `****`. If no matches, report "No secrets found."
- **Import scan** — detect any `@path/to/file` references in the file. List each one found. Determine the import root: if the audited file is inside the workspace (current working directory), use the workspace root; if it is outside (e.g., `~/.claude/CLAUDE.md`), use the audited file's own directory as the root. Resolve each import relative to the audited file's directory, then reject any path that is absolute, contains `..` traversal, or resolves outside the import root; for rejected paths report "import `<path>` rejected: outside project root" and skip `Read`. For each allowed imported file, attempt to `Read` it and report its line count — do not follow imports found inside those files (strictly one level deep). If the imported file exceeds 500 lines, skip counting it but include a warning: "import `<path>` has N lines — exceeds 500-line cap, not counted." Sum the counts of all imports under the cap and report as "effective lines (incl. imports): N (approximate, one level deep)." Note that imported content counts toward effective instruction load but is not visible in the raw line count.

Report all five metrics before proceeding to Step 3.

---

## Step 3 — Run the 6-dimension audit

Score each dimension 0, 1, or 2. Maximum score: 12.

Full dimension definitions, scoring tables, and example audit output are in
[`references/audit-steps.md`](references/audit-steps.md). Load that file before scoring.

---

## Step 4 — Present the scored report

Output a structured report in this format:

```
## CLAUDE.md Audit Report

**File:** [path audited]
**Lines:** [n] | **Estimated instructions:** [n ± 30–50]

### Scores

| Dimension              | Score | Max |
|------------------------|-------|-----|
| Instruction Budget     | [n]   | 2   |
| Section Quality        | [n]   | 2   |
| 80% Rule Compliance    | [n]   | 2   |
| Progressive Disclosure | [n]   | 2   |
| Safety & Hygiene       | [n]   | 2   |
| Structure              | [n]   | 2   |
| **Total**              | **[n]** | **12** |

**Grade:** [see scale below]
```

Grade scale:

| Total | Grade        |
|-------|--------------|
| 10–12 | Optimized    |
| 7–9   | Functional   |
| 4–6   | Needs work   |
| 0–3   | Rewrite      |

After the table:

1. **Critical Issues** — list any secrets found, plus dimension scores of 0, in priority order
2. **Per-dimension findings** — one bullet per dimension with specific observations
3. **Top 3 recommendations** — the highest-impact changes, in order

> When Progressive Disclosure scores 0 or 1, include as a Top 3 item: "Consider invoking the
> sibling `memory-tools:path-rules-advisor` skill to break path-specific content into
> `.claude/rules/` files — it is purpose-built for this workflow. You can also use Step 5's
> inline rule-file generation as a fallback."

> When Safety & Hygiene scores below 2 due to default-restating rules, name them explicitly in
> the per-dimension finding: quote one or two examples from the file and label them "default-restating" so the user can recognise the pattern and apply the same cut test to the rest.

---

## Step 5 — Offer an optimized version

Use `AskUserQuestion` to ask: "Would you like me to generate an optimized version of this file in the chat?" (Yes / No)

If the user says yes, generate the optimized content **in a code block in the chat** (do not write to disk yet). Apply these transformations:

- Remove any credentials or secrets (replace with `[REDACTED - move to .env]`)
- Extract 80%-rule violations and path-specific content — these will be offered as `.claude/rules/` files below, not embedded in the CLAUDE.md output
- Condense padded or overly verbose sections (summarize rather than reproduce)
- Add stub headings for any missing key sections from Dimension 2
- Cut rules that only restate Claude's built-in behavior — keep only rules that would change what Claude does by default (e.g., "write clear code" is a default; "never abbreviate variable names in this codebase" is a rule)
- Tighten kept rules to crisp imperatives — verb-first, one idea per bullet, no hedging or padding; preserve the user's stated intent and any constraint they called out explicitly
- Do not invent new content — preserve the user's intent and wording where possible

**Offer to generate `.claude/rules/` files:**

For each section removed as an 80%-rule violation or path-specific content:
1. Show the proposed rule file in a code block with `paths:` frontmatter:

```md
---
paths:
  - "<glob>"
---

# <Descriptive Title>

- Rule bullet 1
- Rule bullet 2
- Rule bullet 3
```

2. Check if `.claude/rules/` exists. If not, use `AskUserQuestion` to ask: "The `.claude/rules/` directory does not exist. Should I create it?" (Yes / No)
3. Use `AskUserQuestion` to ask: "Should I write this to `.claude/rules/<name>.md`?" (Yes / No) Wait for explicit confirmation before writing each file.

> **Path-rules delegation:** If Progressive Disclosure scored ≤ 1, recommend invoking
> `memory-tools:path-rules-advisor` instead of manually creating rule files here. Keep the
> inline flow above as a fallback if the user prefers to stay in this skill.

**After the CLAUDE.md code block, show a separate callout:**

---
**To make this skill always available in your project**, add the following to your CLAUDE.md
(replace `<plugin-dir>` with the path passed to `--plugin-dir` when loading this plugin):

```md
@<plugin-dir>/skills/agentic-memory-doctor/SKILL.md
```
---

If the user says no, stop here.

---

## Step 6 — Offer to write the optimized file

Use `AskUserQuestion` to ask: "Should I write this to disk? Commit or back up your current CLAUDE.md first — this will overwrite it." (Yes / No)

If the user says yes, use `AskUserQuestion` again with: "Final confirmation: overwrite `<audited file path>` with the optimized version now?" (Yes / No)

Write only the file that was audited in Step 1, and only after both confirmations are affirmative.
