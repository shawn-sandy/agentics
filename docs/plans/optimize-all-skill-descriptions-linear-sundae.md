---
title: Optimize All Skill Descriptions
status: proposed
created: 2026-05-26
---

## Context

All 36 SKILL.md files across the 16 marketplace plugins need their `description:` frontmatter fields brought into compliance with the canonical two-sentence format defined in `.claude/rules/plugin-patterns.md` (line 92):

> `[Capability statement.] Use when the user asks to [trigger].` — Total budget: ≤160 chars.

**Current state (audit of all 36 files):**
- 34/36 use trigger-first format (non-compliant) — missing the capability sentence
- 7/36 exceed the 160-char budget
- 2/36 are missing the `description:` field entirely (`commit-agent`, `pr-agent`)
- 2/36 are already compliant and should not be changed (`auditing-allowed-tools`, `optimizing-skill-frontmatter`)

Four descriptions also embed routing/disambiguation clauses that exceed the budget. Those clauses must be relocated to the skill body under a `## When not to use` or `## Scope` section so the information is preserved.

## Approach

For each non-compliant file:
1. Replace the `description:` value with the optimized string below (capability first, trigger second, ≤160 chars)
2. For `commit-agent` and `pr-agent` — add the missing `description:` key to the YAML frontmatter block
3. For `plan-interview`, `plan-review-agents`, `documenting-plans`, and `plan-to-html` — also add a `## When not to use` section to the body preserving the dropped disambiguation text

No other frontmatter fields should be changed (leave `allowed-tools`, `disable-model-invocation`, `name`, etc. untouched).

## Optimized Descriptions (all ≤160 chars, capability-first)

Files marked ✓ are already compliant — skip them.

### agent-creator

| File | Optimized description |
|------|----------------------|
| `skills/generating-agents/SKILL.md` | `Scaffolds a complete Claude Code agent with frontmatter and system prompt. Use when the user asks to create, scaffold, or generate an agent.` |

### agent-reviewer

| File | Optimized description |
|------|----------------------|
| `skills/reviewing-agents/SKILL.md` | `Audits Claude Code agent files for quality across 5 dimensions, with optional fixes. Use when the user asks to review, audit, or score an agent definition.` |

### agentic-plugin-dev

| File | Optimized description |
|------|----------------------|
| `skills/plugin-creator/SKILL.md` | `Scaffolds a complete Claude Code plugin with manifest and all component types. Use when the user asks to create or scaffold a new plugin from scratch.` |
| `skills/plugin-manager/SKILL.md` | `Manages plugin entries in marketplace.json — add, remove, bump versions, and update metadata. Use when the user asks to list, add, remove, or bump a plugin.` |
| `skills/plugin-validator/SKILL.md` | `Validates plugin manifest, directory structure, and frontmatter against the official spec. Use when the user asks to validate or audit a plugin.` |

### code-review

| File | Optimized description |
|------|----------------------|
| `skills/code-review-agent/SKILL.md` | `Reviews code for bugs, security vulnerabilities, quality issues, and breaking changes. Use when the user asks to review code or check a PR diff.` |

### code-simplifier

| File | Optimized description |
|------|----------------------|
| `skills/code-simplifier/SKILL.md` | `Analyzes code for smells and complexity, then creates a prioritized refactoring plan. Use when the user asks to simplify code, reduce complexity, or refactor.` |

### code-testing-agent

| File | Optimized description |
|------|----------------------|
| `skills/code-testing-agent/SKILL.md` | `Suggests purpose-driven tests tied to actual behavior and writes test files. Use when the user asks to suggest tests or find untested behavior.` |
| `skills/reviewing-tests/SKILL.md` | `Audits tests for quality, coverage gaps, and alignment with code intent. Use when the user asks to review tests, audit test quality, or improve a test suite.` |
| `skills/running-tests/SKILL.md` | `Detects the test framework, runs scoped tests, and reports pass/fail results. Use when the user asks to run tests, check if tests pass, or verify changes.` |
| `skills/tdd-fix/SKILL.md` | `Writes a failing test then autonomously red-greens it up to 10 iterations to fix a bug. Use when the user asks to TDD-fix a bug or run a red-green cycle.` |
| `skills/tdd-loop/SKILL.md` | `Writes failing tests then loops up to 20 red-green-refactor rounds to implement a feature. Use when the user asks to TDD a new feature or write tests first.` |

