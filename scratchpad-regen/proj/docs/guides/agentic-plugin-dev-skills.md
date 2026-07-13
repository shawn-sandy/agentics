# `agentic-plugin-dev` Plugin — Create & Manage Plugins

> New plugin providing three skills for plugin-level authoring workflows: `plugin-creator` (scaffold full plugins), `plugin-manager` (manage marketplace entries), and `plugin-validator` (validate plugin structure against the official spec).

<!-- generated:start -->

**Status:** Shipped 2026-03-13   **Plan:** [agentic-plugin-dev-skills.md](plans/agentic-plugin-dev-skills.md)   **Type:** standard

## What shipped

- New `agentic-plugin-dev` plugin with three skills at `kit/plugins/agentic-plugin-dev/`.
- `plugin-creator`: sequential rigid skill — disambiguation check, gather requirements, generate plugin.json, confirm full file list, write files sequentially (with partial-failure reporting), optionally register in marketplace with name-collision check.
- `plugin-manager`: adaptive flexible skill — locate marketplace.json (CWD only), support list/add/remove/update/bump-version operations; version bumps update CHANGELOG.md and suggest a conventional commit message (no git operations performed).
- `plugin-validator`: sequential rigid skill — structural scan, manifest validation, component validation, PASS/FAIL report with ERROR/WARNING/INFO severity. Cross-checks marketplace source paths when marketplace.json exists.
- Reference files: `plugin-json-schema.md`, `component-templates.md`, `marketplace-schema.md`, `validation-rules.md` — all lean checklists (field + required/optional + constraint) with optional live-fetch mode.
- Plugin registered in `.claude-plugin/marketplace.json` at `v1.0.0`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/agentic-plugin-dev/skills/plugin-creator/SKILL.md` | Skill instructions — plugin-creator | Created |
| `kit/plugins/agentic-plugin-dev/skills/plugin-creator/references/plugin-json-schema.md` | plugin.json schema reference | Created |
| `kit/plugins/agentic-plugin-dev/skills/plugin-creator/references/component-templates.md` | Starter templates for all component types | Created |
| `kit/plugins/agentic-plugin-dev/skills/plugin-manager/SKILL.md` | Skill instructions — plugin-manager | Created |
| `kit/plugins/agentic-plugin-dev/skills/plugin-manager/references/marketplace-schema.md` | marketplace.json schema + version bump rules | Created |
| `kit/plugins/agentic-plugin-dev/skills/plugin-validator/SKILL.md` | Skill instructions — plugin-validator | Created |
| `kit/plugins/agentic-plugin-dev/skills/plugin-validator/references/validation-rules.md` | Validation rule IDs + severity + fix guidance | Created |
| `kit/plugins/agentic-plugin-dev/.claude-plugin/plugin.json` | Plugin manifest | Created |
| `kit/plugins/agentic-plugin-dev/README.md` | Plugin documentation | Created |
| `kit/plugins/agentic-plugin-dev/CHANGELOG.md` | Version history | Created |
| `.claude-plugin/marketplace.json` | Marketplace registry — new plugin entry | Modified |

## How it works

**plugin-creator** starts with a disambiguation check — if the user says something like "scaffold a skill", it asks whether they mean a full plugin or just a component (redirecting to `skill-reviewer` or `agent-creator` if appropriate). After gathering requirements it generates `plugin.json` first for user confirmation, then shows the complete file list before writing. Files are written one at a time with partial-failure reporting. Marketplace registration checks both marketplace name and plugin name uniqueness before adding an entry. Undo guidance is provided: users can delete the generated directory or `git checkout` to revert.

**plugin-manager** locates `marketplace.json` in the current working directory only — it does not traverse parent directories. If not found, it prompts the user for the path. Version bumps use semver (patch/minor/major), update CHANGELOG.md using Keep a Changelog format, and suggest a conventional commit message — they do not stage or commit files. JSON validity is checked after every write operation.

**plugin-validator** runs five validation stages: structural scan (inventories all component directories, flags components inside `.claude-plugin/`), manifest validation (name kebab-case, description present, no version conflicts), component validation (frontmatter correctness for SKILL.md, COMMAND.md, agent files), marketplace source path cross-check (when marketplace.json exists, verifies the source path resolves to the validated plugin directory), and a final report table with PASS/FAIL and severity ratings.

## How to use it

**Skill activations:**
- "create a new plugin called X" → `plugin-creator`
- "list all marketplace plugins", "bump the X plugin version" → `plugin-manager`
- "validate the X plugin", "check if my plugin is valid" → `plugin-validator`

```bash
claude --plugin-dir ./kit/plugins/agentic-plugin-dev
```

Or install from marketplace:
```
/plugin install agentic-plugin-dev@agentics-kit
```

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `9c70a52` | 2026-03-30 | chore(docs/plans): add YAML frontmatter status to 83 plan files |
| `e15fba2` | 2026-04-04 | refactor: rename agentics/ marketplace subtree to kit/ |
| `154adb7` | 2026-04-09 | feat(kit/plugins): declare allowed-tools on unrestricted marketplace skills |
| `9924d3f` | 2026-04-09 | refactor(kit/plugins): trim allowed-tools to only tools each skill actually uses |
| `f2362cc` | 2026-04-11 | fix(kit): trim unused allowed-tools and add argument-hint |

<!-- generated:end -->

## References

- Plan: [agentic-plugin-dev-skills.md](plans/agentic-plugin-dev-skills.md)
