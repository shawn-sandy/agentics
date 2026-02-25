# Review: claude-md-optimizer Plugin (v1.3.0)

## Context

The `claude-md-optimizer` plugin is a skills-only plugin that audits and optimizes CLAUDE.md files against Claude Code best practices. It contains two skills (`claude-md-optimizer` and `path-rules-advisor`) and is registered in the agentics-kit marketplace at v1.3.0. This review evaluates the plugin's quality, accuracy, completeness, and identifies actionable improvements.

All factual claims were verified against the official Claude Code documentation at `code.claude.com/docs/en/memory`, `code.claude.com/docs/en/skills`, and `code.claude.com/docs/en/plugins-reference`.

---

## Findings

### Critical Issues

**C1. Instruction budget numbers have no official basis**
- **File:** `plugins/claude-md-optimizer/skills/claude-md-optimizer/SKILL.md:45-51`
- The skill claims: *"Claude Code allocates roughly 150–200 slots of its context for system-level instructions. Claude itself consumes ~50. This leaves ~100–150 for project instructions."*
- The official docs make no mention of "instruction slots," "instruction budgets," or numeric limits on CLAUDE.md instructions. The docs mention a 200-line cap for auto-memory's `MEMORY.md` — a different concept entirely. CLAUDE.md files are loaded in full without instruction-count limits.
- The D1 scoring thresholds (50–150 = 2, 150–200 = 1, >200 = 0) are based on these unverifiable numbers and may cause users to prematurely remove useful instructions.
- **Fix:** Reframe D1 around general context management. Replace the slot numbers with softer guidance: "Shorter CLAUDE.md files perform better. Files under ~150 instructions generally stay focused. Files over ~200 instructions risk diluting important directives." Remove the claim about Claude consuming ~50 slots.

**C2. Memory load order is incorrect**
- **File:** `plugins/claude-md-optimizer/skills/claude-md-optimizer/SKILL.md:280`
- The skill claims: *"Memory load order: project rules → project memory → user memory → `CLAUDE.local.md`"*
- The official docs hierarchy (from the memory type table) is:
  1. Managed policy
  2. Project memory (`./CLAUDE.md` or `./.claude/CLAUDE.md`)
  3. Project rules (`./.claude/rules/*.md`)
  4. User memory (`~/.claude/CLAUDE.md`)
  5. Project memory local (`./CLAUDE.local.md`)
  6. Auto memory
- The skill puts "project rules" before "project memory" (reversed), omits "Managed policy" and "Auto memory" tiers. The docs also state "More specific instructions take precedence over broader ones" as the actual precedence rule.
- **Fix:** Correct the load order to match official docs, or replace with "More specific instructions take precedence over broader ones (see official memory docs)."

**C3. README is missing the `path-rules-advisor` skill**
- **File:** `plugins/claude-md-optimizer/README.md:11-13`
- The Skills table only lists `claude-md-optimizer`. The `path-rules-advisor` skill (added in v1.2.0) is completely absent — no table entry, usage examples, or feature description.
- **Fix:** Add `path-rules-advisor` to the Skills table with activation triggers. Add usage examples for both Mode A (argument) and Mode B (analysis) flows.

### Moderate Issues

**M1. `@import` used as a keyword — misleading terminology**
- **Files:** `SKILL.md:87` ("referenced via `@import` or a plain link"), `SKILL.md:281`, `CHANGELOG.md:8,13`
- The official feature is called "CLAUDE.md imports" with `@path/to/file` syntax — there is no `@import` keyword. Writing "referenced via `@import`" could lead users to literally write `@import docs/architecture.md`.
- Step 2's "Import scan" (line 33) correctly describes `@path/to/file` syntax, contradicting D4's phrasing.
- **Fix:** Replace "via `@import`" with "via `@path/to/file` import syntax" in D4 and Notes. Update CHANGELOG entries accordingly.

