# Skill Authoring Best Practices

Reference criteria for the `reviewing-skills` audit. Each section maps to a scoring dimension.

## Table of Contents

- [Frontmatter Rules](#frontmatter-rules)
  - [Name Field](#name-field)
  - [Description Field](#description-field)
- [Body Quality Rules](#body-quality-rules)
- [Structure and Progressive Disclosure](#structure-and-progressive-disclosure)
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

### Line Count

| Lines | Assessment |
|-------|------------|
| <400 | Ideal |
| 400–499 | Acceptable; consider splitting into reference files |
| ≥500 | Exceeds limit — must split content into `references/` files |

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

### Reference File Depth

Reference files must be at exactly one level below the skill root:

| Valid | Invalid |
|-------|---------|
| `references/best-practices.md` | `references/sub/best-practices.md` |
| `references/audit-steps.md` | `references/steps/audit/step3.md` |

Claude Code resolves reference paths relative to the skill directory. Nested paths are not supported.

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

### Warning Level (should fix)

| Anti-pattern | Description | Fix |
|--------------|-------------|-----|
| Missing "Use when..." | Trigger phrase absent from description | Add "Use when the user asks to..." |
| Options without a default | Presents 3 options with no recommended default | Designate a default option |
| Time-sensitive content | Platform state described as of a specific date | Rewrite as timeless fact |
| Missing TOC on long file | File >100 lines lacks navigation | Add table of contents |
| Vague trigger phrase | "Use when user asks anything about code" | Make trigger specific to this skill's domain |

### Suggestion Level (consider fixing)

| Anti-pattern | Description | Fix |
|--------------|-------------|-----|
| No concrete examples | Abstract instructions only | Add a before/after or code block example |
| Missing scope definition | Description doesn't say what skill won't do | Add scope exclusion sentence |
| Fewer than 3 keywords | Description not searchable | Add domain-specific terms |
| Freedom level unstated | Reader must infer rigidity | Add "Follow these steps exactly" or "Adapt to context" |
| Imperative voice avoided | "You should" instead of direct imperatives | Use "Do X" not "You should do X" |

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
