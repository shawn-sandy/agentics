# code-simplifier Plugin

> A new marketplace plugin that analyzes code for structural quality problems — dead code, excessive complexity, god classes, duplicated logic — and applies a developer-approved refactoring plan.

<!-- generated:start -->

**Status:** Shipped 2026-04-30 **Plan:** [code-simplifier-plugin.md](plans/code-simplifier-plugin.md)
**Type:** feature

## What shipped

- Created the `code-simplifier` plugin at `kit/plugins/code-simplifier/` with an initial release at v1.0.0.
- Shipped a `code-simplifier` skill with a seven-step plan-mode refactoring workflow: resolve target files → enter plan mode → analyze code smells → create a refactoring plan → present findings → review with developer → apply approved changes.
- Shipped an `agent-code-simplifier` background agent for delegated structural analysis from other agents or automated workflows (read-only, returns a structured report).
- Included a nine-category smell checklist (`references/smell-checklist.md`) covering dead code, excessive complexity, god classes, duplicated logic, coupling/cohesion, primitive obsession, parameter lists, naming, and performance anti-patterns.
- Registered the plugin in `.claude-plugin/marketplace.json` under the `development` category.

> See [CHANGELOG §1.0.0](../kit/plugins/code-simplifier/CHANGELOG.md#100---2026-04-30) for the authoritative feature list.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/code-simplifier/skills/code-simplifier/SKILL.md` | Skill instructions | Created |
| `kit/plugins/code-simplifier/skills/code-simplifier/references/smell-checklist.md` | Nine-category smell checklist reference | Created |
| `kit/plugins/code-simplifier/skills/code-simplifier/references/example-analysis.md` | Sample analysis output | Created |
| `kit/plugins/code-simplifier/agents/agent-code-simplifier.md` | Background agent definition | Created |
| `kit/plugins/code-simplifier/.claude-plugin/plugin.json` | Plugin manifest | Created |
| `kit/plugins/code-simplifier/README.md` | User-facing documentation | Created |
| `kit/plugins/code-simplifier/CHANGELOG.md` | Release notes | Created |
| `.claude-plugin/marketplace.json` | Marketplace registry | Modified |

## How it works

The `code-simplifier` skill activates when a user asks to find code smells, reduce complexity, simplify code, identify refactoring opportunities, or clean up messy code. It intentionally does not overlap with the `code-review` plugin, which focuses on bugs, security, and breaking changes.

On activation the skill enters plan mode via `EnterPlanMode`, then reads `references/smell-checklist.md` to apply a consistent nine-category analysis against each target file. Only findings with High or Medium confidence are retained; Low-confidence findings are discarded to avoid noise. The severity rating system classifies results as Clean / Minor Issues / Needs Refactoring / Major Refactoring Needed.

The skill resolves target files by priority: explicit path in the user message → `git status --short` (uncommitted changes) → `git diff main...HEAD --name-only` (branch delta) → `AskUserQuestion` fallback. Binaries, lock files, and generated files are excluded.

After analysis, the skill writes a prioritized refactoring plan to the project's plans directory (resolved from `.claude/settings.json` `plansDirectory`, falling back to `docs/plans/`). It then presents structured findings and asks the developer — via `AskUserQuestion` — whether to approve and apply, adjust, or discard. If approved, the skill calls `ExitPlanMode` and applies the changes via `Edit`/`Write`. If discarded, the plan file is deleted and no changes are made.

The `agent-code-simplifier` agent is read-only (`disallowedTools: Write, Edit, NotebookEdit`) and runs in the background (`background: true`). It is intended for delegation from orchestrating agents or automated sweep workflows rather than direct user invocation.

## How to use it

**Automatic activation (skill):**

The `code-simplifier` skill activates automatically when your intent matches:

> Analyzes code for structural quality issues, code smells, and optimization opportunities. Use when the user asks to simplify code, find code smells, reduce complexity, identify refactoring opportunities, check for dead code, clean up messy code, or optimize structure.

Example phrases:
- "Find code smells in `src/utils/`"
- "Simplify `components/Dashboard.tsx`"
- "Check `lib/api/` for dead code"

**Agent delegation:**

```javascript
Agent({
  subagent_type: "code-simplifier:agent-code-simplifier",
  prompt: "Analyze kit/plugins/code-review/ for structural quality issues"
})
```

**Installation:**

```bash
/plugin marketplace add shawn-sandy/agentics
/plugin install code-simplifier@agentics-kit
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `bedb42d` | 2026-04-30 | feat(kit/plugins/code-simplifier): add code-smell analysis plugin (v1.0.0) |
| `f88cd82` | 2026-04-30 | fix(kit/plugins/code-simplifier): address PR review feedback |
| `c15082d` | 2026-05-07 | fix(plugins): improve skill activation, discoverability, and README sync (#95) |

<!-- generated:end -->

## References

- Plan: [code-simplifier-plugin.md](plans/code-simplifier-plugin.md)
- Changelog: [code-simplifier CHANGELOG §1.0.0](../kit/plugins/code-simplifier/CHANGELOG.md)
- Related docs: [create-tdd-loop-skill.md](create-tdd-loop-skill.md)