**M2. Self-reference `@import` guidance conflates two mechanisms**
- **Files:** `SKILL.md:210-217`, `SKILL.md:282`
- The skill advises: *"add `@<plugin-dir>/skills/claude-md-optimizer/SKILL.md` to your CLAUDE.md"*
- This imports the SKILL.md as raw memory/instructions, not as a proper skill with frontmatter-based activation, `$ARGUMENTS` substitution, and skill lifecycle. The two mechanisms are:
  1. Plugin installation (`/plugin install` or `--plugin-dir`) — the supported way
  2. CLAUDE.md imports (`@path/to/file`) — for docs and instructions, not skill files
- **Fix:** Replace with proper plugin installation guidance. If the `@import` approach is intentional as a lightweight alternative, explicitly note the behavioral differences.

**M3. Promotional callout embedded in optimization workflow (Step 5)**
- **File:** `SKILL.md:208-217`
- After generating optimized CLAUDE.md, Step 5 shows a callout suggesting the user add the optimizer to their CLAUDE.md. This appears every time the user accepts optimization, regardless of relevance. Ironic: the user just optimized their CLAUDE.md to be shorter, and now the skill suggests adding more content.
- **Fix:** Move this guidance to the Notes section or README. Remove from the Step 5 workflow.

**M4. D3/D4 dimension overlap causes double-penalizing**
- **File:** `SKILL.md:67-104`
- D3 (80% Rule) flags content that applies to <80% of sessions. D4 (Progressive Disclosure) checks whether complex content is delegated. In practice, most D3 violations are also D4 failures — a deployment runbook violates 80% rule AND isn't delegated. One problem can cost 4 points (0+0) while a different issue costs only 2.
- **Fix:** Add clarifying note: D3 = *what* to remove (content relevance), D4 = *how well* relevant-but-complex content is delegated (structural quality). Sharpen D4 to focus on content that IS relevant to most sessions but is too long/complex to keep inline.

**M5. `$ARGUMENTS` parsing unreliable for intent-activated skills**
- **File:** `plugins/claude-md-optimizer/skills/path-rules-advisor/SKILL.md:24`
- Per official docs, when Claude auto-activates a skill, the user's full natural-language prompt becomes `$ARGUMENTS`. If a user says "create a rule for src/api/**/*.ts - validate all inputs", the entire sentence becomes `$ARGUMENTS`, and the split on ` - ` yields "create a rule for src/api/**/*.ts" (with natural language prefix), not a clean glob pattern.
- **Fix:** Add guidance in Mode A Step 1 to extract the glob pattern and description from natural language, not just split on ` - `. Alternatively, add `disable-model-invocation: true` to make this user-invocable only.

**M6. Instruction counting lacks methodology**
- **File:** `SKILL.md:29-31`
- Step 2 defines "instruction count" as "verb-starting bullet points, numbered directives, and bolded imperatives" but doesn't address multi-line bullets, nested lists, or code blocks containing directives.
- **Fix:** Add brief clarifications: "count top-level bullets only", "ignore code block contents", "count each numbered step as one instruction."

### Minor Issues

**m1. Skill descriptions could be broader for activation matching**
- `SKILL.md:3` — add "check" and "analyze" to claude-md-optimizer description
- `path-rules-advisor/SKILL.md:3` — add "extract rules from CLAUDE.md" and "move rules to separate files"
- `path-rules-advisor/SKILL.md:3` — anchor to Claude Code terminology to avoid false positives (e.g., "eslint rules" matching)

**m2. Rule file format duplicated across both skills**
- `SKILL.md:89-100` (D4) and `path-rules-advisor/SKILL.md:193-226` both describe the `.claude/rules/` format with brace expansion. ~30 lines of duplicated context.
- **Fix:** Keep brief mention in D4, defer to path-rules-advisor for complete format.

**m3. Secret redaction lacks `.env` guidance**
- `SKILL.md:181` — Step 5 replaces secrets with `[REDACTED - move to .env]` but never helps the user create the `.env` file or extract the values before overwriting.
- **Fix:** Add: "If secrets were redacted, show the user suggested `.env` entries before offering to write the optimized file."

