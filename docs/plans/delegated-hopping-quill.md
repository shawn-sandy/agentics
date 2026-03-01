# Plan: `code-test-suggestion` Plugin

## Context

Developers frequently write tests that verify implementation details rather than behavior, or rely on coverage tools that produce many low-value tests while missing the ones that catch real bugs. This plugin takes a different approach: it reads the code, searches for the developer's plan/intent, identifies critical behaviors and fragile areas, and suggests the specific tests that would catch the most damaging failures — each with a rationale explaining why the test matters.

This is the first plugin in the `testing` category for the agentics marketplace.

## Plugin Structure

```
plugins/code-test-suggestion/
├── .claude-plugin/
│   └── plugin.json
├── CHANGELOG.md
├── README.md
├── commands/
│   └── suggest-tests.md
└── skills/
    └── code-test-suggestion/
        ├── SKILL.md
        └── references/
            └── test-analysis-guide.md
```

## Files to Create/Modify

### 1. `plugins/code-test-suggestion/.claude-plugin/plugin.json`

Standard plugin manifest, version `1.0.0`, category `testing`. Follows the exact pattern from existing plugins (code-review, plan-interview, etc.).

```json
{
  "name": "code-test-suggestion",
  "version": "1.0.0",
  "description": "Analyze code and suggest specific, purpose-driven tests tied to actual behavior and intent — not arbitrary coverage",
  "author": { "name": "Agentics Project" },
  "license": "MIT",
  "keywords": ["testing", "test-suggestion", "test-driven", "code-analysis", "testability"],
  "homepage": "https://github.com/shawn-sandy/agentics/tree/main/plugins/code-test-suggestion",
  "repository": "https://github.com/shawn-sandy/agentics"
}
```

### 2. `plugins/code-test-suggestion/skills/code-test-suggestion/SKILL.md` (core file)

