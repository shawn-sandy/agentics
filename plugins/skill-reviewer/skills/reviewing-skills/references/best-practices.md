# Skill Authoring Best Practices

Reference criteria for the `reviewing-skills` audit. Each section maps to a scoring dimension. Aligned with Anthropic's "The Complete Guide to Building Skills for Claude" (Jan 2026).

## Table of Contents

- [Frontmatter Rules](#frontmatter-rules)
  - [Name Field](#name-field)
  - [Description Field](#description-field)
- [Body Quality Rules](#body-quality-rules)
- [Structure and Progressive Disclosure](#structure-and-progressive-disclosure)
  - [Three-Level Progressive Disclosure](#three-level-progressive-disclosure)
  - [Folder Structure](#folder-structure)
  - [Skill Packs](#skill-packs)
- [Design Patterns](#design-patterns)
- [Anti-patterns](#anti-patterns)
- [Discoverability Patterns](#discoverability-patterns)

---

## Frontmatter Rules

Frontmatter appears between YAML delimiter pairs (`---`). Both fields are required.

```yaml
---
name: my-skill-name
description: Reviews X for Y. Use when the user asks to...
---
```

### Name Field

**Format requirements:**

| Requirement | Rule | Bad Example | Good Example |
|-------------|------|-------------|--------------|
| Character set | Lowercase letters, numbers, hyphens only | `My_Skill`, `mySkill`, `my skill` | `my-skill`, `skill-reviewer` |
| Length | ≤64 characters | (64+ char name) | `reviewing-skills` |
| Reserved words | Must not contain `anthropic` or `claude` as substring | `claude-helper`, `anthropic-audit` | `skill-reviewer`, `code-audit` |
| No version suffix | Do not include version in name | `skill-reviewer-v2` | `skill-reviewer` |

**Reserved word rule:** The check is a substring match. `claude-helper` fails because it contains `claude`. `claudemd-optimizer` also fails.

**Naming convention — prefer gerund form:**

| Style | Example | Notes |
|-------|---------|-------|
| Gerund (preferred) | `reviewing-skills`, `auditing-code` | Action in progress — matches how skills work |
| Noun (acceptable) | `skill-reviewer`, `code-auditor` | Clear but less idiomatic |
| Verb (avoid) | `review-skill`, `audit` | Imperative form — conflicts with command style |

---

### Description Field

**Requirements:**

| Requirement | Rule | Bad Example | Good Example |
|-------------|------|-------------|--------------|
| Length | ≤1024 characters | (1025+ char description) | (clear, concise description) |
| Person | Third person — no "I", "you", "we", "your" | "I will review your skill." | "Reviews SKILL.md files for quality." |
| Trigger phrase | Must contain "Use when..." | "This skill reviews code." | "Reviews code. Use when the user asks to check quality." |
| No XML tags | No `<example>`, `<user>`, or other XML | "Use when <user> asks..." | "Use when the user asks..." |
| No newlines | Single-paragraph description | Multi-line with `\n` | Single continuous sentence or two |

**Trigger phrase patterns (good examples):**

```
Use when the user asks to review a SKILL.md file.
Use when the user asks to audit, score, or check skill quality.
Use when the user says "review my skill", "check this SKILL.md", or "does my skill follow best practices".
```

**Scope definition (recommended — prevents activation collision):**

Add a sentence clarifying what the skill does NOT handle:

```
...specifically for SKILL.md files — not CLAUDE.md, commands, or general markdown.
```

---

## Body Quality Rules

The body is everything after the closing `---` frontmatter delimiter.

### Size Limits

Skills are evaluated against two thresholds: line count (legacy check) and word count (per Anthropic's guide).

**Line count:**

| Lines | Assessment |
|-------|------------|
| <400 | Ideal |
| 400–499 | Acceptable; consider splitting into reference files |
| ≥500 | Exceeds limit — must split content into `references/` files |

**Word count (Anthropic guideline):**

| Words | Assessment |
|-------|------------|
| <3,000 | Ideal — concise, focused |
| 3,000–4,999 | Acceptable; consider offloading detail to `references/` |
| ≥5,000 | Exceeds recommended limit — must split into `references/` or a Skill Pack |

Word count takes precedence when the two thresholds disagree. A 450-line file at 6,000 words still needs splitting.

### Content Quality

| Rule | Bad | Good |
|------|-----|------|
| Concrete examples | Abstract description only | Code block or before/after example |
| Consistent terminology | "task" then "job" then "operation" for same thing | Same term used throughout |
| Imperative voice | "You should read the file" | "Read the file" |
| No time-sensitive content | "As of 2024, Claude supports..." | "Claude supports..." (timeless) |
| No speculation | "This might work..." | Definitive instructions |

### Time-sensitive content (Error patterns)

Avoid any of these phrases:
- "as of [date/year]"
- "currently" (when referring to platform state)
- "recently added"
- "new in version X"
- "in the latest release"

These become incorrect as Claude Code evolves.

---

## Structure and Progressive Disclosure

### Three-Level Progressive Disclosure

Anthropic's guide defines a three-level system for how Claude loads skill content:

| Level | What | When Loaded | Implication |
|-------|------|-------------|-------------|
| **Level 1** | YAML frontmatter (`name` + `description`) | Always — present in Claude's system prompt | Description determines whether the skill activates at all |
| **Level 2** | SKILL.md body | On activation — when Claude determines the skill applies | Must be self-contained enough to execute the skill |
| **Level 3** | Linked files (`references/`, `scripts/`) | On demand — loaded only when the task requires them | Offload detail here to keep SKILL.md body lean |

The frontmatter description carries outsized importance — if Claude does not understand when to use the skill from that description, the rest never loads.

### Folder Structure

**Folder naming:** Must use kebab-case (e.g., `sprint-planner`, `reviewing-skills`).

**SKILL.md filename:** Case-sensitive, must be exactly `SKILL.md` — no variations (`skill.md`, `Skill.md`).

**Minimum viable skill:**

```
my-skill/
└── SKILL.md
```

**Full skill structure (optional subdirectories):**

```
my-skill/
├── SKILL.md           ← Required — core instructions
├── scripts/           ← Optional — executable Python or Bash scripts
├── references/        ← Optional — documentation loaded on demand
└── assets/            ← Optional — templates, config files, static resources
```

| Subdirectory | Purpose | Example Contents |
|-------------|---------|-----------------|
| `scripts/` | Executable automation scripts | `generate-report.py`, `setup.sh` |
| `references/` | Extended documentation loaded by Claude on demand | `best-practices.md`, `api-reference.md` |
| `assets/` | Templates, config samples, static resources | `template.html`, `config.example.json` |

### Reference File Depth

Reference files must be at exactly one level below the skill root:

| Valid | Invalid |
|-------|---------|
| `references/best-practices.md` | `references/sub/best-practices.md` |
| `references/audit-steps.md` | `references/steps/audit/step3.md` |

Claude Code resolves reference paths relative to the skill directory. Nested paths are not supported.

### Skill Packs

When a skill grows too large or serves multiple related purposes, split it into a **Skill Pack** — multiple skills in one plugin directory.

**When to split:**
- Single skill exceeds 5,000 words even after using `references/`
- Skill serves two distinct user intents that rarely overlap
- Users need to invoke sub-workflows independently

**Example (two skills in one plugin):**

```
plugins/claude-md-optimizer/
├── skills/
│   ├── claude-md-optimizer/     ← Skill 1: audit CLAUDE.md files
│   │   └── SKILL.md
│   └── path-rules-advisor/      ← Skill 2: create .claude/rules/ files
│       └── SKILL.md
```

Each skill has its own `SKILL.md` with independent frontmatter and triggers. Avoid creating skill packs for tightly coupled workflows that always run together.

### Table of Contents

Files at or exceeding 100 lines must have a TOC immediately after the title or overview section. TOC format:

```markdown
## Table of Contents

- [Section Name](#section-name)
  - [Subsection](#subsection)
```

### Freedom Level

Indicate how strictly the skill should be followed. This prevents Claude from over-adapting or under-adapting:

| Freedom Level | When to Use | Signal Phrase |
|---------------|-------------|---------------|
| Rigid | Workflows where deviation causes errors | "Follow these steps exactly." |
| Flexible | Patterns that adapt to context | "Adapt these principles to the situation." |
| Suggested | Loose guidance | "Consider these approaches." |

If unspecified, Claude defaults to flexible — which may be wrong for process-critical skills.

### Heading Hierarchy

- Use H2 (`##`) for major sections
- Use H3 (`###`) for subsections
- Do not skip levels (no H2 → H4)
- Do not use H1 (`#`) inside the body (the frontmatter `name` serves as the title)

---

## Design Patterns

Anthropic's guide codifies four design patterns for skills. Identifying which pattern a skill follows helps assess whether its structure is appropriate.

| Pattern | Use When | Structure Signals |
|---------|----------|-------------------|
| **Sequential / Pipeline** | Multi-step processes in a specific order | Numbered steps, phase markers, rollback instructions |
| **Orchestrator** | Workflows spanning multiple services or tools | MCP tool calls, API integrations, service coordination |
| **Iterative / Refinement** | Output quality improves with iteration | Draft → review → refine loops, quality gates, revision limits |
| **Adaptive** | Same outcome, different tools depending on context | Conditional branching, file-type detection, environment checks |

**Sequential / Pipeline** is the most common pattern for Claude Code skills. Look for numbered steps, `TodoWrite` progress tracking, and explicit "do not skip steps" instructions.

**Orchestrator** skills coordinate external services — expect references to MCP tools, API endpoints, or cross-service workflows.

**Iterative / Refinement** skills produce high-stakes output where first-draft quality is insufficient. Look for revision loops and quality thresholds.

**Adaptive** skills handle the same goal with different approaches based on context (e.g., different linters for different languages).

A skill may combine patterns — a Sequential skill with an Adaptive sub-step is common. The primary pattern should be clearly signalled in the body structure.

---

## Anti-patterns

Anti-patterns by severity:

### Error Level (must fix)

| Anti-pattern | Description | Fix |
|--------------|-------------|-----|
| `$ARGUMENTS` in skill | `$ARGUMENTS` only works in commands | Remove or replace with conversation context instructions |
| `$PWD` in skill | `$PWD` only works in commands | Remove or replace with file resolution logic |
| XML in description | `<example>`, `<user>` tags | Remove all XML tags from description field |
| First/second person in description | "I will...", "You should..." | Rewrite in third person |
| Reserved word in name | `claude-helper`, `anthropic-tool` | Choose a name without the reserved substrings |
| Windows paths | `references\file.md` | Use forward slashes: `references/file.md` |
| Reference depth >1 | `references/sub/file.md` | Flatten to `references/file.md` |
| Wrong SKILL.md casing | `skill.md`, `Skill.md` | Must be exactly `SKILL.md` (case-sensitive) |
| Hardcoded absolute paths | `/Users/me/project/data.json` | Use relative paths or file-resolution logic |

### Warning Level (should fix)

| Anti-pattern | Description | Fix |
|--------------|-------------|-----|
| Missing "Use when..." | Trigger phrase absent from description | Add "Use when the user asks to..." |
| Options without a default | Presents 3 options with no recommended default | Designate a default option |
| Time-sensitive content | Platform state described as of a specific date | Rewrite as timeless fact |
| Missing TOC on long file | File >100 lines lacks navigation | Add table of contents |
| Vague trigger phrase | "Use when user asks anything about code" | Make trigger specific to this skill's domain |
| Exceeds 5,000 words | SKILL.md body is too long for efficient loading | Split into `references/` files or a Skill Pack |
| Non-kebab-case folder name | `mySkill/`, `My_Skill/` | Use `my-skill/` |

### Suggestion Level (consider fixing)

| Anti-pattern | Description | Fix |
|--------------|-------------|-----|
| No concrete examples | Abstract instructions only | Add a before/after or code block example |
| Missing scope definition | Description doesn't say what skill won't do | Add scope exclusion sentence |
| Fewer than 3 keywords | Description not searchable | Add domain-specific terms |
| Freedom level unstated | Reader must infer rigidity | Add "Follow these steps exactly" or "Adapt to context" |
| Imperative voice avoided | "You should" instead of direct imperatives | Use "Do X" not "You should do X" |
| No design pattern visible | Skill body has no structural pattern | Consider adopting Sequential, Orchestrator, Iterative, or Adaptive pattern |
| Missing cross-platform note | Skill uses Claude-Code-only features without noting it | Add note if skill depends on CLI-specific features (e.g., `Bash` tool) |

---

## Discoverability Patterns

### Trigger Phrase Structure

The `description` field is the only signal Claude uses to decide whether to activate a skill. Make triggers specific and multi-phrased:

**Pattern 1 — Intent + phrases:**
```
Reviews X for Y. Use when the user asks to [action], [action], or [action].
```

**Pattern 2 — Explicit triggers:**
```
Use when the user says "[phrase1]", "[phrase2]", or asks about [topic].
```

**Pattern 3 — Scope exclusion:**
```
...specifically for SKILL.md files — not CLAUDE.md, commands, or general markdown.
```

### Keyword Density

Include at least 3 domain-specific, searchable keywords in the description. These help Claude match user intent:

| Domain | Example Keywords |
|--------|-----------------|
| Skill authoring | `SKILL.md`, `skill quality`, `skill authoring`, `best practices` |
| Code review | `code review`, `bugs`, `security`, `quality` |
| Accessibility | `WCAG`, `a11y`, `accessibility`, `screen reader` |

Avoid generic keywords: "tool", "helper", "utility", "assistant".

### Activation Collision Risk

Two skills with similar descriptions may both activate — or neither activates reliably. To reduce collision risk:

1. Make trigger phrases distinct from related skills
2. Add scope exclusion (what the skill does NOT do)
3. Use domain-specific terms the other skill doesn't use

**Example (collision risk):**
```yaml
# Skill A
description: Reviews files for quality. Use when user asks to review files.

# Skill B
description: Reviews files for best practices. Use when user asks to review files.
```

**Example (collision avoided):**
```yaml
# Skill A
description: Reviews SKILL.md files against authoring best practices. Use when user asks to audit a SKILL.md specifically — not CLAUDE.md or commands.

# Skill B
description: Reviews CLAUDE.md files for compliance with Claude Code conventions. Use when user asks to audit or optimize CLAUDE.md — not skill files or commands.
```