**m4. `path-rules-advisor` Mode B uses H1 heading as replacement pointer**
- `path-rules-advisor/SKILL.md:185` — `# See .claude/rules/<name>.md` is an H1 heading used as a reference pointer, which is visually disproportionate.
- **Fix:** Change to bullet: `- See .claude/rules/<name>.md for [topic] rules`

**m5. Keywords in plugin.json could be broader**
- `plugin.json:10-14` — missing "audit" (primary skill verb), "rules", "memory"
- **Fix:** Add `"audit"` and `"rules"` to keywords array.

**m6. Example audit output uses macOS-specific path**
- `SKILL.md:239` — `/Users/alice/projects/myapp/CLAUDE.md` → change to `~/projects/myapp/CLAUDE.md`

---

## Strengths

- **Well-structured scoring rubric** — The 6-dimension audit with 0/1/2 scoring produces a meaningful 0–12 scale with intuitive grades
- **Good skill separation** — `claude-md-optimizer` diagnoses; `path-rules-advisor` implements extraction. They complement without duplicating core logic
- **Safety-first write flow** — Explicit confirmation gates before any disk writes, with Step 6 adding a second confirmation
- **Correct `paths:` frontmatter and brace expansion syntax** — Verified against official docs
- **Clean version history** — CHANGELOG follows Keep a Changelog format; version sync between `plugin.json` and `marketplace.json` is correct (both 1.3.0)
- **Correct homepage URL** — Points to plugin-specific directory per project conventions
- **Step-by-step discipline** — Both skills enforce strict ordering with clear stop-and-ask gates

---

## Implementation Plan

### 1. Fix critical factual inaccuracies (C1, C2)
- **File:** `plugins/claude-md-optimizer/skills/claude-md-optimizer/SKILL.md`
- Rewrite D1 context paragraph (lines 45-46) to remove fabricated slot numbers; use softer guidance
- Correct memory load order in Notes (line 280) to match official docs or replace with precedence rule

### 2. Fix `@import` terminology (M1, M2, M3)
- **File:** `plugins/claude-md-optimizer/skills/claude-md-optimizer/SKILL.md`
- Replace "via `@import`" with "via `@path/to/file` import syntax" in D4 (line 87) and Notes (line 281)
- Remove or relocate the Step 5 self-reference callout (lines 208-217) to Notes section
- Remove the self-reference note on line 282; replace with proper plugin install guidance

### 3. Update README (C3)
- **File:** `plugins/claude-md-optimizer/README.md`
- Add `path-rules-advisor` to Skills table with activation description
- Add usage examples for Mode A and Mode B
- Add brief "What the skill does" section for the second skill

### 4. Clarify D3/D4 distinction (M4)
- **File:** `plugins/claude-md-optimizer/skills/claude-md-optimizer/SKILL.md`
- Add clarifying note after D4: D3 = content relevance (what to remove), D4 = structural delegation (how to organize relevant complex content)

### 5. Address `$ARGUMENTS` parsing (M5)
- **File:** `plugins/claude-md-optimizer/skills/path-rules-advisor/SKILL.md`
- Update Mode A Step 1 to handle natural-language input extraction, not just ` - ` splitting

### 6. Minor fixes (M6, m1–m6)
- Improve instruction counting methodology in Step 2
- Broaden skill activation descriptions
- Reduce rule-file format duplication
- Fix secret redaction guidance, H1 pointer, keywords, example path

### 7. Version bump to 1.4.0
- Update `plugins/claude-md-optimizer/.claude-plugin/plugin.json` version
- Update `.claude-plugin/marketplace.json` version for claude-md-optimizer entry
- Add CHANGELOG entry for 1.4.0

---

## Verification

1. `grep -r '"version"' plugins/claude-md-optimizer/.claude-plugin/ .claude-plugin/marketplace.json` — confirm both show 1.4.0
2. Verify README lists both skills with correct descriptions
3. Verify no remaining instances of "via `@import`" in SKILL.md files
4. Verify memory load order matches official docs
5. Verify D1 no longer cites specific slot numbers
6. Confirm CHANGELOG has a 1.4.0 entry documenting all changes
