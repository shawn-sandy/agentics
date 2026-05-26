# Audit Steps (Steps 3–6)

This reference file is loaded by `reviewing-skills` to complete the audit workflow.

---

## Regression Risk Check (Step 2c Detail)

### Comparison Matrix

| Field / Metric | How to Extract (Previous Version) | Risk Level | Condition |
|----------------|-----------------------------------|------------|-----------|
| `name:` | Parse YAML frontmatter from `git show` output | **BREAKING** | Any change |
| Trigger phrases in `description:` | Extract all "Use when..." clauses | **BREAKING** | Any clause present in previous but absent in current |
| `description:` activation intent | Check whether `"Use when..."` clause and ≥3 domain keywords from previous description appear in current | **WARNING** | `Use when...` clause missing or <3 original keywords survive |
| Reference files in body | Grep for `` `?references/[^\s`]+\.md`? `` in previous body (matches bare and backtick-quoted paths) | **WARNING** | Any path absent in current |
| Total line count | Count lines in `git show` output | **WARNING** | Current <70% of previous |
| New anti-patterns | Apply Dimension 4 checks to previous version | **INFO** | New error/warning anti-pattern in current that was absent before |

**Notes:**
- Parse frontmatter by reading lines between first and second `---` delimiters in `git show` output. If `description:` spans multiple lines (folded YAML), collect all continuation lines until the next top-level key.
- Activation intent check: extract the `"Use when..."` clause and domain-specific keywords from the previous description; verify each survives in the current description.
- Reference detection: use pattern `` `?references/[^\s`]+\.md`? `` to match both bare paths (`references/audit-steps.md`) and backtick-quoted paths (`` `references/audit-steps.md` ``).
- If `git show` returns non-zero exit (renamed file, shallow clone path error): skip all comparisons and note "No previous version found — file may have been renamed" in report.

### Skip Conditions

Omit the Regression Risk section from the report entirely if:
- `git rev-parse --git-dir` exits non-zero
- `git log --oneline -1 -- <path>` returns empty output
- User opted out

### Report Template

Append after the Scores table and before Grade. Three variants:

**Skipped:**
```
**Regression Risk:** Skipped — [not a git repo | file not yet committed | user opt-out | no previous version found]
```

**Clean:**
```
**Regression Risk:** None detected — no breaking changes or regressions vs. last commit.
```

**Findings:**
```
## Regression Risk

**Previous version:** git HEAD (`git show HEAD:<path>`)

| Risk | Field / Metric | Previous | Current | Impact |
|------|----------------|----------|---------|--------|
| BREAKING | `name:` | `old-name` | `new-name` | Invocation references break |
| BREAKING | Trigger phrase removed | "Use when the user asks to audit..." | (absent) | Skill stops auto-activating |
| WARNING | Activation intent | `Use when...` clause absent in current | — | Activation behavior may shift |
| WARNING | Reference file removed | `references/audit-steps.md` | (absent) | Progressive disclosure broken |
| WARNING | Line reduction | 220 lines | 130 lines (41%) | Content may have been lost |
| INFO | New anti-pattern | — | Windows path in body | Regression from previously clean |

**Summary:** BREAKING: N | Warnings: N | Info: N
> Regression Risk findings are informational and do not affect the 1–10 quality score.
```

---

## Step 3: Score 5 Dimensions

Score each dimension 0–2. Maximum total: **10 points**.

Apply the criteria from `references/best-practices.md` when evaluating each dimension.

---

### Dimension 1: Frontmatter Validity (0–2 pts)

**Checks:**

| Check | Requirement | Error / Warning |
|-------|-------------|-----------------|
| `name` present | Field must exist | Error if missing |
| `name` length | ≤64 characters | Error if exceeded |
| `name` format | Lowercase letters, numbers, hyphens only — no spaces, uppercase, or underscores | Error if violated |
| `name` reserved words | Must not contain `anthropic` or `claude` as substring (e.g., `claude-helper` fails) | Error if matched |
| `description` present | Field must exist | Error if missing |
| `description` length | ≤1024 characters | Error if exceeded |
| `description` person | Must be third person (no "I", "you", "we", "your") | Error if violated |
| `description` trigger | Must contain "Use when..." phrase | Warning if absent |
| `description` capability | Should contain a capability statement describing what the skill does/produces — not only "Use when…" | Warning if absent |

**Scoring:**
- **2 pts** — No errors; description has "Use when…" trigger AND a capability statement; third person
- **1 pt** — Minor issues: trigger present but capability absent, or description slightly long
- **0 pts** — Missing required fields, reserved word in name, first/second person

---

### Dimension 2: Body Quality (0–2 pts)

**Checks:**

| Check | Requirement | Severity |
|-------|-------------|----------|
| Line count | <500 lines total (per official Anthropic docs) | Error if ≥500 |
| Word count | <5,000 words total (per Anthropic guide) | Warning if 3,000–4,999; Error if ≥5,000 |
| Terminology | Consistent terms used throughout | Warning if inconsistent |
| Concrete examples | At least one concrete example or code block where relevant | Suggestion if absent |
| No time-sensitive platform-state content | No phrases like "as of 2024", "currently", "recently added", "new in version X" | Warning |
| No first/second person in body instructions | Prefer imperative ("Read the file") over "You should read" | Suggestion |

Word count takes precedence when line count and word count thresholds disagree. Count words in the body only (after closing `---`).

**Scoring:**
- **2 pts** — <500 lines AND <3,000 words, consistent, has examples, no time-sensitive content
- **1 pt** — 3,000–4,999 words, or missing examples, or minor inconsistency
- **0 pts** — ≥500 lines or ≥5,000 words, or time-sensitive content, or major inconsistency

---

### Dimension 3: Structure & Progressive Disclosure (0–2 pts)

**Checks:**

| Check | Requirement | Severity |
|-------|-------------|----------|
| Reference depth | Reference files must be at depth ≤1 (`references/file.md` — no subdirectories) | Error if violated |
| TOC presence | Reference files (`references/*.md`) ≥100 lines must have a TOC; absent TOC in SKILL.md itself is a Suggestion only | Warning if absent in reference files; Suggestion if absent in SKILL.md |
| Freedom level | Skill indicates how strictly to follow it (rigid vs. flexible) | Suggestion if absent |
| Heading hierarchy | Headings use H2/H3 logically; no skipped levels | Warning if violated |
| Folder naming | Skill folder uses kebab-case | Warning if violated |
| SKILL.md casing | File is named exactly `SKILL.md` (case-sensitive) | Error if wrong casing |
| Three-level architecture | Content distributed across frontmatter (L1), body (L2), and linked files (L3) where appropriate | Suggestion if all content crammed into body |
| Feedback loop | Quality-critical or iterative tasks define a validator → fix → repeat cycle with a stop condition | Suggestion if absent in iterative/quality-critical skills |

**Three-level progressive disclosure assessment:**
- Level 1 (frontmatter): Is the description sufficient for activation decisions?
- Level 2 (body): Is the body focused on core instructions without excessive detail?
- Level 3 (references/scripts): Is detailed content properly offloaded?

A skill with >3,000 words in the body and no reference files should consider splitting.

**Scoring:**
- **2 pts** — Reference depth valid, TOC present (if needed), freedom level clear, folder naming correct, content well-distributed across levels
- **1 pt** — Missing TOC on long reference file (≥100 lines), or freedom level unstated, or all content in body with no references
- **0 pts** — Reference depth violation, wrong SKILL.md casing, or no structure

---

### Dimension 4: Anti-pattern Detection (0–2 pts)

Check for the presence of known anti-patterns:

| Anti-pattern | Example | Severity |
|--------------|---------|----------|
| Windows-style paths | `references\file.md` or `C:\Users\...` | Error |
| Options without a default | "Use A, B, or C" with no recommended default | Warning |
| Time-sensitive content in main body | "As of February 2025, Claude supports..." | Warning |
| First/second person in `description` frontmatter | "I will review...", "You should use this when..." | Error |
| `$ARGUMENTS` or `$PWD` in skill body | These variables only work in commands | Error |
| XML tags in `description` | `<example>`, `<user>`, etc. | Error |
| Wrong SKILL.md casing | File named `skill.md` or `Skill.md` instead of `SKILL.md` | Error |
| Hardcoded absolute paths | `/Users/me/project/` or `C:\Users\` in body | Error |
| Exceeds 5,000 words without references | Body too long with no content offloaded | Warning |
| Non-kebab-case folder name | `mySkill/` or `My_Skill/` instead of `my-skill/` | Warning |
| Assumes tools/packages installed | Calls `npm`, `pip`, or external tools without listing install instructions | Warning |
| MCP tool without `ServerName:` prefix | `create_issue` instead of `GitHub:create_issue` | Warning |
| Voodoo constants | Magic numbers (`timeout=30`) with no inline comment | Suggestion |
| Script punts to Claude on error | Script fails silently; no error handling | Warning |
| Verbose over-explanation | Explains things Claude already knows (what JSON is, how git works) | Suggestion |

**Script detection rule:** Apply the five script-related checks (last five rows) if the skill contains a `scripts/` folder reference OR has bash/python code blocks with external tool invocations (`curl`, `npm`, `pip`, `brew`, MCP calls).

**Scoring:**
- **2 pts** — No anti-patterns detected
- **1 pt** — 1–2 warnings (no errors)
- **0 pts** — Any error-level anti-pattern present

---

### Dimension 5: Discoverability (0–2 pts)

**Checks:**

| Check | Requirement | Severity |
|-------|-------------|----------|
| "Use when..." present | Must appear in `description` | Warning if absent |
| Trigger clarity | Trigger phrases are specific, not vague ("Use when user asks anything") | Warning if vague |
| Keyword density | ≥3 searchable keywords in description | Suggestion if <3 |
| Scope defined | Description clarifies what this skill does NOT handle | Suggestion if absent |
| Activation collision risk | Description is distinct enough from similar skills | Warning if ambiguous |

**Scoring:**
- **2 pts** — Clear trigger, ≥3 keywords, scope defined, no collision risk
- **1 pt** — Trigger present but vague, or <3 keywords, or scope unclear
- **0 pts** — No "Use when..." phrase, or high collision risk

---

## Step 4: Output Scored Report

Present the audit results in this format:

```
# Skill Audit Report

**File:** `path/to/SKILL.md`
**Guidelines Source:** [Static: references/best-practices.md | Live fetch: platform.claude.com | Fallback: live fetch failed, used static]
**Total Lines:** N
**Word Count:** N
**Folder Structure:** [Minimum (SKILL.md only) | Standard (SKILL.md + references/) | Full (SKILL.md + references/ + scripts/) | Pack (multi-skill)]
**Design Pattern:** [Sequential | Orchestrator | Iterative | Adaptive | Mixed | None detected]

## Scores

| Dimension | Score | Notes |
|-----------|-------|-------|
| 1. Frontmatter Validity | X/2 | [key findings] |
| 2. Body Quality | X/2 | [key findings] |
| 3. Structure & Progressive Disclosure | X/2 | [key findings] |
| 4. Anti-pattern Detection | X/2 | [key findings] |
| 5. Discoverability | X/2 | [key findings] |
| **Total** | **X/10** | |

## Regression Risk

**Regression Risk:** [None detected | Skipped — reason | See table below]

## Grade: [Excellent | Good | Needs Work | Rewrite]

## Issues Found

### Errors (must fix)
- [List each error with location]

### Warnings (should fix)
- [List each warning with location]

### Suggestions (consider)
- [List suggestions]
```

**Grade thresholds:**

| Score | Grade |
|-------|-------|
| 9–10 | Excellent |
| 6–8 | Good |
| 3–5 | Needs Work |
| 0–2 | Rewrite |

---

## Step 5: Offer Optimized Version

After presenting the report, offer to generate a corrected version.

**If the Regression Risk section contains any BREAKING findings**, prepend this note before the offer:

> "Note: BREAKING regression changes were detected (see Regression Risk section above). The optimized version below addresses quality issues — review breaking changes separately before distributing."

> "Would you like me to generate an optimized version of this skill file?"

**If the user says yes:**

Generate the corrected file applying these rules:

**Frontmatter fixes (apply automatically):**
- Fix `name` format violations (lowercase, hyphens)
- Truncate `description` to ≤1024 chars (note if truncated)
- Add "Use when..." if missing (draft a phrase based on existing content)
- Rewrite description to third person if first/second person detected
- Remove XML tags from description

**Body fixes (flag with inline comments, do not rewrite):**
- Mark time-sensitive content: `<!-- SUGGESTION: Remove time-sensitive reference -->`
- Mark Windows paths: `<!-- SUGGESTION: Use forward slashes: references/file.md -->`
- Mark `$ARGUMENTS`/`$PWD` usage: `<!-- SUGGESTION: These variables are command-only; use conversation context in skills -->`
- Mark options without defaults: `<!-- SUGGESTION: Add a recommended default option -->`

**Do not change:**
- Author's body prose, structure, or examples (beyond inline comment flags)
- Reference file names or paths (unless they violate depth rule)
- Heading hierarchy (unless it causes a structural error)

Present the corrected frontmatter and annotated body as a code block.

---

## Step 6: Write to Disk (Requires Explicit Confirmation)

After presenting the optimized version:

> "Should I write this to disk and overwrite `path/to/SKILL.md`? This will replace the current file. Please confirm with 'yes, write it' to proceed."

**Requirements to proceed:**
1. User must explicitly confirm (e.g., "yes, write it", "go ahead", "overwrite it")
2. Path must be the same file that was audited (no silent path changes)

**If confirmed:** Write the corrected content to the file using the Write tool.

**If not confirmed or unclear:** Do not write. Respond: "No changes written. The corrected version is above if you'd like to copy it manually."

**Warning to include in confirmation prompt:**
> "Note: This overwrites the existing file. Ensure you have a backup or the file is tracked in version control."