**Activation triggers** (non-overlapping with code-review's "review code, check for problems, analyze code quality"):
```
description: Suggests targeted, meaningful tests for code based on what the code actually does
and why. Use when the user asks to suggest tests, recommend tests, identify what to test, review
testability, find untested behavior, or asks "what tests should I write". Also use when the user
says "test this code", "what would you test here", or "help me test this feature". Does not write
or run tests directly — suggests and explains what tests would be valuable and why.
```

**Freedom level:** Flexible — steps execute in order but depth adapts to complexity.

**6-step workflow:**

| Step | Purpose |
|------|---------|
| **Step 0** | Create `TodoWrite` progress todos for visibility |
| **Step 1 — Identify Target Code** | Resolve via: explicit path → conversation context → `git diff --name-only` → ask user |
| **Step 2 — Search for Plan** | Search `docs/plans/`, `~/.claude/plans/`, commit messages, inline comments for developer intent. Extract: goal, key behaviors, edge cases, acceptance criteria |
| **Step 3 — Analyze the Code** | 5 dimensions: (a) behavioral summary, (b) critical paths (happy/error/branching/state), (c) integration points, (d) implicit contracts, (e) fragility areas. Loads `references/test-analysis-guide.md` for detailed heuristics |
| **Step 4 — Detect Test Infrastructure** | Find framework from config files, glob for existing test files, read 1-2 nearby tests to learn conventions (assertion style, mocking patterns, naming). **Also detect coverage target** from jest.config, pyproject.toml, .nycrc, codecov.yml, CI config |
| **Step 5 — Suggest Tests** | Prioritized output **grouped by file, then by priority** within each file: P1 (critical behavior), P2 (error handling/edge cases), P3 (integration contracts), P4 `[coverage-only]` (trivial code needed for target), Coverage Assessment, plus "Tests NOT Suggested" section. Each test has: what, why, code reference, approach |
| **Step 6 — Offer to Write** | Ask user if they want test files written using detected project conventions |

**Key suggestion principles built into Step 5:**
- Behavior over implementation ("returns 401 on expired token" not "calls jwt.verify once")
- Plan intent drives test design, coverage validates completeness
- One reason to fail per test
- Name tests as behavior sentences
- Prioritize by blast radius
- Acknowledge existing coverage
- Cover thoroughly: 5-10 behavior-driven tests to start, plus `[coverage-only]` tests for trivial code if needed to meet the project's target

### 3. `plugins/code-test-suggestion/skills/code-test-suggestion/references/test-analysis-guide.md`

Progressive disclosure Level 3 reference (loaded on demand during Step 3). Contains:
- Behavioral summary heuristics (4 guiding questions)
- Critical path identification signals (happy path, error path, state transitions)
- Integration point test strategies with mock/no-mock guidance table
- Implicit contract detection patterns (sorting, uniqueness, timing, idempotency, atomicity)
- Fragility heuristics for: regex, numeric operations, string manipulation, collections
- Language-specific patterns: TypeScript/JS, Python, Go, Rust (lean set for v1.0.0 — Claude can analyze any language; additional language heuristics can be added in v1.1.0)

### 4. `plugins/code-test-suggestion/README.md`

Plugin documentation covering: purpose, how it differs from code-review, skill activation phrases, command usage (`/code-test-suggestion:suggest-tests [path]`), usage examples (with plan, for recent changes), output structure explanation, installation instructions, and plugin structure.

### 5. `plugins/code-test-suggestion/commands/suggest-tests.md`

Explicit command invoked via `/code-test-suggestion:suggest-tests [file-path]`. Follows the plan-interview command pattern with frontmatter:

```markdown
---
description: Analyze code and suggest specific, purpose-driven tests tied to actual behavior and intent
argument-hint: [file-path] - path to file(s) to analyze; omit to use recent git changes
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, Write, Edit, TodoWrite
---
```

The command body contains the **full 6-step workflow** (duplicated from the skill, not a reference). This is necessary because Claude does not auto-load SKILL.md when a command runs — the plan-interview plugin follows the same pattern. The only difference from the skill is Step 1: the command uses `$ARGUMENTS` as the primary file path input, while the skill infers targets from conversation context.

### 6. `plugins/code-test-suggestion/CHANGELOG.md`

Initial `[1.0.0] - 2026-03-01` entry documenting all 6 steps, the reference file, and the `suggest-tests` command.

### 7. `.claude-plugin/marketplace.json` (EDIT existing file)

Add 8th plugin entry to the `plugins` array:
```json
{
  "name": "code-test-suggestion",
  "source": "./plugins/code-test-suggestion",
  "version": "1.0.0",
  "description": "Analyze code and suggest specific, purpose-driven tests tied to actual behavior and intent — not arbitrary coverage",
  "category": "testing",
  "tags": ["testing", "test-suggestion", "test-driven", "code-analysis", "testability"]
}
```

## Differentiation from code-review

| | code-review | code-test-suggestion |
|---|---|---|
| **Purpose** | Finds what's wrong with code | Designs how to prove code works correctly |
| **Triggers** | "review code", "check for problems", "analyze quality" | "suggest tests", "what tests should I write", "test this code" |
| **Output** | Issues + fixes | Test specifications + rationale |
| **Uses plans?** | No | Yes — plans inform test intent |

## Reusable Patterns from Existing Plugins

- **TodoWrite progress tracking**: from `plugins/plan-interview/skills/plan-interview/SKILL.md` (Step 0 pattern)
- **Plan file resolution logic**: adapted from plan-interview's Step 1 priority-based search
- **Progressive disclosure with references/**: from `plugins/claude-md-optimizer/skills/claude-md-optimizer/` and `plugins/skill-reviewer/`
- **Plugin manifest structure**: from any existing plugin's `.claude-plugin/plugin.json`

## Coverage-Aware Update (Post-v1.0.0 Refinement)

The initial v1.0.0 implementation leans too far away from coverage — the wording actively dismisses it ("not arbitrary coverage metrics"). The skill should prioritize behavior-driven tests **while also striving to meet the project's coverage target** (or maximum coverage when no target is defined).

### Changes Required (4 files)

#### SKILL.md — `plugins/code-test-suggestion/skills/code-test-suggestion/SKILL.md`

1. **Line 6 (intro)**: Change from:
   > "Each suggested test is tied to actual code behavior, not arbitrary coverage metrics."

   To:
   > "Each suggested test is tied to actual code behavior. While behavior and intent drive prioritization, always strive to meet the project's coverage target or maximize coverage when no target is defined."

2. **Step 4 — Add sub-step 4d (after 4c)**: New section `4d. Detect Coverage Target`:
   - Search for coverage thresholds in: `jest.config.*` (`coverageThreshold`), `package.json` (`jest.coverageThreshold`), `pyproject.toml` (`[tool.coverage.report]`), `.nycrc`, `codecov.yml`, `.coveragerc`, CI config files
   - Report detected target: "Coverage target: [X]% (from [config file])."
   - If no target found: "No coverage target configured. Aiming for maximum practical coverage."

3. **Step 5 output format**: Add a `**Coverage assessment:**` section to the output template after the Priority 3 tests and before "Tests NOT Suggested":
   > ```markdown
   > ### Coverage Assessment
   >
   > **Coverage target:** [X]% (from [config file]) | No target configured — aiming for maximum practical coverage
   > **Functions/methods covered by suggestions:** [list covered]
   > **Uncovered gaps:** [list functions, branches, or code paths not covered by any suggested test — with brief reason each is uncovered (e.g., "trivial getter", "dead code", "unreachable branch")]
   > ```
   Note: Do NOT include a numeric coverage percentage estimate — Claude cannot run the actual coverage tool, so a guessed number would be misleading. Instead, list what is and is not covered qualitatively.

4. **Suggestion principle #2**: Change from:
   > "Plan intent over arbitrary coverage."

   To:
   > "Plan intent drives test design, coverage validates completeness. Use the plan to determine *what* to test and *why*. Use coverage analysis to ensure nothing important is missed. If the project defines a coverage target, ensure suggestions would meet or exceed it."

5. **Suggestion principle #8**: Change from:
   > "Limit suggestions to what matters. Aim for 5-10 test suggestions for a typical file. Do not produce 30 trivial tests. Quality over quantity."

   To:
   > "Cover thoroughly, not trivially. Aim for 5-10 behavior-driven test suggestions for a typical file, but add more if needed to reach the project's coverage target. If the coverage target requires testing trivial code (simple getters, pass-through methods, one-line wrappers), suggest these tests with a **`[coverage-only]`** tag and a note that they provide minimal behavioral value but are needed for the target. Never leave coverage gaps unacknowledged — if a function or branch is intentionally not tested, state why in the Coverage Assessment."

#### suggest-tests.md — `plugins/code-test-suggestion/commands/suggest-tests.md`

Same 5 changes as SKILL.md (the command duplicates the full workflow):
1. Line 9 intro wording
2. Add Step 4d (coverage target detection)
3. Add coverage assessment line to Step 5 output format
4. Update suggestion principle #2
5. Update suggestion principle #8

#### README.md — `plugins/code-test-suggestion/README.md`

1. Update the "Purpose" paragraph to mention that the skill also aims for coverage:
   > Add: "At the same time, it ensures suggested tests would meet the project's coverage target — or maximize coverage when no target is defined — so you get both meaningful and thorough test suites."

2. Update the output structure section to mention coverage assessment.

#### CHANGELOG.md — `plugins/code-test-suggestion/CHANGELOG.md`

Add a new entry or update 1.0.0:
> - Coverage-aware: Step 4d detects project coverage targets from jest.config, pyproject.toml, .nycrc, codecov.yml; Step 5 includes coverage assessment and ensures suggestions meet or exceed the target

### What does NOT change

- **plugin.json / marketplace.json descriptions**: Keep concise. The description already says "tied to actual behavior and intent" which is accurate — coverage awareness is an implementation detail, not the tagline.
- **test-analysis-guide.md**: No changes needed — it contains heuristics for *analyzing code*, not coverage policy.
- **Activation triggers**: No change — coverage awareness doesn't change when the skill activates.
- **Version**: Stays at 1.0.0 since this is a refinement before first release, not a post-release change.

## Verification

1. **Version sync**: Confirm `plugin.json` version matches `marketplace.json` entry:
   ```bash
   grep -r '"version"' plugins/code-test-suggestion/.claude-plugin/ .claude-plugin/marketplace.json
   ```
2. **Structure validation**: Verify all required files exist:
   ```bash
   ls -la plugins/code-test-suggestion/.claude-plugin/plugin.json
   ls -la plugins/code-test-suggestion/skills/code-test-suggestion/SKILL.md
   ls -la plugins/code-test-suggestion/skills/code-test-suggestion/references/test-analysis-guide.md
   ```
3. **JSON validity**: Parse both JSON files:
   ```bash
   python3 -c "import json; json.load(open('plugins/code-test-suggestion/.claude-plugin/plugin.json'))"
   python3 -c "import json; json.load(open('.claude-plugin/marketplace.json'))"
   ```
4. **Local load test**:
   ```bash
   claude --plugin-dir ~/devbox/agentics/plugins/code-test-suggestion
   ```
   Then trigger with: "suggest tests for [some file]" — verify skill activates and follows the 6-step workflow.
