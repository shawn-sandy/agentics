# Audit Steps (Steps 3-7)

This reference file is loaded by `reviewing-agents` to complete the audit
workflow.

---

## Regression Risk Check (Step 2c Detail)

### Comparison Matrix

| Field / Metric | How to Extract (Previous Version) | Risk Level | Condition |
|----------------|-----------------------------------|------------|-----------|
| `name:` | Parse YAML frontmatter from `git show` output | **BREAKING** | Any change |
| Trigger phrases in `description:` | Extract all "Use when..." clauses | **BREAKING** | Any clause present in previous but absent in current |
| `tools` list | Parse YAML array or comma-separated string | **WARNING** | Tools added or removed |
| `model` or `permissionMode` | Parse YAML scalar values | **WARNING** | Value changed |
| `description:` activation intent | Check whether "Use when..." clause and >= 3 domain keywords from previous description appear in current | **WARNING** | Clause missing or < 3 original keywords survive |
| Total line count | Count lines in `git show` output | **WARNING** | Current < 70% of previous |
| New anti-patterns | Apply Dimension checks to previous version | **INFO** | New error/warning anti-pattern in current that was absent before |

**Notes:**
- Parse frontmatter by reading lines between first and second `---` delimiters
  in `git show` output. If `description:` spans multiple lines (folded YAML),
  collect all continuation lines until the next top-level key.
- If `git show` returns non-zero exit: skip all comparisons and note "No
  previous version found -- file may have been renamed" in report.

### Skip Conditions

Omit the Regression Risk section from the report entirely if:
- `git rev-parse --git-dir` exits non-zero
- `git log --oneline -1 -- <path>` returns empty output
- User opted out

### Report Template

Append after the Scores table and before Grade. Three variants:

**Skipped:**
```
**Regression Risk:** Skipped -- [not a git repo | file not yet committed | user opt-out | no previous version found]
```

**Clean:**
```
**Regression Risk:** None detected -- no breaking changes or regressions vs. last commit.
```

**Findings:**
```
## Regression Risk

**Previous version:** git HEAD (`git show HEAD:<path>`)

| Risk | Field / Metric | Previous | Current | Impact |
|------|----------------|----------|---------|--------|
| BREAKING | `name:` | `old-name` | `new-name` | Invocation references break |
| WARNING | `tools` list | `Read, Grep` | `Read, Grep, Bash` | Tool access expanded |
| INFO | New anti-pattern | -- | Agent in tools | Subagents cannot spawn subagents |
```

---

## Golden Template Comparison (Step 2c -- New Files)

For files with no git history, compare against the golden template in
`references/best-practices.md` section 7.

### Template Gap Report

