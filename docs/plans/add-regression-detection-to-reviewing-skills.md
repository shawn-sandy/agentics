# Plan: Add Regression & Breaking-Change Detection to `reviewing-skills`

## Context

The `skill-reviewer` plugin's `reviewing-skills` skill audits SKILL.md files as static snapshots — it has no awareness of what changed. When a skill is edited, the audit cannot detect breaking changes (e.g., `name:` renamed, activation triggers removed) or regressions (significant content removed). This plan adds an optional **Step 2c: Regression Risk Check** that compares the current SKILL.md against its last git-committed version and reports findings separately from the 1–10 quality score.

---

## Files to Modify

| File | Change |
|------|--------|
| `plugins/skill-reviewer/skills/reviewing-skills/SKILL.md` | Add TOC entry, Step 2c section, Quick Reference Checklist block |
| `plugins/skill-reviewer/skills/reviewing-skills/references/audit-steps.md` | Add Regression Risk comparison matrix + report template before Step 3; update Step 4 report template |
| `plugins/skill-reviewer/skills/reviewing-skills/references/best-practices.md` | Add paragraph noting regression risk is evaluated separately from scoring |
| `plugins/skill-reviewer/README.md` | Add Step 2c feature entry |
| `plugins/skill-reviewer/.claude-plugin/plugin.json` | Bump version `1.2.0` → `1.3.0` |
| `.claude-plugin/marketplace.json` | Sync `skill-reviewer` version to `1.3.0` (line 65) |
| `plugins/skill-reviewer/CHANGELOG.md` | Prepend `[1.3.0]` entry |

---

## Implementation Steps

### 1. `SKILL.md` — Three changes

**1a. Add TOC entry** (after `Step 2b` line, before `Steps 3–6` line):
```markdown
- [Step 2c: Regression Risk Check (optional)](#step-2c-regression-risk-check-optional)
```

**1b. Add Step 2c section** (insert between `## Step 2b` closing `---` and `## Steps 3–6`):

```markdown
---

## Step 2c: Regression Risk Check (optional)

Compare the current SKILL.md against its last committed version to detect breaking changes and regressions.

**Skip entirely if any of the following are true:**
- Not inside a git repository (`git rev-parse --git-dir` returns non-zero)
- File has never been committed (`git log --oneline -- <path>` returns no output)
- User says "skip regression check", "no comparison", or "first review"

**If not skipped, run in order:**

1. Resolve the git-relative path:
   ```
   git ls-files --full-name <path-to-SKILL.md>
   ```
2. Retrieve the last committed version:
   ```
   git show HEAD:<git-relative-path>
   ```
   If this fails (file renamed, untracked, or path error): skip and note "No previous version found — file may have been renamed" in report. Do NOT attempt `git log --follow`; surface the limitation and move on.

**What to compare:** See `references/audit-steps.md` — Regression Risk section.

**Output:** A **Regression Risk** section in the audit report, appended after the Scores table and before the Grade line. Does not affect any dimension score.

---
```

**1c. Append to Quick Reference Checklist** (after Discoverability block, before end of file):

```markdown
**Regression Risk** (skip if not in git, file is new, or user opts out)
- [ ] `name:` field unchanged (BREAKING if changed)
- [ ] `description:` trigger phrases preserved (BREAKING if any removed)
- [ ] `description:` activation intent preserved (WARNING if `Use when...` clause or ≥3 domain keywords absent vs. previous)
- [ ] Reference files not removed (WARNING if any `references/` path disappeared)
- [ ] Line count not reduced >30% (WARNING if significant shrinkage)
- [ ] No new anti-patterns introduced vs. previous version (INFO)
```

---

### 2. `references/audit-steps.md` — Two changes

**2a. Insert Regression Risk section before `## Step 3`** (after line 5, the `---` separator):

```markdown
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
```

**2b. Update Step 4 report template** — add Regression Risk section between Scores table and Grade line (lines 161–163 of current file):

