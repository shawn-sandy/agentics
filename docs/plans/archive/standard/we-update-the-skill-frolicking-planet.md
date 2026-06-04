# Plan: Three-Part Skill Description Format + Optimization Logic Update

## Context

Claude Code skill descriptions currently use a **two-sentence format**: a capability sentence + a `"Use when…"` trigger phrase, targeting ≤160 chars. This works for ~50 skills installed but leaves no room for a standalone short summary that survives extreme budget pressure (100+ skills).

The new **three-part format** introduces an explicit **short description** (≤80 chars) as the first sentence, followed by the existing capability and trigger sentences (total ≤256 chars). This gives the runtime a reliable compact label even when full descriptions are truncated, and gives users a quick-scan summary.

The `optimizing-skill-frontmatter` skill must be updated to enforce and generate the new format. `plugin-patterns.md` (the authoritative authoring reference) must document the new format, and the `skill-reviewer` marketplace entry gets a minor version bump.

---

## New Description Format

```
[Short description ≤80 chars.] [Capability sentence.] Use when the user asks to [trigger].
```

**Rules:**
- **Short description**: ≤80 chars, third-person, one sentence — the single most essential function in plain language. Distilled from the skill name + Overview first paragraph.
- **Capability sentence**: what the skill does in more detail; may reference specific outputs, flags, or modes.
- **Trigger sentence**: `"Use when the user asks to [activation condition]."` — unchanged from the previous format.
- **Total**: ≤256 chars.
- **Budget property**: short description (≤80 chars) survives even at ~100 skills installed (8000 ÷ 100 = 80 chars/skill).

---

## Files to Modify

### 1. `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md` *(primary)*

**a) Frontmatter description** — update to three-part format, ≤256 total, ≤80 short:
```yaml
description: "Optimizes SKILL.md frontmatter fields. Rewrites descriptions to three-part format (≤256 chars) and tunes disable-model-invocation. Use when the user asks to optimize SKILL.md frontmatter."
```
(188 chars total; short sentence = 38 chars ✓)

**b) Overview section** — update mentions of ≤160 → ≤256 total, short ≤80; rename "two-sentence format" → "three-part format."

**c) "Why 160 chars?" section** — rename to "Why three-part format?" and update the budget math:
- Short ≤80: survives at ~100 skills (8000 ÷ 100 = 80)
- Total ≤256: fits budget for ~31 skills (8000 ÷ 256 ≈ 31)
- Still recommend ≤160 for users with ~50 skills (mention in advisory table)

**d) Step 2 — Measure current descriptions** — update the skip/rewrite rule:
- REWRITE if any of: (1) missing short description, (2) total >256 chars, (3) short description >80 chars
- SKIP if: total ≤256 AND short description ≤80 AND all three components present
- New measurement: extract and measure the short description separately (first sentence, before the second sentence)

**e) Step 3 — Rewrite rules:**
- **Rule 1**: Target ≤256 total; short description ≤80 chars (not ≤160)
- **Rule 2**: Three-part format — short description, capability sentence, trigger sentence
- **Rule 2b**: Generate missing components:
  - Missing short description → compress capability or first Overview sentence to ≤80 chars, prepend as Sentence 1
  - Missing capability (only short + trigger) → add capability as Sentence 2 from Overview
  - Missing trigger → add as final sentence from skill name + Overview
- Rules 3, 4, 5 — unchanged (synonym collapse, negative-scope relocation, filler stripping)

**f) Worked examples** — update both examples to show three-part output:
- Example A: add short description as Sentence 1 in the "After" result
- Example B: update to show three-part format with the short description at position 1

**g) Step 5 — Verify results** — update bash verification to check ≤256 AND that the first sentence is ≤80 chars:
```bash
# Measure full description
echo "${#val} $f"
# Measure first sentence only (up to first period+space)
first="${val%%.*}"
echo "${#first} chars (short desc) $f"
```

**h) Budget advisory table** — update:
```
| Installed skills | Safe avg description length |
|---|---|
| ≤31 | ~256 chars |
| ~50 | ~160 chars |
| ~100 | ~80 chars (short description only) |
```

---

### 2. `.claude/rules/plugin-patterns.md`

Update the "Skill Description Format" bullet (currently line 92) from two-sentence to three-part:

```markdown
**Skill Description Format** — Three-part format: `[Short description (≤80 chars).] [Capability statement.] Use when the user asks to [trigger].` Short description survives even at ~100 skills installed. Source both sentences from the skill body's `## Overview` section. Total budget: ≤256 chars.
```

---

### 3. `.claude-plugin/marketplace.json`

- Bump `skill-reviewer` version `2.1.0` → `2.2.0` (minor: new description format support)
- Update `description` field to reference 256-char budget instead of 160-char:
  ```json
  "description": "Review and optimize Claude Code skill files — score SKILL.md quality, plan and scaffold new skills, audit allowed-tools permissions, optimize frontmatter (descriptions + disable-model-invocation), and enforce the 256-char three-part description format"
  ```

---

### 4. `kit/plugins/skill-reviewer/CHANGELOG.md`

Add entry:
```markdown
## [2.2.0] — 2026-05-27

### Added
- Three-part description format support in `optimizing-skill-frontmatter`: short description (≤80 chars) + capability sentence + trigger phrase, total ≤256 chars.
- New Rule 2b branch: generates missing short description from the first sentence of the Overview section.
- Updated budget advisory table with ≤31 skills / ≤256 chars row.
- Short description survives ~100-skill budget pressure (8000 ÷ 100 = 80 chars).

### Changed
- Length target updated from ≤160 chars to ≤256 chars total.
- Step 2 skip rule now checks for presence of all three components and short description ≤80 chars.
- Step 5 verification now measures first sentence length separately.
```

---

## Existing Skill Descriptions

The 41 existing SKILL.md files across the repo still use the old two-sentence format. They are not all updated in this PR — the updated `optimizing-skill-frontmatter` skill is the tool for that. After this change lands, running the skill on "all" will generate the short description for every file in a single pass. The plan file notes this as a follow-up task.

---

## Verification

1. **Read the updated SKILL.md** and confirm:
   - Frontmatter description = three parts, short ≤80 chars, total ≤256 chars
   - Step 2 skip rule mentions all three components and 80-char short-description check
   - Step 3 Rule 1 says ≤256 total, Rule 2 says three-part, Rule 2b handles missing short description
   - Budget advisory table has the new ≤31/≤256 row
   - Worked examples show three-part output

2. **Read `plugin-patterns.md`** and confirm the Skill Description Format bullet describes three-part format with ≤256 and ≤80 short description.

3. **Read `marketplace.json`** and confirm `skill-reviewer` version = `2.2.0`.

4. **Lint the JSON** (auto-validated by settings hook after every Write/Edit):
   ```bash
   python3 -c "import json; json.load(open('.claude-plugin/marketplace.json'))" && echo OK
   ```

5. **Manual activation test** (optional): Load the `skill-reviewer` plugin and ask "optimize the SKILL.md for optimizing-skill-frontmatter" — the skill should activate and propose adding a short description to any file that lacks one.