```
## Template Gaps

This is a new agent file with no git history. Comparing against the expected
structural template:

| Section | Status | Note |
|---------|--------|------|
| `## Role` | Present / Missing | [context] |
| `## Workflow` / `## Behavior` | Present / Missing | [context] |
| `## Output Format` | Present / Missing / N/A | [context if applicable] |
| `## Scope Boundaries` | Present / Missing | [context] |
| Memory instructions | Present / Missing / N/A | [required if memory: is set] |
| STOP instruction | Present / Missing / N/A | [required if background: true] |
```

Template gaps do not affect dimension scores directly -- the dimension scoring
already checks for these sections. The template gap report provides additional
context for new files.

---

## Step 3: Score 5 Dimensions

Each dimension is scored 0-2 points. Maximum total: 10.

### Dimension 1: Frontmatter Compliance (0-2 pts)

**Checks:**
- `name` present, valid format (lowercase, hyphens, <= 64, no reserved words)
- `description` present, <= 1024 chars, third person
- Optional fields use valid values (see best-practices.md section 1)
- No invalid field names (typos or unsupported fields)
- YAML parses correctly
- No duplicate YAML keys

**Scoring:**

| Score | Criteria |
|-------|----------|
| 2 | All required fields valid. Optional fields (if present) use valid values. No duplicates. |
| 1 | Minor issues: description slightly over limit, missing trigger phrase, or 1 unrecognized field. |
| 0 | Missing required field, invalid name format, YAML parse error, non-YAML frontmatter, or duplicate keys. |

### Dimension 2: Tool Configuration (0-2 pts)

**Checks:**
- Least privilege: does agent have tools it doesn't reference in body?
- `Agent` tool in subagent (no effect -- warning)
- Both `tools` and `disallowedTools` set (valid but note)
- Read-only agents: `disallowedTools` includes Write, Edit, NotebookEdit?
- Background agents: unrestricted mutation tools?
- Inherits all tools (no `tools` field): appropriate or too broad?

**Scoring:**

| Score | Criteria |
|-------|----------|
| 2 | Minimal necessary tools declared. Appropriate restrictions for agent type. No Agent tool. |
| 1 | 1-2 extra tools beyond what body references, or minor over-permission. |
| 0 | Agent tool in subagent, background with unrestricted mutations, or completely unrestricted tools for a specialized agent. |

### Dimension 3: Description Quality (0-2 pts)

**Checks:**
- "Use when..." trigger phrase present
- Delegation context (explains when to delegate, not just what it does)
- Scope exclusion ("Does NOT...", "Not intended for...")
- >= 3 searchable keywords
- Third person (no I/you/we/your)
- <= 1024 characters

**Scoring:**

| Score | Criteria |
|-------|----------|
| 2 | Clear delegation triggers with "Use when...", scope defined, >= 3 keywords, third person. |
| 1 | Trigger present but vague, OR missing scope exclusion, OR < 3 keywords. |
| 0 | No "Use when...", first/second person, way too vague, or missing description entirely. |

### Dimension 4: System Prompt Quality (0-2 pts)

**Checks:**
- `## Role` section present
- `## Workflow` or `## Behavior` section present (numbered steps or structured)
- Output format defined (for agents that produce reports)
- Scope boundaries defined (in scope / out of scope)
- STOP instruction (for `background: true` agents)
- Guard steps (for agents that mutate state via Bash/Write/Edit)
- Memory consult/update instructions (if `memory:` field is set)
- Body length 20-300 lines
- No hardcoded absolute paths
- No time-sensitive content

**Scoring:**

| Score | Criteria |
|-------|----------|
| 2 | Role + Workflow present. Output format defined (if applicable). Scope clear. Background agents have STOP. Memory agents have instructions. |
| 1 | Missing output format or scope boundaries, OR body slightly outside length range (15-19 or 301-350 lines). |
| 0 | No Role OR no Workflow, background agent without STOP, memory set without instructions, body empty or > 350 lines. |

### Dimension 5: Security & Isolation (0-2 pts)

**Checks:**
- `bypassPermissions` used (flag always)
- `background: true` + unrestricted mutations (flag)
- Plugin agent with permissionMode/hooks/mcpServers set (unless marketplace repo)
- Memory without memory instructions in body
- `maxTurns` outside 5-50 range

**Scoring:**

| Score | Criteria |
|-------|----------|
| 2 | No security concerns. Appropriate isolation. Safe defaults. All memory/background patterns correct. |
| 1 | Minor issues: maxTurns slightly outside range, plugin agent with permissionMode (non-marketplace). |
| 0 | `bypassPermissions` without justification, background + unrestricted mutations, critical safety gap. |

---

## Step 4: Output Scored Report

Present the report in this format:

