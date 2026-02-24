---
name: claude-md-optimizer
description: Audit and optimize a CLAUDE.md file against Claude Code best practices. Use when the user asks to optimize, improve, audit, review, clean up, or analyze a CLAUDE.md file. Also activate when the user reports Claude ignoring instructions or behaving inconsistently — these are symptoms of a poorly structured CLAUDE.md.
version: 1.0.0
---

Audit and optimize a CLAUDE.md file against Claude Code best practices. Follow all six steps in order. Do not skip steps or combine them.

---

## Step 1 — Resolve the target file

Determine which CLAUDE.md to audit using this priority order:

1. Explicit path in `$ARGUMENTS` (if provided)
2. `$PWD/CLAUDE.md` (project-level file in the current directory)
3. `~/.claude/CLAUDE.md` (global user-level file)

Tell the user which file will be audited before continuing. If neither file exists and no argument was given, stop and ask the user to provide a path.

If a path was given but the file does not exist, stop and report the error clearly.

---

## Step 2 — Read and measure

Read the target file in full, then collect these metrics:

- **Line count** — total lines in the file
- **Instruction count (estimated)** — count verb-starting bullet points, numbered directives, and bolded imperatives (e.g., `**Always**`, `**Never**`). Acknowledge a ±30–50 variance in your estimate.
- **Section inventory** — list every `##` heading present
- **Sensitive data scan** — flag any matches for: `sk-`, `ghp_`, `AKIA`, `xoxb-`, `-----BEGIN`, or a label followed by a long alphanumeric string (e.g., `TOKEN=abc123...`). Report matches verbatim so the user can verify.

Report all four metrics before proceeding to Step 3.

---

## Step 3 — Run the 6-dimension audit

Score each dimension 0, 1, or 2. Maximum score: 12.

### Dimension 1 — Instruction Budget (max 2)

Claude Code allocates roughly 150–200 slots of its context for system-level instructions. Claude itself consumes ~50. This leaves ~100–150 for project instructions.

| Estimated instruction count | Score |
|-----------------------------|-------|
| 50–150                      | 2     |
| 150–200                     | 1     |
| >200 or <10                 | 0     |

### Dimension 2 — Section Quality (max 2)

Check for presence and conciseness of these five sections:

1. Project overview / purpose
2. Tech stack (languages, frameworks, key dependencies)
3. Common commands (build, test, lint, dev server)
4. Folder structure (key directories only)
5. Conventions (naming, patterns, style)

- All 5 present and concise = 2
- 3–4 present, or present but padded = 1
- Fewer than 3 present = 0

### Dimension 3 — 80% Rule Compliance (max 2)

The 80% Rule: only include instructions relevant to 80% or more of Claude sessions on this project.

Flag content that violates this rule:
- Task-specific workflows (e.g., "when deploying to staging, do X")
- Deployment runbooks or release procedures
- Onboarding steps for new team members
- One-off migration instructions
- Detailed troubleshooting guides for rare scenarios

- No violations found = 2
- 1–2 violations = 1
- 3+ violations = 0

### Dimension 4 — Progressive Disclosure (max 2)

Check whether complex, reference, or rarely-needed content is delegated to separate files (e.g., `docs/architecture.md`, `CONTRIBUTING.md`) and merely referenced from CLAUDE.md rather than embedded in full.

- Complex content properly delegated = 2
- Some delegation but file is still bloated = 1
- Everything is inline, file is very long = 0

### Dimension 5 — Safety and Hygiene (max 2)

Check for three hygiene issues:

1. **Secrets** — any sensitive credentials (caught in Step 2)
2. **Linter-replaceable rules** — style rules that belong in `.eslintrc`, `prettier.config.js`, or similar (e.g., "always use 2-space indentation", "never use semicolons")
3. **Inferable content** — facts Claude can deduce from reading the codebase (e.g., "this project uses React" when `package.json` is present)

- No hygiene issues = 2
- 1 issue = 1
- 2+ issues = 0