### git-agent

| File | Optimized description |
|------|----------------------|
| `skills/branch-agent/SKILL.md` | `Creates a branch from origin/<default> with no upstream tracking, auto-naming from uncommitted changes. Use when the user asks to create or start a new branch.` |
| `skills/commit-agent/SKILL.md` ⚠️ ADD field | `Stages all changes and creates a conventional commit message. Use when the user asks to commit changes, stage and commit, or save work to git.` |
| `skills/pr-agent/SKILL.md` ⚠️ ADD field | `Pushes the branch and creates a pull request via gh or glab. Use when the user asks to create a PR, open a pull request, or submit for review.` |
| `skills/ship-autonomous/SKILL.md` | `Chains branch, commit, PR, CI polling, and bounded autofix into one supervised flow. Use when the user asks to autonomously ship or ship and watch CI.` |
| `skills/ship/SKILL.md` | `Stages, commits, pushes, and creates a PR in one flow for GitHub and GitLab. Use when the user asks to ship changes, commit and create a PR, or land their work.` |

### marketplace-builder

| File | Optimized description |
|------|----------------------|
| `skills/building-marketplaces/SKILL.md` | `Evaluates a repository and scaffolds files needed to create a Claude Code plugin marketplace. Use when the user asks to build or scaffold a marketplace.` |

### memory-tools

| File | Optimized description |
|------|----------------------|
| `skills/agentic-memory-doctor/SKILL.md` | `Audits and optimizes CLAUDE.md project memory files against Claude Code best practices. Use when the user asks to audit, optimize, or diagnose a CLAUDE.md.` |
| `skills/path-rules-advisor/SKILL.md` | `Creates path-specific rule files in .claude/rules/ based on project analysis. Use when the user wants to add rules for specific file types or directories.` |

### plan-interview

| File | Optimized description | Body change |
|------|----------------------|-------------|
| `skills/deep-grill/SKILL.md` | `Stress-tests plan decisions node-by-node with focused questions. Use when the user asks to deep grill or stress-test individual decisions in a plan.` | — |
| `skills/documenting-plans/SKILL.md` | `Generates a prose reference doc from a completed plan by inspecting the codebase and git history. Use when the user asks to document a completed plan.` | Add `## When not to use` noting it only runs on plans 30+ days old |
| `skills/markdown-to-html/SKILL.md` | `Converts a markdown file into a rich, self-contained HTML page viewable in any browser. Use when the user asks to convert a markdown file or plan to HTML.` | — |
| `skills/plan-interview/SKILL.md` | `Stress-tests implementation plans through structured interviews to surface gaps and risks. Use when the user asks to stress-test or validate a technical plan.` | Add `## When not to use` noting it is not for product plans or PRDs (use `product-plans:plan-review-agents` for those) |
| `skills/plan-status/SKILL.md` | `Writes lifecycle status and dates into a plan file's frontmatter after inspecting the codebase. Use when the user asks to check or update a plan's status.` | — |
| `skills/plan-to-html/SKILL.md` | `Deprecated alias for markdown-to-html; delegates immediately. Use when the user asks to convert a plan to HTML.` | — |

### product-plans

| File | Optimized description | Body change |
|------|----------------------|-------------|
| `skills/plan-review-agents/SKILL.md` | `Runs a six-role Agent Team to improve PRDs, feature proposals, and product plans in place. Use when the user asks to review or optimize a product plan.` | Add `## When not to use` noting that for technical implementation plan validation before coding, use `plan-interview:plan-interview` instead |

### react-perf-analyzer

| File | Optimized description |
|------|----------------------|
| `skills/react-perf-analyzer/SKILL.md` | `Identifies React patterns correlated with poor INP, CLS, and Long Tasks. Use when the user asks to analyze React performance or produce a performance report.` |

