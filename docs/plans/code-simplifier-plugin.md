# Plan: code-simplifier Plugin

## Context

The marketplace has a `code-review` plugin that catches bugs, security issues, and breaking changes, but nothing that systematically identifies **structural quality problems** — dead code, excessive complexity, god classes, duplicated logic, poor cohesion, and performance anti-patterns. These "code smells" accumulate silently and slow teams down. This plugin fills that gap with a dedicated analysis workflow that enters plan mode, creates a prioritized refactoring plan, reviews it with the developer, and then applies the approved changes.

## Directory Structure

```
kit/plugins/code-simplifier/
  .claude-plugin/
    plugin.json
  skills/
    code-simplifier/
      SKILL.md
      references/
        smell-checklist.md
        example-analysis.md
  agents/
    agent-code-simplifier.md
  README.md
  CHANGELOG.md
```

Plus: add entry to `.claude-plugin/marketplace.json` (root).

## Steps

### 1. Create `references/smell-checklist.md`

Nine-category smell checklist (dependency of the skill — write first):

1. **Dead Code & Unused Declarations** — unreachable paths, unused vars/imports/methods, stale TODOs
2. **Excessive Complexity** — cyclomatic complexity >10, nesting >3 levels, functions >50 lines, chained ternaries
3. **God Classes & God Functions** — classes >300 lines, >5 unrelated public methods, vague "Manager/Handler/Utils" names
4. **Duplicated Logic** — 5+ near-identical lines across files, repeated conditionals, copy-pasted error handling
5. **Coupling & Cohesion** — deep internal imports, circular deps, temporal coupling, catch-all utility files
6. **Primitive Obsession & Feature Envy** — bare strings for domain types, magic numbers, flag arguments, methods that primarily access another object's data
7. **Parameter Lists & Signatures** — >4 params, boolean flags, confusable positional params
8. **Naming & Consistency** — inconsistent conventions, abbreviations, misleading names, generic names for domain concepts
9. **Performance Anti-Patterns** — N+1 queries, missing memoization, unnecessary re-renders, resource leaks

Includes a severity rating guide: Clean / Minor Issues / Needs Refactoring / Major Refactoring Needed.

### 2. Create `references/example-analysis.md`

Complete sample output demonstrating the analysis format — mirrors `code-review/references/example-review.md` structure but with smell-specific findings and refactoring suggestions.

### 3. Create `skills/code-simplifier/SKILL.md`

**Frontmatter:**
```yaml
name: code-simplifier
description: >
  Analyzes code for structural quality issues, code smells, and optimization
  opportunities. Use when the user asks to simplify code, find code smells,
  reduce complexity, identify refactoring opportunities, check for dead code,
  clean up messy code, or optimize structure. Creates a refactoring plan and
  applies approved changes. Does not cover bugs, security, or test coverage.
allowed-tools: AskUserQuestion, Bash, Edit, EnterPlanMode, ExitPlanMode, Glob, Grep, Read, Write
```

**Workflow (7 steps):**

1. **Resolve target files** — explicit path > `git status --short` > `git diff main...HEAD --name-only` > fallback AskUserQuestion. Skip binaries/lock files/generated files.
2. **Enter plan mode** — call `EnterPlanMode`. All analysis happens in plan mode.
3. **Analyze code smells** — read `references/smell-checklist.md`, apply each category to every target file. Record category, smell name, file:line, severity (Critical/Moderate/Minor), confidence (High/Medium — discard Low).
4. **Create refactoring plan** — resolve plans directory (check `.claude/settings.json` for `plansDirectory`, fallback `docs/plans/`). Write plan file with: summary, prioritized refactoring steps, before/after code examples for top findings, estimated effort.
5. **Present findings** — show structured analysis (summary, severity rating, critical smells, moderate smells, refactoring plan link, positive observations).
6. **Review with developer** — use `AskUserQuestion` with options: Approve and apply / Adjust the plan / Discard. Loop on adjustments.
7. **Apply changes** — call `ExitPlanMode`, then apply the approved refactoring steps using Edit/Write. If the developer discards, delete plan file and exit plan mode without changes.

**Key tools rationale:**
- `EnterPlanMode` / `ExitPlanMode` — enforces read-only during analysis, write after approval
- `Edit` / `Write` — needed for the "apply" phase after user approves
- `Glob` / `Grep` — for finding related files when analyzing coupling/duplication

### 4. Create `agents/agent-code-simplifier.md`

