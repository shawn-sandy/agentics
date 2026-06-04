# Rename plugin to memory-tools and skill to memory-doctor (v2.0.0) + 9 fixes

> MAJOR release renaming the `claude-md-optimizer` plugin to `memory-tools` and the `md-optimizer` skill to `memory-doctor`, bundled with nine behavioral improvements including a Grep-based secret scan, AskUserQuestion confirmations, and import-depth analysis.

<!-- generated:start -->

**Status:** Shipped 2026-05-07  **Plan:** [rename-md-optimizer-to-memory-doctor.md](plans/rename-md-optimizer-to-memory-doctor.md)
**Type:** artifact

## What shipped

- Renamed plugin directory `kit/plugins/claude-md-optimizer/` → `kit/plugins/memory-tools/` via `git mv`; updated `plugin.json` (`name`, `homepage` URL) and `marketplace.json` (`name`, `source.path`). New install command: `/plugin install memory-tools@agentics-kit`.
- Renamed skill directory `skills/claude-md-optimizer/` → `skills/memory-doctor/` via `git mv`; updated SKILL.md frontmatter `name: md-optimizer` → `name: memory-doctor`. New invocation: `memory-tools:memory-doctor`.
- Fix 1: Added `Grep` to `allowed-tools`; rewrote Step 2 secret scan to use `Grep -nE` with patterns (`sk-`, `ghp_`, `AKIA`, etc.) and report match line numbers — replacing unreliable eyeball-matching.
- Fix 2: Moved the operational rules paragraph (audit only the specified file; Steps 5 and 6 are opt-in) from `references/audit-steps.md` into the top of SKILL.md so Claude sees them before any Read triggers.
- Fix 3: Extended Step 2 `@import` scan to read each imported file one level deep and report "effective lines (incl. imports): N", with a 500-line soft cap (skip and warn for larger imports).
- Fix 4: Replaced prose yes/no prompts in Steps 5 and 6 with `AskUserQuestion` calls (Generate? Yes/No; Write to disk? Yes/No; Create `.claude/rules/`? Yes/No).
- Fix 5: Added recommendation to invoke sibling `path-rules-advisor` skill when Progressive Disclosure scores ≤ 1, with the inline flow kept as a documented fallback.
- Fix 6: Added plan-mode pre-check — if plan mode is active when reaching Step 5, defer until the user exits.
- Fix 7: Clarified Step 1 priority: when both `CLAUDE.md` and `.claude/CLAUDE.md` exist, audit `CLAUDE.md` (root takes priority) and note the alternate was skipped.
- Fix 8: Tightened frontmatter description to two sentences using "memory" terminology (~180 chars).
- Fix 9: Removed duplicate `CLAUDE.local.md` mention from Dimension 4 in `references/audit-steps.md`; retained only in Dimension 6.
- Updated all repo-wide cross-references from `claude-md-optimizer`/`md-optimizer` to the new names across `marketplace-builder`, `skill-reviewer`, `kit/plugins/README.md`, and root `README.md`.
- Added `## [2.0.0] - 2026-05-04` CHANGELOG entry with prominent BREAKING CHANGE and Migration subsections (uninstall/reinstall steps + grep command for finding stale `@import` references).
- Bumped `agentics-kit` marketplace top-level version from `3.0.0` → `3.1.0` (MINOR — plugin updated, not a marketplace breaking change).

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/memory-tools/.claude-plugin/plugin.json` | Plugin manifest | Modified |
| `kit/plugins/memory-tools/skills/memory-doctor/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/memory-tools/skills/memory-doctor/references/audit-steps.md` | Audit dimension reference | Modified |
| `kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md` | Sibling skill cross-reference | Modified |
| `kit/plugins/memory-tools/README.md` | Plugin documentation | Modified |
| `kit/plugins/memory-tools/CHANGELOG.md` | Version history | Modified |
| `kit/plugins/marketplace-builder/skills/building-marketplaces/SKILL.md` | Cross-plugin reference | Modified |
| `kit/plugins/marketplace-builder/skills/building-marketplaces/references/marketplace-templates.md` | Template reference | Modified |
| `kit/plugins/marketplace-builder/README.md` | Plugin documentation | Modified |
| `kit/plugins/skill-reviewer/README.md` | Cross-plugin reference | Modified |
| `kit/plugins/skill-reviewer/skills/reviewing-skills/references/best-practices.md` | Best-practices reference | Modified |
| `kit/plugins/README.md` | Plugin listing | Modified |
| `README.md` | Root documentation | Modified |
| `.claude-plugin/marketplace.json` | Marketplace entry | Modified |

## How it works

The plugin was originally named `claude-md-optimizer` — a workaround required because the reserved-word rule blocked skill names containing `claude-`. By v1.6.0 the workaround name read as generic markdown tooling rather than CLAUDE.md-specific auditing. Anthropic's official docs use "memory" terminology for CLAUDE.md files, so the rename to `memory-tools` / `memory-doctor` aligns the plugin with the canonical vocabulary users will encounter when reading docs.

Both renames used `git mv` — plugin directory first, then skill subdirectory — so git tracks the rename as a single move rather than a delete+add pair. Content edits followed in subsequent commits to keep the rename diff clean and reviewable.

The behavioral fixes bundled into v2.0.0 address three reliability gaps identified in the audit. The secret scan (Fix 1) was previously performed by eyeball-matching a Read'd file, which silently missed tokens on long CLAUDE.md files. Switching to `Grep -nE` with explicit pattern strings and line-number output makes the scan deterministic and auditable. The `@import` depth analysis (Fix 3) solves an under-counting problem in Dimension 1 (Instruction Budget): a CLAUDE.md that uses `@import` heavily could score deceptively low on line count while actually loading thousands of lines into context.

The `AskUserQuestion` additions (Fix 4) enforce the skill's "opt-in" contract for Steps 5 and 6. Previously those steps asked yes/no questions in prose, which Claude could misread as already-confirmed. Structured `AskUserQuestion` calls make the confirmation gate unambiguous.

The `path-rules-advisor` cross-delegation (Fix 5) eliminates a redundancy: Step 5 previously reimplemented the `.claude/rules/*.md` generation flow that the sibling skill was purpose-built to handle. The new pattern recommends the sibling when the Progressive Disclosure score is low, falling back to the inline flow only when the sibling isn't available.

The CHANGELOG `## [2.0.0]` entry includes an explicit Migration subsection because existing `@import` references pointing at `skills/claude-md-optimizer/SKILL.md` silently 404 after the directory rename. Users can find stale references with `grep -rn 'skills/claude-md-optimizer/SKILL.md' .`.

## How to use it

Install the renamed plugin:

```bash
/plugin install memory-tools@agentics-kit
```

Migrate from the old name:

```bash
/plugin uninstall claude-md-optimizer@agentics-kit
/plugin install memory-tools@agentics-kit
```

Invoke the skill naturally — activation phrases are unchanged:

```
audit my CLAUDE.md
diagnose my project memory
review project instructions
```

Find stale `@import` references after migration:

```bash
grep -rn 'skills/claude-md-optimizer/SKILL.md' .
```

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `c15082d` | 2026-05-07 | fix(plugins): improve skill activation, discoverability, and README sync (#95) |

<!-- generated:end -->

## References

- Plan: [rename-md-optimizer-to-memory-doctor.md](plans/rename-md-optimizer-to-memory-doctor.md)
