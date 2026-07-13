---
status: todo
---

# Optimize running-tests SKILL.md

## Context

The `running-tests` skill was moved from `skill-reviewer` to `code-testing-agent`. Its SKILL.md (149 lines, 74-word description) inlines detail that already exists in `references/test-runner-guide.md`, creating duplication and context bloat. The sibling `code-testing-agent` skill already uses the slim "Load references/..." progressive disclosure pattern — this plan aligns `running-tests` to the same pattern.

**Prior art:** The `code-testing-agent` refactor (commit `d04e49e`) achieved a 69% reduction (318->98 lines) by extracting 3 chunks to reference files. The `running-tests` skill already has its heaviest tabular data in references, so the reduction will be more modest.

**Goal:** ~30-40% line reduction (149 -> ~90-105 lines) while preserving all behavioral instructions.
If post-edit line count drops below 90, audit each step to confirm no behavioral instruction was lost.

## Repo-wide SKILL.md Context

- **10/21 skills use the slim pattern** — body as orchestrator + reference pointers. This is the majority convention.
- **Median description:** 57 words; running-tests is at 74 words (above average).
- **Canonical reference pointer syntax:** `Load \`references/file.md\` Section N for [brief purpose].` (6 current pointers use inconsistent phrasings).
- **Freedom level:** Only 4/21 skills declare it explicitly via blockquote. Running-tests uses prose; should use the blockquote form.

## Files to Modify

**Commit 1 — optimize running-tests:**

- `plugins/code-testing-agent/skills/running-tests/SKILL.md`

**Commit 2 — fix sibling bug:**

- `plugins/code-testing-agent/skills/code-testing-agent/SKILL.md` — fix duplicated frontmatter (lines 12-18 are outside YAML delimiters)

The reference file `references/test-runner-guide.md` does **not** need changes — all inline content being removed is already covered in Sections 1-5.

## Pre-Removal Verification (do this before Step 4)

Before removing any inline content from Steps 4-8, confirm the reference file covers the same cases. Specifically:

- Step 3 removes 5 config file signals → confirm all 5 are in Section 2 of the reference
- Step 5 removes example table rows → confirm Section 1 covers naming conventions with examples
- Step 8 removes results parsing → confirm Section 3 covers all frameworks' pass/fail signals
- Step 8 removes advisory templates → confirm Section 4 has per-language templates

## Steps

### 1. Tighten the frontmatter description

Replace the 74-word single-line description. Changes:
- Remove procedural blow-by-blow from the intro
- Replace with tighter trigger phrases (broader: "run tests" instead of "run tests for my changes")
- Restore both negative boundaries (quality AND suggestions)
- Use multi-line YAML block scalar

```yaml
description:
  Detects the test framework, runs scoped tests, and reports pass/fail results
  with missing-test advisories. Use when the user asks to "run tests",
  "check if tests pass", "test this file", "verify my changes", or "are there
  missing tests". Does not review test quality — use reviewing-tests for that.
  Does not suggest tests — use code-testing-agent for that.
```

### 2. Replace Overview with summary + freedom level

Remove the 5-line Overview section (redundant with description). Replace with:

```markdown
Detect the test framework per changed file, run scoped test commands via Bash,
and report pass/fail/error counts. Advise on missing test files.

> **Freedom level: Adaptive** — Follow these steps exactly.
```

### 3. Compress Step 0 (Create Progress Todos)

Compress from 9 lines to 2 lines:

```markdown
Use `TodoWrite` to create todos for Steps 1-5 (all `status: "pending"`).
Mark each `status: "completed"` as you finish.
```

### 4. Slim Step 1 (Identify Changed Files)

- **Keep:** 4-item priority list + empty-state short-circuit directive + filter list (4 bullets — too small to extract)
- **Remove:** Example short-circuit message block (6 lines of prose around a 2-line example)
- **Standardize:** Reference pointer syntax if any exists in this step

### 5. Slim Step 2 (Find Related Test Files)

- **Keep:** Instruction to produce resolved pairs table with column spec + header + **1 example row** (shows "Found"/"Not found" format)
- **Keep:** "Prefer closest test file" rule and "Not found -> Step 5" carry-forward
- **Remove:** The other 2 example rows
- **Add/Standardize:** `Load \`references/test-runner-guide.md\` Section 1 for naming conventions and search directories.`

### 6. Slim Step 3 (Detect Test Framework)

- **Pre-check:** Confirm Section 2 of the reference covers all 5 config file signals before removing inline list
- **Remove:** 5-item inline config file priority list, monorepo tie-breaking explanation
- **Keep:** AskUserQuestion fallback instruction
- **Add/Standardize:**
  - `Load \`references/test-runner-guide.md\` Section 2 for detection signals and run commands.`
  - `See Section 5 for the monorepo nearest-ancestor tie-breaking rule.`

### 7. Slim Step 4 (Run Tests)

- **Remove:** Jest example command block (4 lines) — Section 2 has `npx jest <test-file>`
- **Keep:** Bash execution directive, scope-to-resolved-files rule, failure handling (capture exit code, surface stderr, no retry), skip "Not found" rule
- **Add/Standardize:** `Load \`references/test-runner-guide.md\` Section 2 for command templates.`

### 8. Slim Step 5 (Report Results + Missing Tests)

- **Pre-check:** Confirm Section 3 covers all 7 framework pass/fail signals; Section 4 has per-language templates
- **Remove:** 4-line example results table rows, 6-line advisory example block, parsing paraphrase
- **Keep:** Output format spec (`Test File | Result | Pass | Fail | Error`), scope boundary ("file-level only, direct to reviewing-tests")
- **Add/Standardize:**
  - `Load \`references/test-runner-guide.md\` Section 3 for result parsing patterns.`
  - `Load \`references/test-runner-guide.md\` Section 4 for per-language advisory templates.`

### 9. Fix sibling SKILL.md duplicated frontmatter (separate commit)

In `plugins/code-testing-agent/skills/code-testing-agent/SKILL.md`, delete lines 12-18: the duplicated `name:` and `description:` text that appears outside the YAML front-matter delimiters.

## Verification

1. **Line count:** Read the final SKILL.md. Target: 90-105 lines. If below 90, audit each step for lost behavioral instructions before committing.
2. **Reference coverage:** Grep for `Section [1-5]` in the SKILL.md — confirm each pointer maps to an actual `## Section N:` heading in the reference file.
3. **Behavioral checklist:** For each removed inline block, confirm its content exists in the referenced section:
   - 5 config file signals → Section 2 ✓ (pre-verified above)
   - Advisory templates → Section 4 ✓ (pre-verified above)
   - Result parsing → Section 3 ✓ (pre-verified above)
4. **Cross-reference:** `grep "reviewing-tests" SKILL.md` — confirm the string appears in both the description and Step 5.
5. **Sibling fix:** Read `code-testing-agent/SKILL.md` — confirm no duplicate `name:` / `description:` outside YAML delimiters.
6. **Activation smoke test:** In a test session with the plugin loaded:
   - "run tests for my changes" → should activate `running-tests`
   - "suggest tests for this file" → should activate `code-testing-agent`, NOT `running-tests`

## Next Steps

- Optimize `reviewing-tests` SKILL.md (301 lines, verbose pattern) — separate plan
- Audit `react-perf-analyzer` (345 lines), `code-review-agent` (399 lines), `plan-interview` (434 lines) for reference extraction candidates
