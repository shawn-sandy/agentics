# Audit Steps (Steps 3–6)

This reference file is loaded by `reviewing-skills` to complete the audit workflow.

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

**Scoring:**
- **2 pts** — No errors; description has "Use when..." and is third person
- **1 pt** — Minor issues (missing trigger phrase, description slightly long)
- **0 pts** — Missing required fields, reserved word in name, first/second person

---

### Dimension 2: Body Quality (0–2 pts)

**Checks:**

| Check | Requirement | Severity |
|-------|-------------|----------|
| Line count | <500 lines total | Warning if 400–499; Error if ≥500 |
| Terminology | Consistent terms used throughout | Warning if inconsistent |
| Concrete examples | At least one concrete example or code block where relevant | Suggestion if absent |
| No time-sensitive platform-state content | No phrases like "as of 2024", "currently", "recently added", "new in version X" | Warning |
| No first/second person in body instructions | Prefer imperative ("Read the file") over "You should read" | Suggestion |

**Scoring:**
- **2 pts** — <400 lines, consistent, has examples, no time-sensitive content
- **1 pt** — 400–499 lines, or missing examples, or minor inconsistency
- **0 pts** — ≥500 lines, or time-sensitive content, or major inconsistency

---

### Dimension 3: Structure & Progressive Disclosure (0–2 pts)

**Checks:**

| Check | Requirement | Severity |
|-------|-------------|----------|
| Reference depth | Reference files must be at depth ≤1 (`references/file.md` — no subdirectories) | Error if violated |
| TOC presence | Files ≥100 lines must have a table of contents | Warning if absent |
| Freedom level | Skill indicates how strictly to follow it (rigid vs. flexible) | Suggestion if absent |
| Heading hierarchy | Headings use H2/H3 logically; no skipped levels | Warning if violated |

**Scoring:**
- **2 pts** — Reference depth valid, TOC present (if needed), freedom level clear
- **1 pt** — Missing TOC on long file, or freedom level unstated
- **0 pts** — Reference depth violation, or no structure

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
**Guidelines Source:** [Static: references/best-practices.md | Live fetch: code.claude.com | Fallback: live fetch failed, used static]
**Total Lines:** N

## Scores

| Dimension | Score | Notes |
|-----------|-------|-------|
| 1. Frontmatter Validity | X/2 | [key findings] |
| 2. Body Quality | X/2 | [key findings] |
| 3. Structure & Progressive Disclosure | X/2 | [key findings] |
| 4. Anti-pattern Detection | X/2 | [key findings] |
| 5. Discoverability | X/2 | [key findings] |
| **Total** | **X/10** | |

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

After presenting the report, offer to generate a corrected version:

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