```
| **Total** | **X/10** | |

## Regression Risk

**Regression Risk:** [None detected | Skipped — reason | See table below]

## Grade: [Excellent | Good | Needs Work | Rewrite]
```

---

### 3. Step 5 interaction — warn on BREAKING findings

In `references/audit-steps.md`, update the Step 5 offer text. If the Regression Risk section contains any BREAKING findings, prepend this note before the optimized version offer:

> "Note: BREAKING regression changes were detected (see Regression Risk section above). The optimized version below addresses quality issues — review breaking changes separately before distributing."

Do not suppress the offer; warn only.

---

### 4. Version bump

- `plugins/skill-reviewer/.claude-plugin/plugin.json` line 3: `"version": "1.3.0"`
- `.claude-plugin/marketplace.json` line 65: `"version": "1.3.0"`

---

### 5. `CHANGELOG.md` — Prepend new entry

```markdown
## [1.3.0] - 2026-03-03

### Added

- **Step 2c: Regression Risk Check** — optional git-based comparison against last committed version
- **Comparison matrix** with 6 fields classified as BREAKING | WARNING | INFO:
  - `name:` change (BREAKING)
  - Trigger phrase removal from `description:` (BREAKING)
  - <60% word overlap in `description:` rewrite (WARNING)
  - Reference file removal (WARNING)
  - >30% line reduction (WARNING)
  - New anti-patterns introduced (INFO)
- **Regression Risk section** in audit report — after Scores table, before Grade; does not affect 1–10 score
- **Quick Reference Checklist** — new Regression Risk block (6 items)
- Graceful skip: auto-skipped if not in git, file untracked, or user opts out
```

---

## Verification

Load the plugin: `claude --plugin-dir ~/devbox/agentics/plugins/skill-reviewer`

**Scenario A — git-tracked modified file (regression found):**
1. Edit `plugins/skill-reviewer/skills/reviewing-skills/SKILL.md` locally without committing (change `name:` to something else)
2. Ask Claude: "review my skill at `plugins/skill-reviewer/skills/reviewing-skills/SKILL.md`"
3. Confirm the report shows a **Regression Risk** section with `name:` listed as BREAKING

**Scenario B — untracked file (skip):**
1. Create a new temp file: `touch /tmp/test-skill/SKILL.md` with minimal frontmatter (not in any git repo)
2. Ask Claude to review it
3. Confirm the Regression Risk line reads: "Skipped — not a git repo"

**Scenario C — user opt-out:**
1. Ask Claude: "skip regression check and review `plugins/skill-reviewer/skills/reviewing-skills/SKILL.md`"
2. Confirm the Regression Risk line reads: "Skipped — user opt-out"

**Scenario D — clean file (no regressions):**
1. Ask Claude to review any committed SKILL.md with no local modifications
2. Confirm the Regression Risk line reads: "None detected"

**Version check:**
- Verify `plugins/skill-reviewer/.claude-plugin/plugin.json` reads `"version": "1.3.0"`
- Verify `.claude-plugin/marketplace.json` `skill-reviewer` entry reads `"version": "1.3.0"`

---

## Interview Summary

### Open Risks Resolved by This Plan Revision

| Risk | Resolution |
|------|-----------|
| Renamed-file handling | Skip + note "file may have been renamed"; no `--follow` complexity |
| Word overlap computation | Replaced with keyword survival check — `Use when...` clause + ≥3 domain keywords |
| Multi-line YAML `description:` | Notes added for collecting continuation lines |
| Reference detection pattern | Updated to `` `?references/[^\s`]+\.md`? `` (catches backtick-quoted paths) |
| BREAKING findings + Step 5 | Warn before optimized version offer; do not suppress |
| README.md not updated | Added to file scope |
| `best-practices.md` not updated | Added to file scope |
| Vague verification | Replaced with 4 concrete test scenarios |
