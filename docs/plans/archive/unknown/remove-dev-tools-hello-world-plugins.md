---
title: Remove dev-tools and hello-world plugins
status: completed
---

# Remove dev-tools and hello-world plugins

## Context

Remove two example/reference plugins (`hello-world` and `dev-tools`) from the agentics marketplace. Both are simple demonstration plugins that are no longer needed in the marketplace. All references in documentation and marketplace registration must be cleaned up.

## Files to Delete

- `plugins/hello-world/` — entire directory (6 files)
- `plugins/dev-tools/` — entire directory (5 files)

## Files to Modify

- `.claude-plugin/marketplace.json` — remove both plugin entries; bump marketplace version (MINOR: `2.2.0` → `2.3.0`)
- `CLAUDE.md` — remove both from the **Reference Implementations** section
- `README.md` — remove references in quick start examples and plugin listings
- `plugins/README.md` — remove both plugin entries
- `CHANGELOG.md` (root) — add removal entry
- `.claude/rules/plugin-patterns.md` — remove or redirect line 56 (dead pointer to `plugins/dev-tools/skills/code-review/SKILL.md`)
- `CLAUDE.local.md` — remove `--plugin-dir` commands for both plugins
- `~/.claude/projects/-Users-shawnsandy-devbox-agentics/memory/MEMORY.md` — remove both plugins from "Active Plugins", "Key Commands", and "Detailed Notes"

## Steps

1. Delete `plugins/hello-world/` directory
2. Delete `plugins/dev-tools/` directory
3. Remove `hello-world` and `dev-tools` entries from `.claude-plugin/marketplace.json`
4. Bump marketplace version in `marketplace.json` (MINOR: `2.2.0` → `2.3.0`)
5. Update `CLAUDE.md` — remove both lines from the Reference Implementations table
6. Update root `README.md` — remove hello-world/dev-tools from plugin listings and `--plugin-dir` examples
7. Update `plugins/README.md` — remove both plugin entries
8. Update `.claude/rules/plugin-patterns.md` — remove or redirect line 56 (dead pointer to deleted file)
9. Update `CLAUDE.local.md` — remove `--plugin-dir` commands for both plugins
10. Update `~/.claude/projects/-Users-shawnsandy-devbox-agentics/memory/MEMORY.md` — remove stale plugin references
11. Add a root `CHANGELOG.md` entry noting the removals
12. Commit all changes including this plan file

## Verification

1. Confirm `plugins/hello-world/` and `plugins/dev-tools/` no longer exist
2. `grep -r "hello-world\|dev-tools" .claude-plugin/marketplace.json` returns no results
3. Register the marketplace locally and confirm neither plugin appears in the install list

## Next Steps

- Consider whether `plugins/README.md` still makes sense as a standalone file or can be merged into the root `README.md`

## Unresolved Questions

- Decide what replaces the `plugin-patterns.md` line 56 reference — remove the pointer entirely or redirect to another existing plugin as the progressive disclosure example

## Interview Summary

### Key Decisions Confirmed

- **Version bump**: 2.3.0 MINOR (not 3.0.0 MAJOR) — removal is internal only, no external consumers impacted
- **No consumer impact**: Marketplace is personal/internal use; no downstream users to notify
- **Doc scope**: Update `.claude/rules/plugin-patterns.md` and `CLAUDE.local.md` in addition to the files already listed — promote `CLAUDE.local.md` from "Next Steps" to main steps

### Open Risks & Concerns

- **MEMORY.md not in plan**: `~/.claude/projects/.../memory/MEMORY.md` has stale references to both plugins in "Active Plugins", "Key Commands", and "Detailed Notes" — needs to be added to the plan
- **Broken pointer in plugin-patterns.md**: Line 56 points to `plugins/dev-tools/skills/code-review/SKILL.md` as a reference. After deletion this is a dead link — must remove or redirect before implementation
- **CLAUDE.local.md scope mismatch**: Demoted to "Next Steps" but user confirmed it should be updated — move to main steps
- **Ambiguous doc scope selection**: Selected all options including "None — stick to the plan" — plan must explicitly list every file in scope before implementation begins

### Recommended Plan Amendments

1. Update "Files to Modify" — add `CLAUDE.local.md` and `~/.claude/projects/-Users-shawnsandy-devbox-agentics/memory/MEMORY.md`
2. Change Step 4 version bump from `3.0.0` → `2.3.0`
3. Resolve broken `plugin-patterns.md` pointer — remove line 56 or redirect to another reference implementation
4. Clarify doc scope — explicitly list every file to be modified
