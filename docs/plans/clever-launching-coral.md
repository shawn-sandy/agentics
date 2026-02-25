# Fix claude-md-optimizer Plugin: SKILL.md Violations

## Context

A skill-reviewer audit of the `claude-md-optimizer` plugin found 3 errors and 1 warning across both SKILL.md files. The issues are:

1. **Reserved name substring** — `claude-md-optimizer` skill name contains `claude`, which Anthropic prohibits in skill names
2. **Command-only variables in skill bodies** — `$ARGUMENTS` and `$PWD` only expand in commands, not skills; using them in SKILL.md causes Claude to treat them as literal strings
3. **Missing table of contents** — both files exceed 100 lines and require a TOC

These are correctness bugs that affect skill activation and instruction clarity.

---

## Files to Modify

- `plugins/claude-md-optimizer/skills/claude-md-optimizer/SKILL.md`
- `plugins/claude-md-optimizer/skills/path-rules-advisor/SKILL.md`
- `plugins/claude-md-optimizer/.claude-plugin/plugin.json` (version bump)
- `.claude-plugin/marketplace.json` (version sync)
- `plugins/claude-md-optimizer/CHANGELOG.md` (create if absent)

---

## Steps

### 1. Fix `name` in `claude-md-optimizer/SKILL.md`

Change:
```yaml
name: claude-md-optimizer
```
To:
```yaml
name: md-optimizer
```

> Note: This is a breaking change for users who reference the skill by name (`claude-md-optimizer:claude-md-optimizer`). After the fix the reference becomes `claude-md-optimizer:md-optimizer`. Warrants a **minor** version bump.

### 2. Replace `$ARGUMENTS` and `$PWD` in `claude-md-optimizer/SKILL.md`

Lines 13–19 — replace variable references with prose:

**Before:**
```
1. Explicit path in `$ARGUMENTS` (if provided)
2. `$PWD/CLAUDE.md` (primary project location)
3. `$PWD/.claude/CLAUDE.md` (alternate project location, checked if primary absent)
4. `~/.claude/CLAUDE.md` (global user-level)
```

**After:**
```
1. Explicit path provided in the user's message (if present)
2. `CLAUDE.md` in the current working directory (primary project location)
3. `.claude/CLAUDE.md` in the current working directory (alternate, checked if primary absent)
4. `~/.claude/CLAUDE.md` (global user-level)
```

### 3. Add TOC to `claude-md-optimizer/SKILL.md`

Insert after the opening instruction line (after line 6), before the first `---`:

```markdown
## Table of Contents

- [Step 1 — Resolve the target file](#step-1--resolve-the-target-file)
- [Step 2 — Read and measure](#step-2--read-and-measure)
- [Step 3 — Run the 6-dimension audit](#step-3--run-the-6-dimension-audit)
- [Step 4 — Present the scored report](#step-4--present-the-scored-report)
- [Step 5 — Offer an optimized version](#step-5--offer-an-optimized-version)
- [Step 6 — Offer to write the optimized file](#step-6--offer-to-write-the-optimized-file)
- [Example audit output](#example-audit-output)
- [Notes](#notes)
```

### 4. Replace `$ARGUMENTS` and `$PWD` in `path-rules-advisor/SKILL.md`

- Line 12: `Use this mode when $ARGUMENTS is non-empty.` → `Use this mode when the user provides an argument in their message.`
- Lines 100–103 (Mode B, Step 1): Replace `$PWD/CLAUDE.md` → `CLAUDE.md in the current working directory`, `$PWD/.claude/CLAUDE.md` → `.claude/CLAUDE.md in the current working directory`

### 5. Add TOC to `path-rules-advisor/SKILL.md`

Insert after the opening instruction line (after line 6), before the first `---`:

```markdown
## Table of Contents

- [Mode A — Argument provided](#mode-a--argument-provided)
- [Mode B — No argument (analysis mode)](#mode-b--no-argument-analysis-mode)
- [Rule file format](#rule-file-format)
- [Notes](#notes)
```

### 6. Version bump

- `plugin.json`: `1.3.0` → `1.4.0` (minor bump — skill name change is user-visible)
- `marketplace.json`: sync to `1.4.0`
- `CHANGELOG.md`: add entry documenting the fixes

---

## Verification

```bash
# Confirm no $ARGUMENTS or $PWD remain in SKILL.md files
grep -r '\$ARGUMENTS\|\$PWD' plugins/claude-md-optimizer/skills/

# Confirm name field no longer contains 'claude'
grep '^name:' plugins/claude-md-optimizer/skills/claude-md-optimizer/SKILL.md

# Confirm version sync
grep -r '"version"' plugins/claude-md-optimizer/.claude-plugin/ .claude-plugin/marketplace.json
```

---

## Unresolved Questions

- Should `path-rules-advisor/SKILL.md` `name:` field also be reviewed for correctness? (Currently `path-rules-advisor` — no reserved words, passes.)
- Is the skill name change from `claude-md-optimizer` to `md-optimizer` acceptable? Any existing user references will break.
