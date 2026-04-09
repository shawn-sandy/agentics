---
name: md-optimizer
description: Use when the user asks to audit, optimize, review, clean up, or improve a CLAUDE.md file. Also use when Claude is ignoring instructions, behaving inconsistently, or the CLAUDE.md appears bloated or overloaded. Does not cover SKILL.md files, plugin commands, or other markdown files.
allowed-tools: AskUserQuestion, Glob, Read, Write
---

Audit and optimize a CLAUDE.md file against Claude Code best practices.

> **Freedom level: Rigid** — Execute all six steps in the order listed. Do not skip, combine,
> or reorder them.

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

Tell the user which file will be audited before continuing. If none of the four locations has a file and no argument was given, stop and ask the user to provide a path.

If a path was given but the file does not exist, stop and report the error clearly.

---

## Step 2 — Read and measure

Read the target file in full, then collect these metrics:

- **Line count** — total lines in the file
- **Instruction count (estimated)** — count verb-starting bullet points, numbered directives, and bolded imperatives (e.g., `**Always**`, `**Never**`). Acknowledge a ±30–50 variance in your estimate.
- **Section inventory** — list every `##` heading present
- **Sensitive data scan** — flag any matches for: `sk-`, `ghp_`, `AKIA`, `xoxb-`, `-----BEGIN`, or a label followed by a long alphanumeric string (e.g., `TOKEN=abc123...`). Report matches verbatim so the user can verify.
- **Import scan** — detect any `@path/to/file` references in the file. List each one found. Note that imported content counts toward effective instruction load but is not visible in the raw line count.

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

> When Progressive Disclosure scores 0 or 1, include as a Top 3 item: "Use Step 5's rule-file generation to break path-specific content into `.claude/rules/` files."

---

## Step 5 — Offer an optimized version

Ask the user: "Would you like me to generate an optimized version of this file in the chat?"

If the user says yes, generate the optimized content **in a code block in the chat** (do not write to disk yet). Apply these transformations:

- Remove any credentials or secrets (replace with `[REDACTED - move to .env]`)
- Extract 80%-rule violations and path-specific content — these will be offered as `.claude/rules/` files below, not embedded in the CLAUDE.md output
- Condense padded or overly verbose sections (summarize rather than reproduce)
- Add stub headings for any missing key sections from Dimension 2
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

2. Check if `.claude/rules/` exists. If not, ask: "The `.claude/rules/` directory does not exist. Should I create it?"
3. Ask: "Should I write this to `.claude/rules/<name>.md`?" Wait for explicit confirmation before writing each file.

**After the CLAUDE.md code block, show a separate callout:**

---
**To make this optimizer always available in your project**, add the following to your CLAUDE.md
(replace `<plugin-dir>` with the path passed to `--plugin-dir` when loading this plugin):

```md
@<plugin-dir>/skills/claude-md-optimizer/SKILL.md
```
---

If the user says no, stop here.

---

## Step 6 — Offer to write the optimized file

After showing the optimized version, ask: "Should I write this to disk? Commit or back up your current CLAUDE.md first — this will overwrite it."

Wait for an explicit second confirmation before writing. Write only the file that was audited in Step 1.
