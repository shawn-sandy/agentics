# Rename plugin to memory-tools and skill to memory-doctor (v2.0.0) + 9 fixes

> A MAJOR breaking release that renames the `claude-md-optimizer` plugin to `memory-tools` and its primary skill from `md-optimizer` to `memory-doctor`, aligning with Anthropic's official "memory" terminology, while also shipping nine quality improvements to the skill itself.

<!-- generated:start -->

**Status:** Shipped 2026-05-04 **Plan:** [rename-md-optimizer-to-memory-doctor.md](plans/rename-md-optimizer-to-memory-doctor.md)
**Type:** feature

## What shipped

- Renamed the plugin directory `kit/plugins/claude-md-optimizer/` → `kit/plugins/memory-tools/` via `git mv` (preserving history).
- Renamed the primary skill directory `skills/claude-md-optimizer/` → `skills/memory-doctor/` and updated its frontmatter `name` from `md-optimizer` to `memory-doctor`.
- Updated `plugin.json` (`name`, `homepage`), `marketplace.json` (`name`, `source.path`, `version` → `2.0.0`), and the install command to `/plugin install memory-tools@agentics-kit`.
- Fixed secret-scan reliability: added `Grep` to `allowed-tools` and rewrote Step 2 to use `Grep -nE` with specific patterns, reporting match line numbers instead of eyeball-matching.
- Improved `@import` line-count accuracy: Step 2 now reads each imported file (one level deep, soft cap at 500 lines) and adds an "effective lines (incl. imports)" figure to the report.
- Replaced prose yes/no prompts in Steps 5 and 6 with `AskUserQuestion` calls for explicit developer confirmation.
- Added `path-rules-advisor` cross-skill delegation: when Progressive Disclosure scores ≤ 1, the skill recommends invoking the sibling skill instead of reinventing the flow inline.
- Added a plan-mode pre-check at the top of the skill: defers write steps until the user exits plan mode.
- Clarified Step 1 priority for dual-file scenarios (`CLAUDE.md` and `.claude/CLAUDE.md`): root file takes priority, alternate location noted as skipped.
- Tightened frontmatter description to two sentences with "memory" terminology.
- Removed duplicate `CLAUDE.local.md` mention from Dimension 4; retained in Dimension 6 only.
- Updated all repo-wide cross-references from `claude-md-optimizer` / `md-optimizer` to the new names (README files, marketplace-builder skill, skill-reviewer references, root CLAUDE.md).
- Bumped `agentics-kit` marketplace version from `3.0.0` to `3.1.0` (MINOR).

> See [CHANGELOG §2.0.0](../kit/plugins/memory-tools/CHANGELOG.md#200---2026-05-04) for the authoritative feature list and migration steps.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/memory-tools/` | Plugin directory (renamed from `claude-md-optimizer`) | Relocated |
| `kit/plugins/memory-tools/.claude-plugin/plugin.json` | Plugin manifest | Modified |
| `kit/plugins/memory-tools/skills/memory-doctor/SKILL.md` | Skill instructions (renamed from `claude-md-optimizer`) | Relocated + Modified |
| `kit/plugins/memory-tools/skills/memory-doctor/references/audit-steps.md` | Audit reference (path updated) | Modified |
| `kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md` | Sibling skill cross-reference updated | Modified |
| `kit/plugins/memory-tools/README.md` | User-facing documentation | Modified |
| `kit/plugins/memory-tools/CHANGELOG.md` | Release notes | Modified |
| `.claude-plugin/marketplace.json` | Marketplace registry | Modified |
| `kit/plugins/marketplace-builder/skills/building-marketplaces/SKILL.md` | Cross-reference updated | Modified |
| `kit/plugins/skill-reviewer/README.md` | Cross-reference updated | Modified |
| `kit/plugins/README.md` | Plugin table updated | Modified |
| `README.md` | Root README updated | Modified |
| `CLAUDE.md` | Plugin reference table updated | Modified |

## How it works

The rename was driven by two factors: the original name `md-optimizer` was a workaround for the reserved-word rule blocking `claude-*` names, and Anthropic's official docs now use "memory" terminology for CLAUDE.md files. The new pair — `memory-tools` (plugin) and `memory-doctor` (skill) — improves discoverability and aligns with the official vocabulary.

The rename was executed as `git mv` operations to preserve commit history. Content edits followed in subsequent commits to keep the rename diff clean. A comprehensive `grep -rn` pass identified all cross-references (excluding historical CHANGELOG entries and the intentional reserved-word example in `best-practices.md`), which were updated in the same release.

The nine quality fixes addressed the highest-impact issues from a skill audit. The secret-scan fix (adding `Grep`) is the most operationally significant: eyeball-matching long CLAUDE.md files for tokens like `sk-`, `ghp_`, `AKIA` is unreliable; `Grep -nE` with exact patterns and line numbers is not. The `AskUserQuestion` fixes close an ambiguity where Claude could misread prose yes/no prompts as already-confirmed.

The `path-rules-advisor` delegation recommendation (Fix 5) avoids reimplementing rule-file generation inline when the sibling skill does it better; the inline path is kept as a documented fallback.

Migration for existing users requires uninstalling the old plugin and reinstalling under the new name. Any `@import` references to `skills/claude-md-optimizer/SKILL.md` in a user's CLAUDE.md will silently break and must be updated to `skills/memory-doctor/SKILL.md`.

## How to use it

**New installation:**

```bash
/plugin marketplace add shawn-sandy/agentics
/plugin install memory-tools@agentics-kit
```

**Migration from `claude-md-optimizer`:**

```bash
/plugin uninstall claude-md-optimizer@agentics-kit
/plugin install memory-tools@agentics-kit
```

Then update any `@import` references in your CLAUDE.md:
- Old path: `@<plugin-dir>/skills/claude-md-optimizer/SKILL.md`
- New path: `@<plugin-dir>/skills/memory-doctor/SKILL.md`

Find references with: `grep -rn 'skills/claude-md-optimizer/SKILL.md' .`

**Activation (unchanged):**

The `memory-doctor` skill activates when you ask to audit, optimize, clean up, or diagnose a CLAUDE.md / project memory file, or when Claude appears to ignore project instructions.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `c2b37fb` | 2026-05-04 | feat(kit/plugins/memory-tools)!: 2.0.0 — rename plugin to memory-tools, skill to memory-doctor |
| `ba486a7` | 2026-05-04 | fix(pr-91): address CodeRabbit and Copilot review comments |
| `f820476` | 2026-05-04 | fix(pr-91): address second round of CodeRabbit review comments |
| `9be3e28` | 2026-05-04 | fix(pr-91): address Copilot and third CodeRabbit round of comments |
| `c997216` | 2026-05-04 | fix(pr-91): address Copilot suppressed comments (fourth round) |
| `c15082d` | 2026-05-07 | fix(plugins): improve skill activation, discoverability, and README sync (#95) |

<!-- generated:end -->

## References

- Plan: [rename-md-optimizer-to-memory-doctor.md](plans/rename-md-optimizer-to-memory-doctor.md)
- Changelog: [memory-tools CHANGELOG §2.0.0](../kit/plugins/memory-tools/CHANGELOG.md)
- Related docs: [audit-claude-md-optimizer-skill.md](audit-claude-md-optimizer-skill.md) · [enhance-claude-md-optimizer-path-rules.md](enhance-claude-md-optimizer-path-rules.md)