**Frontmatter:**
```yaml
name: agent-code-simplifier
description: >
  Internal background code simplification agent for delegation from other agents
  or automated workflows. Analyzes code for structural quality issues, code
  smells, and optimization opportunities using confidence-based filtering to
  report only high-priority findings. Use when delegating a structural quality
  analysis to a sub-agent or running a proactive sweep after a merge or batch of
  commits. Not intended for direct user requests — use the code-simplifier skill.
  Does not cover bugs, security, or test coverage.
tools: Read, Glob, Grep, Bash
disallowedTools: Write, Edit, NotebookEdit
model: sonnet
permissionMode: plan
maxTurns: 10
memory: project
background: true
```

**Sections:** Role, Behavior, Workflow (resolve files > read & analyze > confidence filter > format report), Output Format, Scope Boundaries, Memory.

Read-only. Returns structured report. No plan mode interaction (that's the skill's job).

### 5. Create `.claude-plugin/plugin.json`

```json
{
  "name": "code-simplifier",
  "description": "Analyze code for structural quality issues, code smells, and optimization opportunities",
  "author": { "name": "Agentics Project" },
  "license": "MIT",
  "keywords": ["code-smells", "refactoring", "complexity", "dead-code", "simplification"],
  "homepage": "https://github.com/shawn-sandy/agentics/tree/main/kit/plugins/code-simplifier",
  "repository": "https://github.com/shawn-sandy/agentics"
}
```

No `version` field — version lives in marketplace.json only.

### 6. Create `README.md`

Sections: Purpose, How It Differs from code-review, Skills table, Smell Checklist Overview (nine categories), Agent (internal) table, Usage examples (automatic activation + agent delegation), Installation.

### 7. Create `CHANGELOG.md`

```markdown
# Changelog

## [1.0.0] - 2026-04-30

### Added
- Initial release of code-simplifier plugin
- `code-simplifier` skill with plan-mode refactoring workflow
- `agent-code-simplifier` background agent for delegated analysis
- Nine-category smell checklist
- Plan + apply workflow with developer approval gate
```

### 8. Update `.claude-plugin/marketplace.json`

Add entry to the `plugins` array:

```json
{
  "name": "code-simplifier",
  "source": {
    "source": "git-subdir",
    "url": "https://github.com/shawn-sandy/agentics.git",
    "path": "kit/plugins/code-simplifier"
  },
  "version": "1.0.0",
  "description": "Analyze code for structural quality issues, code smells, and optimization opportunities",
  "category": "development",
  "tags": ["code-smells", "refactoring", "complexity", "dead-code", "code-quality", "simplification", "optimization"]
}
```

## Critical Files

| File | Action |
|------|--------|
| `kit/plugins/code-simplifier/skills/code-simplifier/SKILL.md` | Create |
| `kit/plugins/code-simplifier/skills/code-simplifier/references/smell-checklist.md` | Create |
| `kit/plugins/code-simplifier/skills/code-simplifier/references/example-analysis.md` | Create |
| `kit/plugins/code-simplifier/agents/agent-code-simplifier.md` | Create |
| `kit/plugins/code-simplifier/.claude-plugin/plugin.json` | Create |
| `kit/plugins/code-simplifier/README.md` | Create |
| `kit/plugins/code-simplifier/CHANGELOG.md` | Create |
| `.claude-plugin/marketplace.json` | Modify (add entry) |

## Existing Code to Reuse

- **File resolution pattern** — same 4-priority order as `kit/plugins/code-review/skills/code-review-agent/SKILL.md:22-46`
- **Review output format** — adapted from `kit/plugins/code-review/skills/code-review-agent/SKILL.md:55-98`
- **Agent structure** — mirrors `kit/plugins/code-review/agents/agent-code-reviewer.md` (confidence filtering, memory, scope boundaries)
- **Marketplace entry format** — follows existing entries in `.claude-plugin/marketplace.json`

## Verification

1. **Load plugin locally:** `claude --plugin-dir ./kit/plugins/code-simplifier`
2. **Test skill activation:** say "find code smells in src/utils/" — should trigger the skill, enter plan mode, and produce analysis
3. **Test file resolution:** invoke without a target path — should detect git changes or prompt
4. **Test plan creation:** verify plan file appears in the project's plans directory
5. **Test apply flow:** approve the plan — verify the skill exits plan mode and applies changes
6. **Test discard flow:** discard the plan — verify plan file is deleted and no changes are made
7. **Test agent delegation:** from another session, call `Agent(subagent_type: "code-simplifier:agent-code-simplifier", prompt: "Analyze kit/plugins/code-review/ for code smells")` — should return structured report
8. **Validate marketplace.json:** run `python -m json.tool .claude-plugin/marketplace.json` — should parse without errors
