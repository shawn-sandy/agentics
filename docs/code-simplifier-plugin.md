# code-simplifier Plugin

> Introduces the `code-simplifier` plugin — a plan-mode refactoring workflow that identifies structural code smells across nine categories, creates a prioritized refactoring plan with developer approval, and applies the approved changes.

<!-- generated:start -->

**Status:** Shipped 2026-05-07  **Plan:** [code-simplifier-plugin.md](plans/code-simplifier-plugin.md)
**Type:** artifact

## What shipped

- Created `kit/plugins/code-simplifier/skills/code-simplifier/references/smell-checklist.md` — nine-category checklist (Dead Code, Excessive Complexity, God Classes, Duplicated Logic, Coupling & Cohesion, Primitive Obsession, Parameter Lists, Naming, Performance Anti-Patterns) with a four-tier severity rating guide, written first as a skill dependency.
- Created `kit/plugins/code-simplifier/skills/code-simplifier/references/example-analysis.md` — complete sample output demonstrating the smell-specific findings and refactoring suggestions format (mirrors `code-review/references/example-review.md` structure).
- Created `kit/plugins/code-simplifier/skills/code-simplifier/SKILL.md` — seven-step skill with `allowed-tools: AskUserQuestion, Bash, Edit, EnterPlanMode, ExitPlanMode, Glob, Grep, Read, Write`; resolves target files, enters plan mode, analyzes via smell checklist, writes a refactoring plan to the project's plans directory, presents findings, gates on developer approval, then applies or discards changes.
- Created `kit/plugins/code-simplifier/agents/agent-code-simplifier.md` — read-only background agent (`tools: Read, Glob, Grep, Bash`; `disallowedTools: Write, Edit, NotebookEdit`; `model: sonnet`; `permissionMode: plan`; `background: true`) for delegated structural quality analysis from other agents or automated workflows.
- Created `kit/plugins/code-simplifier/.claude-plugin/plugin.json` — manifest with name, description, author, license, keywords, and homepage pointing to `kit/plugins/code-simplifier`; no `version` field (version lives in `marketplace.json`).
- Created `kit/plugins/code-simplifier/README.md` covering purpose, differentiation from `code-review`, skills table, nine smell categories, agent table, and usage examples.
- Created `kit/plugins/code-simplifier/CHANGELOG.md` with initial `[1.0.0] - 2026-04-30` entry.
- Added `code-simplifier` entry to `.claude-plugin/marketplace.json` at version `1.0.0` under the `development` category.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/code-simplifier/skills/code-simplifier/SKILL.md` | Skill instructions | Created |
| `kit/plugins/code-simplifier/skills/code-simplifier/references/smell-checklist.md` | Reference / smell checklist | Created |
| `kit/plugins/code-simplifier/skills/code-simplifier/references/example-analysis.md` | Reference / example output | Created |
| `kit/plugins/code-simplifier/agents/agent-code-simplifier.md` | Agent definition | Created |
| `kit/plugins/code-simplifier/.claude-plugin/plugin.json` | Plugin manifest | Created |
| `kit/plugins/code-simplifier/README.md` | Plugin documentation | Created |
| `kit/plugins/code-simplifier/CHANGELOG.md` | Changelog | Created |
| `.claude-plugin/marketplace.json` | Marketplace entry | Modified |

## How it works

The `code-simplifier` skill fills a gap left by the `code-review` plugin: while `code-review` catches bugs, security issues, and breaking changes, `code-simplifier` targets structural quality problems that accumulate silently — dead code, excessive complexity, god classes, duplicated logic, and performance anti-patterns.

Step 1 resolves target files using the same four-priority order established by the `code-review` skill: explicit path argument, `git status --short` for uncommitted changes, `git diff main...HEAD --name-only` for branch changes, fallback `AskUserQuestion`. Binaries, lock files, and generated files are skipped.

Step 2 calls `EnterPlanMode`, making all subsequent analysis read-only. Step 3 reads `references/smell-checklist.md` and applies each of the nine categories to every target file, recording category, smell name, file:line location, severity (Critical/Moderate/Minor), and confidence level. Only High and Medium confidence findings are kept; Low confidence findings are discarded to reduce noise.

Step 4 writes a refactoring plan to the project's configured plans directory (`docs/plans/` by default, or the path from `.claude/settings.json`). The plan includes a summary, prioritized steps, before/after code examples for the top findings, and estimated effort. Step 5 presents the structured analysis to the user with summary, severity rating, and a link to the plan file.

Step 6 gates on developer approval via `AskUserQuestion` (Approve and apply / Adjust the plan / Discard). Adjustments loop back through presentation; approval or discard proceeds to Step 7. On approval, Step 7 calls `ExitPlanMode` and applies the refactoring steps using `Edit`/`Write`. On discard, the plan file is deleted and plan mode is exited without changes.

The background agent `agent-code-simplifier` provides a read-only analysis path for delegation from other agents or automated post-merge workflows. It is explicitly `disallowedTools: Write, Edit, NotebookEdit` and returns a structured report without any plan mode interaction — the interactive plan-and-apply cycle is reserved for the skill.

## How to use it

```
# Automatic activation — mention smells, complexity, or refactoring
"find code smells in src/utils/"
"simplify this component"
"check for dead code in lib/"

# Agent delegation (from another agent or workflow)
Agent(subagent_type: "code-simplifier:agent-code-simplifier",
      prompt: "Analyze kit/plugins/code-review/ for code smells")
```

After skill activation, the workflow enters plan mode, analyzes the target files, and writes a refactoring plan. The developer reviews the prioritized findings, can request adjustments, and either approves (triggering the apply phase) or discards (cleaning up the plan file with no code changes).

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `44dc02f` | 2026-05-17 | docs(sweep): mark 18 completed plans as artifact and generate initial docs |
| `e33c5fb` | 2026-05-13 | fix(plugins/code-simplifier): document deferred-tool bootstrap for EnterPlanMode |
| `c15082d` | 2026-05-07 | fix(plugins): improve skill activation, discoverability, and README sync (#95) |

<!-- generated:end -->

## References

- Plan: [code-simplifier-plugin.md](plans/code-simplifier-plugin.md)
