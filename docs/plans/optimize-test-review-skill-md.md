# Plan: Optimize test-review SKILL.md

## Context

Audit of `plugins/code-test-suggestion/skills/test-review/SKILL.md` scored 10/10 (Excellent). No errors or warnings were found. Three suggestion-level issues were identified. Per the skill-reviewer workflow, the optimized version applies inline comment annotations to body suggestions and leaves all prose, structure, and references unchanged.

## Changes

### 1. Add fallback instruction in Step 6 (suggestion)

**Location:** `plugins/code-test-suggestion/skills/test-review/SKILL.md`, line 184

**Current:**
```
Load `references/test-quality-checklist.md` for detailed heuristics on each review dimension.
```

**Change:** Add a fallback sentence immediately after so the skill degrades gracefully if the reference file is unavailable:
```
Load `references/test-quality-checklist.md` for detailed heuristics on each review dimension. If the file is unavailable, apply the nine review dimensions using the criteria defined in the Review Dimensions list below.
```

### 2. Fix nested code fence in Step 6 output template (suggestion)

**Location:** Lines 228-230 — the ` ```[language] ` fence inside the ` ```markdown ` block

**Change:** Replace the outer code fence delimiter with `~~~` to avoid rendering artifacts:
- Opening ` ```markdown ` → `~~~markdown`
- Closing ` ``` ` (for the outer block) → `~~~`

### 3. Name style (no change)

`test-review` (noun-noun) is acceptable per best practices. Changing to `reviewing-tests` (gerund) would require updates to `plugin.json`, `marketplace.json`, and any documentation. Leaving as-is.

## Files to Modify

- `plugins/code-test-suggestion/skills/test-review/SKILL.md`

## Verification

1. Read the updated SKILL.md to confirm both changes applied correctly
2. Confirm the outer `~~~markdown` fence renders the inner ` ```[language] ` correctly
3. Confirm the fallback sentence is coherent with the surrounding Step 6 instructions
