# Plan: Add Breaking Changes & Regression Detection to code-review-agent

## Context

The `code-review-agent` skill currently reviews code quality, bugs, security, best practices, and complexity — but has no dedicated detection of breaking changes or regressions. Developers changing shared utilities, public APIs, or widely-used interfaces need explicit callouts when their changes could break callers or reintroduce previously fixed behaviors. This plan adds that dimension as a first-class checklist section and review output section.

## Target File

- `plugins/code-review/skills/code-review-agent/SKILL.md`

## Also Updated (version bump — MINOR)

- `plugins/code-review/.claude-plugin/plugin.json` — bump `2.0.0` → `2.1.0`
- `.claude-plugin/marketplace.json` — sync version to `2.1.0`
- `plugins/code-review/CHANGELOG.md` — add `[2.1.0]` entry

---

## Implementation Steps

### 1. Update frontmatter `description`

Append detection of breaking changes and regressions to the one-line description so the skill auto-activates on those intents:

```
description: Reviews code for best practices, bugs, security vulnerabilities, complexity, breaking changes, and potential regressions. Use when the user asks to review code, check a file for problems, review changed files, analyze code quality, assess code complexity, or detect breaking changes. Does not cover architecture reviews or testing strategy.
```

### 2. Add ToC entry

Add after the `[5. Code Complexity]` entry:

```
  - [6. Breaking Changes & Regressions](#6-breaking-changes--regressions)
```

### 3. Add checklist section 6 after the Complexity section

Insert a new `### 6. Breaking Changes & Regressions` section with these sub-categories:

**Public API Surface**
- Are exported functions, classes, or types renamed or removed?
- Have function signatures changed (added required params, removed params, reordered params)?
- Have return types or shapes changed in ways callers won't expect?
- Are previously thrown errors now suppressed, or new errors thrown that callers don't handle?

**Shared / Internal Contracts**
- Are widely-used utilities or helpers modified in ways that affect all call sites?
- Are base classes or interfaces changed in ways that break subclasses?
- Are default argument values, fallback behaviors, or guard conditions changed?

**Data & Config Contracts**
- Are environment variable names or config keys renamed or removed?
- Are serialized data formats, API request/response shapes, or wire formats changed?
- Are database schema changes present (NOT NULL columns added, columns dropped, type changes)?

**Regression Risk**
- Does the change touch code that previously had bugs fixed? (check git blame / commit messages for context)
- Are shared mutable states or global singletons modified?
- Are previously reliable invariants (e.g., "this function never returns null") broken?

**Detection Approach**
- Use `git diff` or `git log --follow` to compare changed exports/signatures to their previous form
- Search for all call sites of changed functions using grep/AST awareness to estimate blast radius
- Flag high blast-radius changes (3+ callers) as higher severity

### 4. Update Review Format

Add a `### Breaking Changes & Regressions` section to the output format, placed **between Summary/Complexity and Critical Issues**:

```markdown
### Breaking Changes & Regressions
List any changes that break existing callers, alter contracts, or risk reintroducing previously fixed behavior.
For each:
- **What changed** — the specific symbol, config key, schema field, or behavior
- **Who is affected** — call sites, dependents, consumers
- **Severity** — Breaking (callers will fail) / Risky (callers may silently misbehave)
- **Migration path** — what callers must do to adapt

If none detected: `No breaking changes or regression risks identified.`
```

### 5. Add a brief example to the Example Review section

Show a sample breaking change entry under the new output section.

### 6. Version bump

- `plugin.json`: `"version": "2.0.0"` → `"version": "2.1.0"`
- `marketplace.json`: sync version for `code-review` entry to `2.1.0`
- `CHANGELOG.md`: add `[2.1.0]` entry documenting the new section

---

## Verification

1. Load the plugin: `claude --plugin-dir ~/devbox/agentics/plugins/code-review`
2. Trigger with: _"review my changed files"_ or _"check for breaking changes"_ — skill should activate
3. Confirm output includes the new `Breaking Changes & Regressions` section
4. Verify `grep -r '"version"' plugins/code-review/.claude-plugin/ .claude-plugin/marketplace.json` shows matching `2.1.0`

---

## Unresolved Questions

None — scope is clear.

---

## Interview Summary

### Key Decisions Confirmed

- **Call site detection**: Instruct Claude to grep for callers when a repo is accessible, with an explicit caveat when callers aren't visible from the reviewed file alone
- **Section placement**: "Breaking Changes & Regressions" as its own output section placed **before** Critical Issues
- **DB schema checks**: Keep but mark conditional — "Apply only when reviewing migration files or schema definitions"
- **Example type**: Renamed/removed function export (most universally recognizable)

### Plan Naming

| Element | Current | Issue | Suggested |
|---------|---------|-------|-----------|
| Filename | `robust-stargazing-volcano.md` | Random — unrelated to content | `add-breaking-change-regression-detection.md` |
| H1 Heading | `# Plan: Add Breaking Changes & Regression Detection to code-review-agent` | Passes | — |

User confirmed rename — execute post-plan-mode via `mv`.

### Open Risks & Concerns

1. **Duplicate reporting**: No guidance on whether a breaking change that belongs in both the new section and "Critical Issues" should be duplicated, cross-referenced, or suppressed
2. **Over-triggering risk**: Adding "breaking changes" and "regressions" as keyword triggers in the frontmatter may cause false-positive skill activations — phrasing should target intent, not raw keywords
3. **Detection Approach style inconsistency**: Procedural steps (`git diff`, grep) conflict with the question-based style of the rest of the checklist — could cause inconsistent behavior
4. **Missing fallback for no git context**: No guidance for reviewed snippets or new files with no git history

### Recommended Next Steps

1. **Resolve duplicate reporting**: Add a note to the Review Format — e.g., "If a breaking change also qualifies as a Critical Issue, list it in Breaking Changes & Regressions only and omit from Critical Issues to avoid duplication"
2. **Rephrase frontmatter triggers**: Use intent-pattern phrasing rather than raw keywords — e.g., `"check if this change breaks anything"` and `"could this cause a regression"` as example trigger phrases
3. **Normalize Detection Approach to question style**: Replace procedural steps with questions matching the existing checklist format — e.g., "Are there other files that import or call this symbol? Does git history confirm this symbol previously existed?"
4. **Add a no-git-context fallback note**: "If git history is unavailable, assess the API surface visually from the reviewed code only"

### Simplification Opportunities

- **Detection Approach**: Convert from procedure (`git diff`, grep commands) to question-based guidance consistent with the rest of the checklist — same outcome, no style mismatch, Claude retains flexibility in how it investigates
