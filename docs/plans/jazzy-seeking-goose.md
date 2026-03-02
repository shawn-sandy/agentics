# Plan: Fix Cross-Skill Reference in test-review SKILL.md

## Context

The `test-review` skill scored 8/10 in a skill audit. It loses full marks on Dimension 3
(Structure & Progressive Disclosure) due to a cross-skill reference on line 103:

```
Load `../code-test-suggestion/references/test-analysis-guide.md` for detailed heuristics
```

Claude Code has no native mechanism for sharing references across skills in a skill pack.
The spec requires all references to be at depth ≤1 within the skill root (`references/file.md`).
Using `..` to escape the skill directory is non-compliant.

## Why "remove the reference" is the right fix

The `test-analysis-guide.md` file is annotated: "Loaded by the code-test-suggestion skill
during Step 3." It is oriented toward suggesting tests — fragility heuristics, language-specific
testing patterns, what to mock.

`test-review` Step 4 already has its own comprehensive analysis instructions (4a–4e):
behavioral summary, critical paths, integration points, implicit contracts, fragility areas.
These cover the same analytical ground independently. The guide adds incremental heuristic
depth that `test-review` does not require to function correctly — it reviews tests, it doesn't
suggest them.

## Files

- **To edit:** `plugins/code-test-suggestion/skills/test-review/SKILL.md` (line 103)
- **Shared file (not to modify):** `plugins/code-test-suggestion/skills/code-test-suggestion/references/test-analysis-guide.md`

## Steps

1. Edit `test-review/SKILL.md` line 103:

   Before:
   ```
   Read the source code and identify the following. Load `../code-test-suggestion/references/test-analysis-guide.md` for detailed heuristics on each category.
   ```

   After:
   ```
   Read the source code and identify the following.
   ```

2. The rest of Step 4 (4a–4e) remains unchanged — it already contains all needed heuristics.

3. Version bump (PATCH — no behavior change, just removes non-working cross-skill reference):
   - `plugins/code-test-suggestion/.claude-plugin/plugin.json`
   - `.claude-plugin/marketplace.json`

## Alternatives considered

| Option | Why rejected |
|--------|-------------|
| Duplicate file into `test-review/references/` | Two copies that must be kept in sync; unnecessary since test-review's Step 4 body is self-sufficient |
| Inline guide content into Step 4 body | Increases body word count without adding value for a review (vs. suggestion) workflow |
| Keep the `../` path | Non-compliant with authoring spec |

## Verification

After the edit, confirm:
- Line 103 no longer references any external path
- Step 4 body (4a–4e) reads coherently without the guide load instruction
- Run the skill on a test file and confirm Step 4 analysis still executes correctly
