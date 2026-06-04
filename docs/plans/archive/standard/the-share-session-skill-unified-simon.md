# Plan: Add resume prompt after security scrub in share-session skill

## Context

The `share-session` skill invokes the `security-scrub` skill in Phase 2. When the scrub result is `PASS`, the skill currently says "continue silently" — meaning the user gets no chance to confirm before the workflow proceeds to card generation (Phase 3). The user wants a prompt so they can decide whether to continue after the scrub completes.

The `WARN` case already asks for confirmation, and `BLOCKED` stops entirely — only the `PASS` case is missing a user checkpoint.

## Change

**File:** `kit/plugins/social-media-tools/skills/share-session/SKILL.md` (line 188)

Replace the `PASS` bullet in the Phase 2 result handling:

```
- `PASS` → continue silently.
```

With:

```
- `PASS` → use `AskUserQuestion` to ask: "Security scrub passed — proceed with generating the recap card?" Continue only if the user confirms.
```

No other files need to change. `AskUserQuestion` is already in the skill's `allowed-tools` frontmatter.

## Verification

1. Read the modified SKILL.md and confirm the three result cases (`BLOCKED`, `WARN`, `PASS`) all have appropriate user-facing behavior
2. Confirm `AskUserQuestion` is in `allowed-tools` (it is — line 4)
3. Run `/validate-plugin social-media-tools` to check plugin structure
