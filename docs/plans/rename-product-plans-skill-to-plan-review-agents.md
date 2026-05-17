---
status: completed
type: artifact
created: 2026-05-15
---

# Plan: Rename product-plans skill to plan-review-agents

## Context

The `product-plans` plugin (v3.0.0) ships a single skill currently also named `product-plans`. The skill name no longer matches what the skill does: it's a coordinated panel of cross-functional reviewer agents that review and improve a plan. The user wants ONLY the skill renamed — to `plan-review-agents` — so the skill's name reflects its function. The plugin folder, plugin name, marketplace entry, command, orchestrator, and 6 reviewer agents all keep their current `product-plans` / `product-reviewer-*` / `agent-product-plans` / `product-plans-bg` names.

After this change, the skill invocation reads `product-plans:plan-review-agents` — namespace (plugin) + verb (skill).

Decisions locked in by the user (across multiple rounds of clarification):

- **Scope:** SKILL ONLY. Plugin folder, plugin name, marketplace.json name/path, all 7 agents, and the command stay as-is. Only the skill rename and its downstream references (skill invocation strings, frontmatter, agent descriptions that reference the skill name) change.
- **Version bump:** MINOR — `3.0.0` → `3.1.0`. The plugin identifier itself is unchanged so `/plugin install` keeps working; only the skill activation name changes, which is internal to the plugin's surface.

## Objective

Rename the skill from `product-plans` to `plan-review-agents`, update every place that names the skill (skill folder, SKILL.md frontmatter, the orchestrator agent's `Skill(...)` invocation, the background command's skill invocation, reviewer-agent descriptions, README, CHANGELOG, settings.local.json), and bump the plugin to v3.1.0.

## Name Map (single source of truth for the rename)

| Kind | Old | New |
|---|---|---|
| Plugin folder | `kit/plugins/product-plans/` | unchanged |
| Plugin name (`plugin.json`, `marketplace.json`) | `product-plans` | unchanged |
| Skill folder | `kit/plugins/product-plans/skills/product-plans/` | `kit/plugins/product-plans/skills/plan-review-agents/` |
| Skill name (`SKILL.md` frontmatter) | `product-plans` | `plan-review-agents` |
| Skill invocation string | `product-plans:product-plans` | `product-plans:plan-review-agents` |
| Orchestrator agent name + file | `agent-product-plans` | unchanged |
| 6 reviewer agent names + files | `product-reviewer-<role>` | unchanged |
| Reviewer-agent description phrase | "for the product-plans skill" | "for the plan-review-agents skill" |
| Command file + name + invocation | `product-plans-bg` / `/product-plans:product-plans-bg` | unchanged |
| Homepage URL | `.../tree/main/kit/plugins/product-plans` | unchanged |
| Plugin version | `3.0.0` | `3.1.0` |

## Steps

1. **Rename the skill folder with `git mv`**: `git mv kit/plugins/product-plans/skills/product-plans kit/plugins/product-plans/skills/plan-review-agents`. — *Why:* the skill's directory name must match its `name:` frontmatter for Claude Code to resolve `product-plans:plan-review-agents`. *Verify:* `ls kit/plugins/product-plans/skills/` returns only `plan-review-agents/`; the directory still contains `SKILL.md` and `references/`.

