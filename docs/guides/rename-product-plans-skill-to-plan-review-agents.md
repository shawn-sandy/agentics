# Rename product-plans skill to plan-review-agents

> MINOR version bump renaming only the `product-plans` skill to `plan-review-agents` within the `product-plans` plugin, updating all downstream skill-invocation references while leaving the plugin folder, plugin name, agents, command, and install path unchanged.

<!-- generated:start -->

**Status:** Shipped 2026-05-15  **Plan:** [rename-product-plans-skill-to-plan-review-agents.md](plans/rename-product-plans-skill-to-plan-review-agents.md)
**Type:** artifact

## What shipped

- Renamed skill directory `kit/plugins/product-plans/skills/product-plans/` → `kit/plugins/product-plans/skills/plan-review-agents/` via `git mv`. New invocation: `product-plans:plan-review-agents`.
- Updated SKILL.md frontmatter: `name: product-plans` → `name: plan-review-agents`. `description:` field left unchanged (activation triggers on intent words, not skill name).
- Updated `agents/agent-product-plans.md` (the orchestrator): changed `Skill(skill: "product-plans:product-plans" …)` → `Skill(skill: "product-plans:plan-review-agents" …)` to keep the `-bg` background flow working after the rename.
- Updated `commands/product-plans-bg.md`: replaced any inline `product-plans:product-plans` skill invocation string with `product-plans:plan-review-agents`.
- Updated all six reviewer agent files (`agents/product-reviewer-*.md`): changed description phrase from "for the product-plans skill" → "for the plan-review-agents skill" (agent `name:` frontmatter left unchanged).
- Updated `kit/plugins/product-plans/README.md`: replaced skill invocation paths and directory tree entries referencing the old skill name; plugin-level references (`product-plans` install command, homepage) left unchanged.
- Added `## 3.1.0 — 2026-05-15` entry to `kit/plugins/product-plans/CHANGELOG.md` including: skill rename note, migration instructions for `settings.local.json` permission entries, and explicit confirmation that plugin name/agent names/command/install command are unchanged.
- Bumped `product-plans` version from `3.0.0` → `3.1.0` in `.claude-plugin/marketplace.json` (MINOR — plugin identity unchanged, only skill activation name changed).
- Updated `.claude/settings.local.json` (gitignored): `Skill(product-plans:product-plans)` → `Skill(product-plans:plan-review-agents)`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/product-plans/skills/plan-review-agents/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/product-plans/skills/plan-review-agents/references/role-prompts.md` | Role spawn-prompt templates | Modified |
| `kit/plugins/product-plans/skills/plan-review-agents/references/output-template.md` | Output report template | Modified |
| `kit/plugins/product-plans/agents/agent-product-plans.md` | Orchestrator agent | Modified |
| `kit/plugins/product-plans/agents/product-reviewer-pm.md` | PM reviewer subagent | Modified |
| `kit/plugins/product-plans/agents/product-reviewer-lead-developer.md` | Lead developer reviewer subagent | Modified |
| `kit/plugins/product-plans/agents/product-reviewer-ux-designer.md` | UX designer reviewer subagent | Modified |
| `kit/plugins/product-plans/agents/product-reviewer-frontend-engineer.md` | Frontend engineer reviewer subagent | Modified |
| `kit/plugins/product-plans/agents/product-reviewer-accessibility-expert.md` | Accessibility expert reviewer subagent | Modified |
| `kit/plugins/product-plans/agents/product-reviewer-security-expert.md` | Security expert reviewer subagent | Modified |
| `kit/plugins/product-plans/commands/product-plans-bg.md` | Command wrapper | Modified |
| `kit/plugins/product-plans/README.md` | Plugin documentation | Modified |
| `kit/plugins/product-plans/CHANGELOG.md` | Version history | Modified |
| `.claude-plugin/marketplace.json` | Marketplace entry | Modified |

## How it works

The `product-plans` plugin ships a single skill that orchestrates a cross-functional Agent Team to review and improve product plans. Before this change, the skill shared its name with the plugin (`product-plans:product-plans`), which was confusing: the namespace and verb were identical. The rename to `plan-review-agents` makes the skill name reflect its function — coordinating reviewer agents to review a plan.

The scope was deliberately minimal. Only the skill itself renames. The plugin folder (`product-plans/`), plugin name in `plugin.json` and `marketplace.json`, all seven agent files, the background command (`product-plans-bg`), the install path, and the homepage URL are all unchanged. This keeps `/plugin install product-plans@agentics-kit` working without re-installation and limits the blast radius of the change.

The rename is classified as MINOR (not MAJOR) because the plugin's external identity is unchanged — users who installed the plugin do not need to uninstall and reinstall. However, any `settings.local.json` file that pre-approved `Skill(product-plans:product-plans)` must be updated to `Skill(product-plans:plan-review-agents)`, otherwise the renamed skill will prompt for permission on every invocation rather than silently failing.

The orchestrator agent (`agent-product-plans.md`) is the critical path for the `/product-plans:product-plans-bg` background command: the command dispatches into `agent-product-plans`, which then calls the skill by name. Without updating the `Skill(...)` invocation inside the orchestrator agent, the background flow would silently break after the skill directory rename — it would try to invoke a skill name that no longer exists. Step 3 of the plan addresses this dependency explicitly.

The six reviewer-agent description updates (changing "for the product-plans skill" to "for the plan-review-agents skill") are a small consistency fix: those descriptions are user-visible discovery copy. After the rename, leaving them referencing the old skill name would be misleading. The agents' own `name:` frontmatter fields (`product-reviewer-pm`, `product-reviewer-lead-developer`, etc.) are unchanged; they use the plugin's existing `product-` naming convention and are out of scope for this plan.

## How to use it

The plugin install command and plugin name are unchanged:

```bash
/plugin install product-plans@agentics-kit
```

After the rename, the skill activates under the new name in tool-use output:

```
product-plans:plan-review-agents
```

The background command is still invoked as before:

```bash
/product-plans:product-plans-bg docs/plans/<plan>.md
```

If you had a pre-approved permission entry in `settings.local.json`, update it:

```json
// Old:
"Skill(product-plans:product-plans)"
// New:
"Skill(product-plans:plan-review-agents)"
```

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `4b11fe6` | 2026-05-15 | fix(kit/plugins/product-plans): assign role-optimized models to reviewer agents (v3.2.1) |
| `bf67a43` | 2026-05-15 | feat(kit/plugins/product-plans): add domain-specific research tools to all six reviewer agents |
| `549b66e` | 2026-05-15 | feat(product-plans): rename skill to plan-review-agents (v3.1.0) (#123) |
| `a5a4b77` | 2026-05-15 | feat(kit/plugins/product-plans)!: v3.0.0 — reframe as plan improvement tool |
| `20281b3` | 2026-05-15 | feat(kit/plugins/product-plans): integrate panel review into source plan |
| `efa1088` | 2026-05-15 | fix(kit/plugins/product-plans): address remaining Copilot review comments |
| `498aca0` | 2026-05-15 | fix(kit/plugins/product-plans): address CodeRabbit review comments |
| `d0a8fa7` | 2026-05-15 | fix(kit/plugins/product-plans): address Codex/Copilot PR #120 review comments |
| `4e656df` | 2026-05-15 | feat(kit/plugins/product-plans): add security-expert reviewer to panel (v2.2.0) |

<!-- generated:end -->

## References

- Plan: [rename-product-plans-skill-to-plan-review-agents.md](plans/rename-product-plans-skill-to-plan-review-agents.md)