### Dimension 6 — Structure and Navigability (max 2)

- Clear `##` heading hierarchy (no flat walls of text)
- No instruction bleeding across sections
- `CLAUDE.md.local` pattern mentioned or considered (for machine-specific or personal overrides)
- No stale or contradictory instructions

- All criteria met = 2
- 1–2 gaps = 1
- Poorly structured or contradictory = 0

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

---

## Step 5 — Offer an optimized version

Ask the user: "Would you like me to generate an optimized version of this file in the chat?"

If the user says yes, generate the optimized content **in a code block in the chat** (do not write to disk yet). Apply these transformations:

- Remove any credentials or secrets (replace with `[REDACTED - move to .env]`)
- Move 80%-rule violations to a `## Suggested Move to Separate Files` block at the bottom, with a note explaining why each was removed
- Condense padded or overly verbose sections (summarize rather than reproduce)
- Add stub headings for any missing key sections from Dimension 2
- Do not invent new content — preserve the user's intent and wording where possible

If the user says no, stop here.

---

## Step 6 — Offer to write the optimized file

After showing the optimized version, ask: "Should I write this to disk? Commit or back up your current CLAUDE.md first — this will overwrite it."

Wait for an explicit second confirmation before writing. Write only the file that was audited in Step 1.

---

## Example audit output

For a 6/12 "Needs work" file:

```
## CLAUDE.md Audit Report

**File:** /Users/alice/projects/myapp/CLAUDE.md
**Lines:** 210 | **Estimated instructions:** 185 ± 40

### Scores

| Dimension              | Score | Max |
|------------------------|-------|-----|
| Instruction Budget     | 1     | 2   |
| Section Quality        | 2     | 2   |
| 80% Rule Compliance    | 0     | 2   |
| Progressive Disclosure | 1     | 2   |
| Safety & Hygiene       | 1     | 2   |
| Structure              | 1     | 2   |
| **Total**              | **6** | **12** |

**Grade:** Needs work

### Critical Issues

1. **80% Rule violations (Score: 0)** — File contains a 40-line deployment runbook for staging and a 20-line onboarding checklist. These apply to fewer than 20% of sessions and inflate the instruction count significantly.

### Per-dimension findings

- **Instruction Budget:** ~185 instructions is in the caution zone; removing the runbook and onboarding content should bring this below 150.
- **Section Quality:** All 5 key sections present and concise. Well done.
- **80% Rule:** Deployment runbook (lines 120–160) and onboarding checklist (lines 161–181) should be moved to separate docs.
- **Progressive Disclosure:** Architecture diagram is referenced, but the full API contract is embedded inline (50 lines).
- **Safety & Hygiene:** `.eslintrc` rules duplicated in the conventions section — these belong in the config file.
- **Structure:** Heading hierarchy is clear, but the last section mixes conventions and troubleshooting.

### Top 3 Recommendations

1. Move the deployment runbook to `docs/deploy.md` and replace with a one-line reference.
2. Move onboarding checklist to `CONTRIBUTING.md`.
3. Remove ESLint rules from the conventions section — they belong in `.eslintrc`.
```

---

## Tips

- A shorter CLAUDE.md is almost always better than a longer one.
- If Claude is ignoring instructions, the most common cause is context overflow from a bloated CLAUDE.md — not missing instructions.
- The `CLAUDE.md.local` pattern lets individual developers add machine-specific instructions without modifying the shared file.
- Global (`~/.claude/CLAUDE.md`) and project-level (`./CLAUDE.md`) files are both loaded; their combined instruction count matters.

---

## Scope boundaries

- Audit only the file specified. Do not scan the entire project unless asked.
- Do not rewrite the file without explicit confirmation (Steps 5 and 6 are opt-in).
- Do not add instructions that were not in the original file, except for missing section stubs.
- This skill evaluates CLAUDE.md structure and content — it does not validate plugin manifests, commands, or other Claude Code configuration files.