2. **Edit `kit/plugins/product-plans/skills/plan-review-agents/SKILL.md` frontmatter**: change `name: product-plans` → `name: plan-review-agents`. Leave the `description:` field unchanged (per earlier interview decision — activation triggers on intent words, not the skill's own name). The body of SKILL.md doesn't reference its own skill name in invocation strings, but verify the spawn list still uses `product-reviewer-<role>` agent names (those are unchanged in this scope). — *Why:* the `name:` field is the canonical skill identifier; Claude Code resolves `product-plans:plan-review-agents` by matching the plugin folder name and this field. *Verify:* `grep -nE "^name:" kit/plugins/product-plans/skills/plan-review-agents/SKILL.md` returns exactly `name: plan-review-agents`. `grep -n "name: product-plans" kit/plugins/product-plans/skills/plan-review-agents/SKILL.md` returns nothing.

3. **Edit `kit/plugins/product-plans/agents/agent-product-plans.md`** (the orchestrator): change the `Skill(skill: "product-plans:product-plans" …)` invocation to `Skill(skill: "product-plans:plan-review-agents" …)`. Leave the agent's own `name:` frontmatter (`agent-product-plans`) alone — it isn't renaming. — *Why:* the orchestrator agent is what `/product-plans:product-plans-bg` dispatches into background; if its skill invocation still names the old skill, the `-bg` flow silently breaks after step 2. *Verify:* `grep -n "product-plans:product-plans" kit/plugins/product-plans/agents/agent-product-plans.md` returns nothing; `grep -n "product-plans:plan-review-agents" kit/plugins/product-plans/agents/agent-product-plans.md` returns at least one line.

4. **Edit `kit/plugins/product-plans/commands/product-plans-bg.md`**: update any inline `Skill(skill: "product-plans:product-plans" …)` invocation in the command body to `Skill(skill: "product-plans:plan-review-agents" …)`. Leave the command's own filename and frontmatter alone. — *Why:* if the command invokes the skill directly (rather than via the orchestrator agent), the skill name string must be current. *Verify:* `grep -n "product-plans:product-plans" kit/plugins/product-plans/commands/product-plans-bg.md` returns nothing.

5. **Edit each of the 6 reviewer agent files** (`kit/plugins/product-plans/agents/product-reviewer-*.md`): update the `description:` line so the phrase "for the product-plans skill" becomes "for the plan-review-agents skill". Leave `name:` frontmatter alone (agent names are unchanged in this scope). — *Why:* the description is user-visible discovery copy; after the skill rename the old phrase becomes misleading (the skill no longer exists by that name). *Verify:* `grep -nE "for the product-plans skill" kit/plugins/product-plans/agents/product-reviewer-*.md` returns nothing; `grep -nE "for the plan-review-agents skill" kit/plugins/product-plans/agents/product-reviewer-*.md` returns 6 lines (one per reviewer).

6. **Edit `kit/plugins/product-plans/README.md`**: update any reference to the skill named `product-plans` (skill invocation paths, directory tree showing `skills/product-plans/`, usage examples). Leave references to the *plugin* `product-plans` (install commands, homepage, plugin name) alone — those don't change. — *Why:* README's directory tree and invocation examples are the most-copied parts; mismatched skill names cause user confusion. *Verify:* `grep -n "skills/product-plans" kit/plugins/product-plans/README.md` returns nothing; `grep -n "product-plans:product-plans" kit/plugins/product-plans/README.md` returns nothing; `grep -n "product-plans:plan-review-agents" kit/plugins/product-plans/README.md` returns at least one line.

7. **Edit `kit/plugins/product-plans/CHANGELOG.md`**: add a new `## 3.1.0 — 2026-05-15` entry at the top noting the skill rename. The entry must include: (a) the new skill name `plan-review-agents`; (b) a "Migration for existing installers" subsection saying any `.claude/settings.local.json` entries containing `Skill(product-plans:product-plans)` must be re-keyed to `Skill(product-plans:plan-review-agents)`; (c) a note that the plugin name, agent names, command name, and install command are unchanged. — *Why:* changelog documents the version bump and tells installers exactly what they need to change locally; without this, the renamed skill silently prompts for permission on every invocation. *Verify:* the new 3.1.0 entry appears above 3.0.0 and includes the three points above.

8. **Edit `.claude-plugin/marketplace.json`**: bump the product-plans entry's `version` from `"3.0.0"` to `"3.1.0"`. Leave `name`, `source.path`, `description`, `category`, and `tags` unchanged. — *Why:* this is the only marketplace-level change because nothing else about the plugin's identity changed. *Verify:* `jq '.plugins[] | select(.name=="product-plans") | .version' .claude-plugin/marketplace.json` returns `"3.1.0"`.

9. **Edit `.claude/settings.local.json`**: update the permission entry `Skill(product-plans:product-plans)` → `Skill(product-plans:plan-review-agents)`. Leave any `jq` examples that filter on `select(.name=="product-plans")` alone (the plugin name is unchanged). — *Why:* the local settings file gates which Skill invocations are pre-approved; without this update, the renamed skill prompts for permission on every invocation. *Verify:* `grep -n "product-plans:product-plans" .claude/settings.local.json` returns nothing; `grep -n "product-plans:plan-review-agents" .claude/settings.local.json` returns at least one line.

10. **Final scoped grep** for any straggler references to the old skill invocation or skill folder path within tracked working files (exclude `docs/plans/` historical artifacts and CHANGELOG history entries before 3.1.0): `git grep -nE "product-plans:product-plans|skills/product-plans" -- ':!docs/plans' ':!kit/plugins/product-plans/CHANGELOG.md'`. — *Why:* catches anything missed by the targeted edits in steps 2–9. Note: we deliberately do NOT grep for the bare string `product-plans` because the plugin name itself remains and would create false positives. *Verify:* command returns no lines, or only intentional historical references in files the user explicitly asked to preserve.

11. **Stage and commit as a single atomic commit** including the plan file itself, per repo policy (`CLAUDE.md`: "Always include the plan file in commits for plugin changes"). Use a conventional-commit message of the form `feat(kit/plugins/product-plans): rename skill to plan-review-agents (v3.1.0)` with a body that explains the skill rename and includes the settings.local.json migration note from the CHANGELOG. — *Why:* one commit captures the entire change so reviewers see the full picture and `git bisect` lands on a working state. This is a `feat` (not `feat!`) because the plugin's external surface (install command, plugin name) is unchanged — only the skill activation name changes, which existing skill permission entries will gracefully fail-open from (they'll prompt) rather than silently break. *Verify:* `git log -1 --stat` shows a single commit touching the renamed skill folder (R100), the plan file, marketplace.json, CHANGELOG, and the 6 reviewer agent files. `.claude/settings.local.json` is NOT in the commit (it's gitignored — expected). `git status` is clean afterward.

## Verification

End-to-end confirmation that the rename is complete and the plugin still works:

1. **Plugin install still resolves under the same name** — `/plugin marketplace add ~/devbox/agentics` then `/plugin install product-plans@agentics-kit` succeeds. The install command and plugin name are unchanged.
2. **Skill activates under the NEW name** — In a fresh Claude Code session with the plugin loaded, ask: "Improve the plan at `docs/plans/<any-existing-plan>.md`". The `plan-review-agents` skill activates (visible in tool-use output as `product-plans:plan-review-agents`), spawns all 6 reviewer agents in parallel, and produces the consolidated report writing back to the source plan.
3. **Background command works** — Run `/product-plans:product-plans-bg docs/plans/<plan>.md`. The `agent-product-plans` orchestrator dispatches in the background and the renamed skill runs without permission prompts (settings.local.json was updated in step 9).
4. **No old skill references remain in live files** — `git grep -nE "product-plans:product-plans|skills/product-plans" -- ':!docs/plans' ':!kit/plugins/product-plans/CHANGELOG.md'` returns nothing.
5. **Plugin manifest version bumped** — `jq '.plugins[] | select(.name=="product-plans") | .version' .claude-plugin/marketplace.json` returns `"3.1.0"`; SKILL.md frontmatter `name:` returns `plan-review-agents`.

## Next Steps *(optional)*

- **Audit reviewer-agent descriptions for further freshness**:

  ```text
  In /Users/shawnsandy/devbox/agentics, the product-plans plugin's
  six reviewer agents (product-reviewer-pm, -lead-developer,
  -ux-designer, -frontend-engineer, -accessibility-expert,
  -security-expert) had only the phrase "for the product-plans skill"
  updated to "for the plan-review-agents skill" during the v3.1.0
  rename. Review each agent's full description and recommend any
  further wording improvements that would aid discovery, without
  renaming the agents themselves. Report a diff per file.
  ```

- **Plan the agent rename for a future major version**:

  ```text
  In /Users/shawnsandy/devbox/agentics, the v3.1.0 rename touched only
  the skill name (product-plans → plan-review-agents). The 7 agents
  (agent-product-plans + six product-reviewer-*) still use the old
  "product-" prefix, which is now inconsistent with the skill's
  plan-review-agents name. Draft a follow-up plan for a v4.0.0
  rename that brings the agents in line: agent-product-plans →
  agent-plan-review, product-reviewer-<role> → plan-reviewer-<role>.
  Include the migration steps for settings.local.json permission
  entries that name those agents.
  ```

## Unresolved Questions *(optional — omit if none)*

- **Future agent-name alignment**:

  ```text
  After v3.1.0 the plugin has a "plan-review-agents" skill but its
  reviewer agents are still named product-reviewer-*. Is this
  asymmetry acceptable indefinitely, or should it be scheduled for
  a v4.0.0 cleanup? Recommend one path with reasoning. The current
  state is functional but reads inconsistently in agent dispatch
  logs and README copy.
  ```

## Interview Summary

Stress-tested via `/plan-interview:plan-interview` on 2026-05-15. The plan went through three rounds of scope refinement before settling on the final form:

1. **Initial scope:** rename whole plugin to `plan-review` (string-rename-everything across plugin, skill, agents, command).
2. **Second scope:** rename whole plugin to `plan-review-agents`.
3. **Third scope:** split into domain container `plan-agents` (plugin) + action `plan-review` (skill), enabling future siblings like `plan-cost`, `plan-builder`.
4. **Final scope (current):** SKILL ONLY rename to `plan-review-agents`. Plugin folder, plugin name, all 7 agents, command, install path remain `product-plans` / `product-reviewer-*` / `agent-product-plans` / `product-plans-bg`. Minimal blast radius; defers the broader agent/plugin rename to a separate future plan.

### Key Decisions Confirmed

- **Skill-only scope:** Only the skill renames. Everything else (folder, plugin name, agents, command, install command) stays as `product-plans`.
- **Version bump:** MINOR (`3.0.0` → `3.1.0`). Plugin identity unchanged so `/plugin install product-plans@agentics-kit` keeps working; only the skill activation name changes.
- **Commit shape:** ONE atomic commit (step 11). `feat`, not `feat!`, because the plugin's external surface is unchanged.
- **`settings.local.json`:** Step 9 updates the gitignored permission entry; CHANGELOG calls this out for other installers.
- **Skill description phrasing:** unchanged. Activation triggers on intent words, not the skill's name.
- **Reviewer-agent descriptions:** the phrase "for the product-plans skill" is updated to "for the plan-review-agents skill" (in scope as a small consistency fix; doesn't rename the agents themselves).

### Plan Naming

| Element | Current | Issue | Suggested | Status |
|---|---|---|---|---|
| Filename | `rename-the-product-plans-skills-atomic-conway.md` | Trailing `atomic-conway` is random/unrelated | `rename-product-plans-skill-to-plan-review-agents.md` | User accepted earlier filename rename in spirit — deferred to post-approval (plan-mode restriction). Final suggestion updated to reflect skill-only scope. |
| H1 | `# Plan: Rename product-plans skill to plan-review-agents` | Pass | *(no change)* | Pass |

### Open Risks

- **Naming asymmetry within the plugin.** After v3.1.0 the skill is `plan-review-agents` but the 7 agents are still `product-reviewer-*` / `agent-product-plans`. This is intentional (minimal scope) but is logged in the Unresolved Question for a future cleanup decision.
- **Permission failure-open behavior.** If a user's `settings.local.json` still has `Skill(product-plans:product-plans)` and they invoke the renamed skill, Claude Code prompts for permission rather than silently failing. The CHANGELOG migration note handles this for known installers.

### Amendments Applied (folded into the plan above)

- **Step 10:** scoped grep explicitly excludes the bare `product-plans` string (which intentionally remains as the plugin name) to avoid false positives.
- **Step 11:** commit message uses `feat:` not `feat!:` because the plugin's external surface is unchanged.
- **Step 7 CHANGELOG:** must explicitly note that plugin name, agent names, command name, and install command are unchanged (so installers don't accidentally rename more than needed).

### Simplification Opportunities

None. The plan is already at minimum scope after iteration; further reduction would skip the reviewer-agent description fix (step 5), which would leave user-visible copy lying about the skill name.