```markdown
## Agent Audit Report: `<agent-name>`

**File:** `<file-path>`
**Agent Type:** [Read-only | Editor | Background | Orchestrator]
**Guidelines Source:** [Static reference | Live fetch (date)]

### Summary

[1-2 sentences on the agent's purpose and overall quality]

### Metrics

| Metric | Value |
|--------|-------|
| Total lines | [n] |
| Body lines | [n] |
| Body word count | [n] |
| Frontmatter fields | [n] of 16 optional + 2 required |
| Plugin agent | [Yes (marketplace) | Yes (end-user) | No] |

### Scores

| # | Dimension | Score | Notes |
|---|-----------|-------|-------|
| 1 | Frontmatter Compliance | [0-2] | [key finding or "Clean"] |
| 2 | Tool Configuration | [0-2] | [key finding or "Clean"] |
| 3 | Description Quality | [0-2] | [key finding or "Clean"] |
| 4 | System Prompt Quality | [0-2] | [key finding or "Clean"] |
| 5 | Security & Isolation | [0-2] | [key finding or "Clean"] |

[Regression Risk section -- if applicable, insert here]
[Template Gaps section -- if applicable, insert here]

**Total: [n]/10 -- Grade: [Excellent | Good | Needs Work | Rewrite]**

### Findings

#### Errors (must fix)
[List each error with file path context, what's wrong, and how to fix]

#### Warnings (should fix)
[List each warning with explanation and fix]

#### Suggestions (consider)
[List suggestions for improvement]

#### Positive Observations
[Things the agent does well -- reinforce good practices]
```

### Grade Thresholds

| Score | Grade | Meaning |
|-------|-------|---------|
| 9-10 | Excellent | Production-ready, follows all best practices |
| 6-8 | Good | Functional with minor improvements possible |
| 3-5 | Needs Work | Significant issues that should be addressed |
| 0-2 | Rewrite | Fundamental problems -- recommend starting from the golden template |

---

## Step 5: Present Fixes as Diff

After presenting the scored report, generate a unified diff showing all
recommended fixes:

```diff
--- a/agents/agent-name.md
+++ b/agents/agent-name.md
@@ -1,5 +1,5 @@
 ---
-name: Agent_Name
+name: agent-name
 description: >
-  Reviews code for quality.
+  Reviews code for quality and best practices. Use when delegating a code
+  review to a sub-agent or when another agent needs a second opinion.
+  Does not cover system architecture reviews.
```

**Frontmatter fixes (apply automatically in diff):**
- Fix `name` format violations (lowercase, hyphens)
- Truncate `description` to <= 1024 chars if needed
- Add "Use when..." if missing (draft a contextual trigger phrase)
- Rewrite description to third person if needed
- Remove `Agent` from `tools` (subagents can't spawn subagents)
- Add `disallowedTools: Write, Edit, NotebookEdit` for read-only agents
- Remove `permissionMode`/`hooks`/`mcpServers` for plugin agents (with comment
  noting why)

**Body fixes (flag with inline comments in diff):**
- Missing Role section: `<!-- REVIEW: Consider adding ## Role section -->`
- Missing Workflow section: `<!-- REVIEW: Consider adding ## Workflow section -->`
- Missing STOP instruction for background agents:
  `<!-- REVIEW: Background agent -- add explicit STOP instruction -->`
- Memory instructions missing when memory field is set:
  `<!-- REVIEW: memory: is set -- add consult/update instructions -->`

---

## Step 6: Offer Fix Application

After presenting the diff, ask via AskUserQuestion:

> "How would you like to apply the fixes?"

Options:
1. **Apply diff directly** -- Write the corrected version to the original file
   path. Frontmatter fixes applied, body issues marked with
   `<!-- REVIEW: ... -->` inline comments.
2. **Save as a copy** -- Write a corrected copy alongside the original (e.g.,
   `agent-name.reviewed.md`). Original untouched.
3. **Skip** -- Keep the report in chat only, no file changes.

---

## Step 7: Write-to-Disk Confirmation

If the user chose option 1 or 2 in Step 6, ask for explicit second
confirmation before writing:

> "Confirm: I will write the corrected version to `<path>`. Proceed?"

**Only write after receiving explicit confirmation.** This two-step pattern
prevents accidental overwrites of agent files that may be shared across teams
via version control.

After writing, show a summary of changes applied:
- Number of frontmatter fixes
- Number of body comments added
- Final score if all fixes were applied (re-score mentally)