### settings-sync

| File | Optimized description |
|------|----------------------|
| `skills/settings-backup/SKILL.md` | `Backs up Claude Code user settings to a git repo; runs unattended as a routine. Use when the user asks to back up, save, or sync their Claude Code settings.` |
| `skills/settings-restore/SKILL.md` | `Pulls Claude Code settings from a backup git repo and restores them to ~/.claude/ with confirmation. Use when the user asks to restore or import settings.` |

### skill-reviewer

| File | Optimized description |
|------|----------------------|
| `skills/auditing-allowed-tools/SKILL.md` | ✓ Already compliant — no change |
| `skills/optimizing-skill-frontmatter/SKILL.md` | ✓ Already compliant — no change |
| `skills/planning-skills/SKILL.md` | `Walks through a structured workflow to scaffold a new skill with SKILL.md and supporting files. Use when the user asks to plan, design, or scaffold a new skill.` |
| `skills/reviewing-skills/SKILL.md` | `Scores SKILL.md files across 5 quality dimensions against Anthropic's authoring best practices. Use when the user asks to review, audit, or score a skill.` |

### social-media-tools

| File | Optimized description |
|------|----------------------|
| `skills/code-share/SKILL.md` | `Drafts social copy and generates a dark-mode card image for LinkedIn, Twitter/X, or Bluesky. Use when the user asks to create or draft a social media post.` |

### wcag-compliance-reviewer

| File | Optimized description |
|------|----------------------|
| `skills/wcag-compliance-reviewer/SKILL.md` | `Reviews HTML/CSS and React code for WCAG 2.2 Level AA violations and provides fixes. Use when the user asks to check WCAG compliance or audit accessibility.` |

## Files With Special Handling

### Missing `description:` field (commit-agent, pr-agent)
Both `git-agent/skills/commit-agent/SKILL.md` and `git-agent/skills/pr-agent/SKILL.md` lack a `description:` key in frontmatter. The existing text (starting with "Use when...") lives in the YAML block but is not keyed. Add `description:` before the string on the same line.

### Routing clauses to preserve in body
Four files currently embed scope/disambiguation in their descriptions. After trimming, add or extend a `## When not to use` section in each body:

- `plan-interview/skills/plan-interview/SKILL.md` — add: "This skill is for technical implementation plans (files to modify, code to write). For product plans, PRDs, or stakeholder proposals, use `product-plans:plan-review-agents` instead."
- `product-plans/skills/plan-review-agents/SKILL.md` — add: "For quick single-agent technical validation of an implementation plan before coding, use `plan-interview:plan-interview` instead."
- `plan-interview/skills/documenting-plans/SKILL.md` — add: "Only runs on completed plans that are 30+ days old."
- `plan-interview/skills/plan-to-html/SKILL.md` — body already notes deprecation; no additional change needed.

## Verification

1. After all edits, run:
   ```bash
   find kit/plugins -name "SKILL.md" -exec grep -n "^description:" {} +
   ```
   Verify every file has exactly one `description:` line.

2. Check no description exceeds 160 chars:
   ```bash
   find kit/plugins -name "SKILL.md" | while read f; do
     desc=$(grep '^description:' "$f" | sed 's/^description: *"//' | sed 's/"$//')
     len=${#desc}
     if [ "$len" -gt 160 ]; then echo "OVER: $f ($len chars)"; fi
   done
   ```

3. Manually verify two-sentence structure (capability first, trigger second) for the 5 previously-worst offenders:
   - `plan-interview/skills/plan-interview/SKILL.md`
   - `product-plans/skills/plan-review-agents/SKILL.md`
   - `social-media-tools/skills/code-share/SKILL.md`
   - `git-agent/skills/ship-autonomous/SKILL.md`
   - `plan-interview/skills/markdown-to-html/SKILL.md`

4. Commit with message: `fix(kit/plugins): optimize all SKILL.md descriptions to ≤160-char two-sentence format`
