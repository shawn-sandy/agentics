---
status: in-progress
created: 2026-03-02
---

# Plan: Fix Cross-Skill Reference in test-review SKILL.md

## Context

The `test-review` skill scored 8/10 in a skill audit. It loses full marks on Dimension 3
(Structure & Progressive Disclosure) because line 103 uses a cross-skill reference path
that exits the skill root directory:

```
../code-test-suggestion/references/test-analysis-guide.md
```

Claude Code resolves reference paths relative to the skill directory. Using `..` to go
above the skill root violates the reference depth rule (`references/file.md` only). Even
though the file exists on disk, this path format is non-compliant per Anthropic's authoring
best practices and will fail in environments where Claude Code resolves references strictly.

The fix is to copy the shared reference file into the `test-review` skill's own `references/`
directory so both skills own their own copies.

## Files

- **Violating file:** `plugins/code-test-suggestion/skills/test-review/SKILL.md` (line 103)
- **Source reference:** `plugins/code-test-suggestion/skills/code-test-suggestion/references/test-analysis-guide.md`
- **Target reference:** `plugins/code-test-suggestion/skills/test-review/references/test-analysis-guide.md`

## Steps

1. Copy `skills/code-test-suggestion/references/test-analysis-guide.md` →
   `skills/test-review/references/test-analysis-guide.md`

2. Edit `test-review/SKILL.md` line 103:
   - Before: `Load '../code-test-suggestion/references/test-analysis-guide.md'`
   - After: `Load 'references/test-analysis-guide.md'`

3. Verify the fix:
   ```bash
   ls plugins/code-test-suggestion/skills/test-review/references/
   # Should show: test-analysis-guide.md  test-quality-checklist.md
   ```

4. Version bump (PATCH — no behavior change, just structure fix):
   - `plugins/code-test-suggestion/.claude-plugin/plugin.json`
   - `.claude-plugin/marketplace.json`

## Unresolved Questions

None — the fix is unambiguous.
