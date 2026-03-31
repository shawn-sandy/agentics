---
status: ready
---

# Fix: Remove `$PWD` anti-pattern from code-testing-agent SKILL.md

## Context

Audit of `plugins/code-testing-agent/skills/code-testing-agent/SKILL.md` scored **9/10 (Excellent)**. One error found: `$PWD` is used on line 50, but `$PWD` is a command-only template variable that is never substituted in skills.

## Fix

**File:** `plugins/code-testing-agent/skills/code-testing-agent/SKILL.md`
**Line:** 50

### Current text (line 50)

```
   If a file path is found, resolve it relative to `$PWD` and confirm it exists. **If it does not exist, stop and report the error to the user — do not fall through to lower-priority sources.**
```

### Replacement text

```
   If a file path is found, resolve it relative to the current working directory and confirm it exists. **If it does not exist, stop and report the error to the user — do not fall through to lower-priority sources.**
```

## Verification

1. Read the updated file and confirm `$PWD` no longer appears
2. Confirm no other `$ARGUMENTS` or `$PWD` references exist in the file
3. Re-score Dimension 4 (Anti-pattern Detection) — should move from 1/2 to 2/2, bringing total to **10/10**

## Next Steps

- Consider adding a cross-reference to the sibling `reviewing-tests` skill in the scope section
- Consider updating Step 1 level 5 git command to `git diff --name-only main...HEAD` for better feature-branch coverage
