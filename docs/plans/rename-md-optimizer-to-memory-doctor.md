
# Plan: Rename plugin to memory-tools and skill to memory-doctor (v2.0.0) + 9 fixes

## Context

Audit the `claude-md-optimizer` plugin and skill against `.claude/rules/skill-authoring.md` and Anthropic's skill best-practices checklist. Identify concrete optimizations and rename **both the plugin** (`claude-md-optimizer` → `memory-tools`) **and the primary skill** (`md-optimizer` → `memory-doctor`) to use Anthropic's official "memory" terminology for CLAUDE.md files.

The skill is mature (v1.6.0) and already follows progressive disclosure correctly. The current name `md-optimizer` is a workaround forced by the reserved-word rule blocking "claude-*". A more descriptive plugin/skill pair improves discoverability and aligns with the official docs at <https://code.claude.com/docs/en/memory>.

This is a **MAJOR breaking change** (`v1.6.0` → `v2.0.0`) per `.claude/rules/marketplace.md`. Both the plugin name and skill name change in the same release.

## Findings summary

### What's working well

- Three-level progressive disclosure (description → 6 steps → references file) is properly applied.
- `allowed-tools` is explicitly declared and minimally scoped.
- "Freedom level: Rigid" sets clear operational expectations.
- Frontmatter description includes a scope boundary ("Does not cover SKILL.md files, plugin commands…").
- SKILL.md body (157 lines) is well under the 500-line ceiling.

### Optimization opportunities (ranked by impact)

#### Headline changes (drive MAJOR bump)

1. **Rename plugin `claude-md-optimizer` → `memory-tools`.**
   - Plugin contains two skills (`memory-doctor` and `path-rules-advisor`), both centered on Claude memory tooling. New name reflects that scope.
   - **Fix:** (a) Rename plugin directory `kit/plugins/claude-md-optimizer/` → `kit/plugins/memory-tools/`. (b) Update `plugin.json` `name` and `homepage` URL. (c) Update `marketplace.json` plugin entry: `name`, `source.path`. (d) Update install command to `/plugin install memory-tools@agentics-kit`.

2. **Rename skill `md-optimizer` → `memory-doctor`.**
   - Current name is a workaround (reserved-word rule blocks `claude-*`). It reads as generic markdown tooling rather than CLAUDE.md-specific.
   - **Fix:** (a) Rename frontmatter `name: md-optimizer` → `name: memory-doctor`. (b) Rename skill directory `skills/claude-md-optimizer/` → `skills/memory-doctor/` (within the renamed plugin directory). (c) New invocation path: `memory-tools:memory-doctor`.

#### High impact

1. **Step 2 secret scan is unreliable without `Grep`.**
   - `allowed-tools` excludes `Grep`, so Claude must scan a Read'd file by eye for `sk-`, `ghp_`, `AKIA`, etc.
   - On long CLAUDE.md files, eyeball-matching misses tokens — the audit could falsely report "no secrets found."
   - **Fix:** Add `Grep` to `allowed-tools` and restructure Step 2 to use `Grep -n` with the listed patterns. Report match line numbers.

2. **Critical operational rules are buried in `references/audit-steps.md`.**
   - The Notes section (lines 137–143 of `audit-steps.md`) contains load-bearing rules: "Audit only the file specified. Do not scan the entire project. Steps 5 and 6 are opt-in." These belong in the main SKILL.md so Claude sees them before Step 3 triggers a Read.
   - **Fix:** Move that one paragraph back into SKILL.md (top, after the Freedom level callout). Keep dimension scoring + example in references.

3. **Step 2 `@import` scan is shallow — does not recursively measure imported content.**
   - The skill counts visible lines but flags imports without measuring their effective context cost.
   - This causes Dimension 1 (Instruction Budget) to under-count when CLAUDE.md uses `@imports` heavily.
   - **Fix:** After listing imports, optionally `Read` each `@imported` file and add its line count to the report as "effective lines (incl. imports): N." Note this is approximate (recursive imports not followed beyond one level).

#### Medium impact

1. **Step 5 / Step 6 confirmations should use `AskUserQuestion`.**
   - `AskUserQuestion` is already in `allowed-tools` but is unused. Steps 5 and 6 ask yes/no questions in prose, which can be misread by Claude as already-confirmed.
   - **Fix:** Replace each yes/no prompt in Steps 5 and 6 with an `AskUserQuestion` call (Generate? Yes/No; Write to disk? Yes/No; Create `.claude/rules/`? Yes/No).

2. **Cross-skill delegation is missing.**
   - The plugin ships a sibling skill `path-rules-advisor` purpose-built for generating `.claude/rules/*.md`. Step 5 reimplements the same flow inline.
   - **Fix:** When Progressive Disclosure scores ≤ 1, recommend invoking `path-rules-advisor` instead of generating rule files manually. Keep the inline flow as a fallback.

3. **Plan-mode pre-check is missing.**
   - Per project memory, write-heavy skills must not run in plan mode. Steps 5 and 6 perform writes. The skill currently has no Step 0 / pre-check.
   - **Fix:** Add a one-line directive at the top: "If plan mode is active when reaching Step 6, stop and instruct the user to exit plan mode before writing." Match the pattern used by `git-agent` skills.

#### Low impact / polish

1. **Step 1 priority order is ambiguous when both `CLAUDE.md` and `.claude/CLAUDE.md` exist.**
   - **Fix:** Clarify: "If both exist, audit `CLAUDE.md` (root takes priority) and mention the alternate location was skipped."

2. **Frontmatter description is 290+ chars and wordy.**
   - **Fix:** Tighten to 2 sentences. Example draft:
     `Use when the user asks to audit, optimize, or clean up a CLAUDE.md file, or when Claude appears to ignore project instructions. Does not cover SKILL.md files, slash commands, or general markdown.`

3. **Dimension 6 and Dimension 4 both reference `CLAUDE.local.md`.**
   - Minor redundancy in `referenc
   - es/audit-steps.md`. Consolidate the mention in Dimension 6 only.

4. **No evals / test fixtures.**
    - The skill-authoring checklist requires "at least three evaluations." None exist for this skill.
    - **Fix:** Add `tests/fixtures/claude-md-samples/` with three sample CLAUDE.md files at known grade levels (Rewrite / Needs work / Optimized) and document expected scores. Out of scope for this review unless the user requests.

## Critical files

> Both plugin and skill rename — every file referencing `claude-md-optimizer` (plugin) or `md-optimizer` (skill) must be updated. Use `git mv` for directory renames to preserve history.

### Plugin-level changes

| File | Change |
|------|--------|
| `kit/plugins/claude-md-optimizer/` (directory) | `git mv` to `kit/plugins/memory-tools/` |
| `kit/plugins/memory-tools/.claude-plugin/plugin.json` | `name`: `claude-md-optimizer` → `memory-tools`; `homepage`: update `tree/main/kit/plugins/claude-md-optimizer` → `tree/main/kit/plugins/memory-tools` |
| `kit/plugins/memory-tools/CHANGELOG.md` | Add `## [2.0.0] - 2026-05-04` entry with prominent `### BREAKING CHANGE` and `### Migration` subsections |
| `kit/plugins/memory-tools/README.md` | Update plugin name in headers, install command (`/plugin install memory-tools@agentics-kit`), Skills table row (skill name `claude-md-optimizer` → `memory-doctor`), and any directory tree examples |
| `.claude-plugin/marketplace.json` | Plugin entry: `name` `claude-md-optimizer` → `memory-tools`; `source.path` `kit/plugins/claude-md-optimizer` → `kit/plugins/memory-tools`; `version` `1.6.0` → `2.0.0` |

### Skill-level changes

| File | Change |
|------|--------|
| `kit/plugins/memory-tools/skills/claude-md-optimizer/` (directory) | `git mv` to `kit/plugins/memory-tools/skills/memory-doctor/` |
| `…/skills/memory-doctor/SKILL.md` | Frontmatter `name: md-optimizer` → `name: memory-doctor`; description tightened (fix #8); body adds plan-mode pre-check (fix #6), Notes paragraph from references (fix #2), updated Step 2 secret-scan (fix #1), Step 5/6 `AskUserQuestion` calls (fix #4), `path-rules-advisor` recommendation (fix #5), Step 1 priority clarification (fix #7); self-reference `@<plugin-dir>/skills/claude-md-optimizer/SKILL.md` → `@<plugin-dir>/skills/memory-doctor/SKILL.md` |
| `…/skills/memory-doctor/references/audit-steps.md` | Move Notes paragraph out (fix #2); dedup `CLAUDE.local.md` mention (fix #9); update self-reference path |
| `…/skills/path-rules-advisor/SKILL.md` line 108 | "Use the same priority order as the `claude-md-optimizer` skill" → "Use the same priority order as the `memory-doctor` skill" |

### Repo-wide cross-reference updates

Every match from `grep -rn "claude-md-optimizer\|md-optimizer" --include="*.md" --include="*.json"` (excluding `.claude/worktrees/`) must be evaluated and updated. Confirmed targets:

| File | Lines | Notes |
|------|-------|-------|
| `kit/plugins/marketplace-builder/skills/building-marketplaces/SKILL.md` | 3, 134, 158 | "use claude-md-optimizer" / "defer to claude-md-optimizer" — update plugin name |
| `kit/plugins/marketplace-builder/skills/building-marketplaces/references/marketplace-templates.md` | 155 | Plugin reference |
| `kit/plugins/marketplace-builder/README.md` | 105 | Plugin reference |
| `kit/plugins/skill-reviewer/README.md` | 14 | "counterpart to `claude-md-optimizer`" — update |
| `kit/plugins/skill-reviewer/skills/reviewing-skills/references/best-practices.md` | 226, 228 | Directory tree: plugin dir + skill dir both rename |
| `kit/plugins/skill-reviewer/skills/reviewing-skills/references/best-practices.md` | 52 | `claudemd-optimizer` is a reserved-word rule example — **do not change** (it's illustrating the rule, not a real reference) |
| `kit/plugins/README.md` | 24, 28 | Plugin section header + skill name (skill name was inaccurate, naturally corrected) |
| Root `README.md` | 68, 285, 293, 297, 303, 526, 619 | Plugin section header + version + Skills table + install commands + directory tree + plugin list table |
| Root `CLAUDE.md` | 52 | Plugin reference table |
| Root `CHANGELOG.md` | 73 | **Historical entry — do not retroactively edit.** Entry remains as `claude-md-optimizer v1.5.0` since that was the actual name at that time |

> Worktree files under `.claude/worktrees/laughing-hermann/**` are out of scope (separate branch state). The user's `CLAUDE.local.md` (gitignored) needs manual update post-rename — flag in verification.

### Reference

- `.claude/rules/skill-authoring.md` — checklist driving this review.
- `.claude/rules/marketplace.md` — version-bump rules (rename = MAJOR).

## Approved fix scope — single 2.0.0 MAJOR release

Bundle the following into `2.0.0`:

- **Fix 0a (NEW)** — Rename **plugin** `claude-md-optimizer` → `memory-tools`. `git mv` plugin directory; update `plugin.json` (`name`, `homepage`); update `marketplace.json` (`name`, `source.path`); update install command in plugin README. New invocation prefix: `memory-tools:`.
- **Fix 0b** — Rename **skill** `md-optimizer` → `memory-doctor`. `git mv` skill directory `skills/claude-md-optimizer/` → `skills/memory-doctor/`; update SKILL.md frontmatter `name`; update self-reference `@import` path; update sibling skill cross-reference. New invocation: `memory-tools:memory-doctor`.
- **Fix 1** — Add `Grep` to `allowed-tools`; rewrite Step 2 secret scan to use `Grep -nE` against the listed patterns and report line numbers.
- **Fix 2** — Move the operational rules paragraph from `references/audit-steps.md` (Notes section, lines 137–143) into the top of SKILL.md, right after the Freedom level callout. Keep dimension scoring and example output in references.
- **Fix 3** — Extend Step 2 `@import` scan: read each imported file (one level deep, no recursion) and add an "effective lines (incl. imports): N" figure to the report.
- **Fix 4** — Replace prose yes/no prompts in Steps 5 and 6 with `AskUserQuestion` calls (already in `allowed-tools`).
- **Fix 5** — When Progressive Disclosure scores ≤ 1, recommend invoking the sibling `path-rules-advisor` skill instead of the inline rule-file flow. Keep the inline flow as a documented fallback.
- **Fix 6** — Add a one-line plan-mode pre-check at the top: "If plan mode is active, stop before Steps 5–6 and instruct the user to exit plan mode." Mirror the pattern used by `git-agent` skills.
- **Fix 7** — Clarify Step 1: when both `CLAUDE.md` and `.claude/CLAUDE.md` exist, audit `CLAUDE.md` and note the alternate was skipped.
- **Fix 8** — Tighten frontmatter description to two sentences (~180 chars).
- **Fix 9** — Remove the `CLAUDE.local.md` mention from Dimension 4; keep it only in Dimension 6.

Skipped from this release: Fix 10 (evals) — tracked as a separate follow-up plan.

### Refinements from stress-testing

- **Fix 3 (import scan) — soft cap on per-import line count.** Skip any imported file >500 lines but include a one-line warning in the report ("import `<path>` has N lines — exceeds 500-line cap, not counted"). Prevents runaway reads on accidentally large imports.
- **Fix 6 (plan-mode pre-check) — be explicit about detection.** Skills don't get a programmatic plan-mode signal; Claude reads the system reminder. Wording: "If the system indicates plan mode is active when reaching Step 5, defer until the user exits plan mode." Mirror the `git-agent` skill phrasing.
- **Fix 8 (description tighten) — add "memory" terminology** to leverage the new name's positioning. New draft: `Use when the user asks to audit, optimize, clean up, or diagnose a CLAUDE.md / project memory file, or when Claude appears to ignore project instructions. Does not cover SKILL.md files, slash commands, or general markdown.`
- **Critical: existing user `@imports` to old skill path will break silently.** If a user added `@<plugin-dir>/skills/claude-md-optimizer/SKILL.md` to their CLAUDE.md (per the previous SKILL.md instruction), that path 404s after the directory rename. The CHANGELOG `2.0.0` entry MUST include a prominent "Migration" subsection with the old → new path swap and a `grep -rn 'skills/claude-md-optimizer/SKILL.md' .` command users can run to find references.

### Release mechanics

- Bump `version` to `2.0.0` in `.claude-plugin/marketplace.json` (not in `plugin.json`); also update `name` and `source.path` for the plugin entry.
- Add CHANGELOG entry under `## [2.0.0] - 2026-05-04` with three subsections:
  - `### BREAKING CHANGE` — Plugin renamed `claude-md-optimizer` → `memory-tools`; primary skill renamed `md-optimizer` → `memory-doctor`. New invocation path: `memory-tools:memory-doctor`.
  - `### Migration` — Step-by-step instructions:
    1. `/plugin uninstall claude-md-optimizer@agentics-kit`
    2. `/plugin install memory-tools@agentics-kit`
    3. Update any `@import` references in your CLAUDE.md from `@<plugin-dir>/skills/claude-md-optimizer/SKILL.md` to `@<plugin-dir>/skills/memory-doctor/SKILL.md`. Find references with: `grep -rn 'skills/claude-md-optimizer/SKILL.md' .`.
    4. Update `--plugin-dir` paths in any local scripts or CLAUDE.local.md.
  - `### Added/Changed/Fixed` — list fixes 1–9.
- Commit message:
  - Subject: `feat(kit/plugins/memory-tools)!: 2.0.0 — rename plugin to memory-tools, skill to memory-doctor`
  - Body must include:

    ```
    BREAKING CHANGE: Plugin renamed from claude-md-optimizer to memory-tools.
    Primary skill renamed from md-optimizer to memory-doctor.
    New invocation: memory-tools:memory-doctor.
    Update @import paths, install commands, and --plugin-dir references.
    ```

## Verification

After applying changes:

1. Confirm both directory renames succeeded:
   - `ls kit/plugins/` shows `memory-tools/` (no `claude-md-optimizer/`).
   - `ls kit/plugins/memory-tools/skills/` shows `memory-doctor/` and `path-rules-advisor/`.
2. Confirm no stragglers (excluding intentional historical/illustrative entries):
   - `grep -rn "claude-md-optimizer\|md-optimizer" --include="*.md" --include="*.json" .` should return only:
     - Root `CHANGELOG.md` line 73 (historical entry, intentionally preserved).
     - `kit/plugins/memory-tools/CHANGELOG.md` historical entries pre-2.0.0.
     - `…/best-practices.md` line 52 (`claudemd-optimizer` reserved-word example).
3. Validate JSON parsing — `marketplace.json` and `plugin.json` parse without errors (project's auto-validate hook fires on save).
4. Run `/skill-reviewer:reviewing-skills` against the updated `kit/plugins/memory-tools/skills/memory-doctor/SKILL.md` for a scored audit.
5. Load the renamed plugin: `claude --plugin-dir ./kit/plugins/memory-tools` and confirm the skill activates on:
   - "audit my CLAUDE.md" (intent match preserved)
   - "diagnose my project memory" (new naming match)
   - "review project instructions" (alternate phrasing)
6. Manually invoke against three test inputs:
   - A CLAUDE.md containing a fake `sk-test123abc...` token — verify Grep flags it with a line number.
   - A CLAUDE.md with three `@import` lines — verify the report lists imports and shows effective-lines count (with the 500-line cap warning if applicable).
   - A CLAUDE.md scoring ≤ 1 on Progressive Disclosure — verify the recommendation now suggests `path-rules-advisor`.
7. Test the marketplace install path: `/plugin marketplace add ~/devbox/agentics` then `/plugin install memory-tools@agentics-kit` and confirm successful install.
8. **User-side cleanup (manual, post-merge):** update `CLAUDE.local.md` plugin path (`./kit/plugins/claude-md-optimizer` → `./kit/plugins/memory-tools`) on the user's machine. This file is gitignored and not part of the commit.

## Stress-test findings — risks and gotchas

1. **Migration silently breaks existing installs and `@import` references.** Users running `/plugin install claude-md-optimizer@agentics-kit` and any `@import` references both break. Mitigation: prominent CHANGELOG `### Migration` subsection with explicit uninstall/reinstall steps and a `grep` command to find references.
2. **Plugin and skill names now align** (memory-tools / memory-doctor). No asymmetry remains — original concern resolved.
3. **Plan filename has random suffix (`bright-frog`).** Per `.claude/rules/plan-hygiene.md`, this must be renamed before commit. The renaming step is manual at implementation time (cannot be done in plan mode).
4. **Reserved-word check passes.** `memory-doctor` (skill) does not contain `claude` or `anthropic`. `memory-tools` (plugin) is unrestricted (the reserved-word rule applies to skills, not plugins, but `memory-tools` is clean either way).
5. **Activation regression risk.** New `memory-doctor` name with description still mentioning "CLAUDE.md" should preserve all current activation phrases. Verify with the manual test suite (verification step 5).
6. **Two-pass file read in Step 2.** After fix #1, Claude does Read (for line count + sections) AND Grep (for secrets) on the same file. Acceptable cost — Grep is cheap and the alternative (eyeballing) is unreliable.
7. **`AskUserQuestion` already in `allowed-tools`.** Fix #4 requires no `allowed-tools` change. Tool auto-loads when skill activates.
8. **Adversarial input for fix #3:** what if `@imports` form a cycle (a → b → a)? The "no recursion" guard (only one level deep) prevents infinite loops. ✓
9. **Massive `git mv` diff.** Renaming the plugin directory + skill subdirectory will produce a large diff. Use `git mv` (not delete + add) so git tracks rename history. The implementation should `git mv` first, then make content edits in subsequent commits to keep the rename diff clean.
10. **`agentics-kit` marketplace `version` bump goes from `3.0.0` to `3.1.0`** (MINOR — the marketplace itself didn't break, it just contains an updated plugin entry). Plugin's own `2.0.0` is the breaking event.
11. **Historical CHANGELOG entries must NOT be retroactively renamed.** Root `CHANGELOG.md` line 73 (`claude-md-optimizer v1.5.0`) and `kit/plugins/memory-tools/CHANGELOG.md` pre-2.0.0 entries reference what was true at the time. Edit only forward-looking entries.

## Next steps (out of scope for this plan)

- **Evals (fix #10):** three sample CLAUDE.md fixtures at known grade levels (Rewrite / Needs work / Optimized) under `tests/fixtures/claude-md-samples/`, with expected dimension scores documented. Track as a separate plan.
- **Pre-commit:** rename the plan file from `review-this-skill-and-bright-frog.md` to `rename-md-optimizer-to-memory-doctor.md` (per `.claude/rules/plan-hygiene.md`). Run as the first implementation step (`mv` + restage).
- **Optional fix #3 deferral:** if the rename + cross-reference diff is already large, defer fix #3 (effective line count for `@imports`) to `2.1.0` to keep `2.0.0` mechanically focused on the rename + behavior fixes.

---

## Interview Summary

Captured 2026-05-04 via `/plan-interview:plan-interview`.

### Key Decisions Confirmed

- **Skill rename**: `md-optimizer` → `memory-doctor`.
- **Plugin rename** (NEW, expanded scope): `claude-md-optimizer` → `memory-tools`.
- **Release strategy**: single `2.0.0` MAJOR bundling both renames + 9 fixes.
- **Migration support**: CHANGELOG callout with uninstall/reinstall instructions; no backward-compat stub.
- **`@import` cap (fix #3)**: 500 lines.
- **Plan filename**: rename to `rename-md-optimizer-to-memory-doctor.md` (deferred to implementation since plan-mode restricts `mv`).

### Plan Naming

| Element | Current | Issue | Suggested | Status |
|---------|---------|-------|-----------|--------|
| Filename | `review-this-skill-and-bright-frog.md` | Random `bright-frog` suffix | `rename-md-optimizer-to-memory-doctor.md` | User accepted; rename pending plan-mode exit |
| H1 Heading | (now updated to plugin+skill rename framing) | n/a | n/a | Updated in this plan |

### Open Risks & Concerns (resolved during interview)

1. ~~Plugin/skill name asymmetry~~ — resolved by renaming both.
2. **Cross-reference scope expanded** — every `claude-md-optimizer` mention in the repo now updates (was previously partial). Critical files section rewritten accordingly.
3. **No backward-compat stub** — accepted tradeoff. CHANGELOG migration steps are the only safety net.
4. **`marketplace.json source.path`** must change (not just `version`) — captured in plugin-level changes table.
5. **`plugin.json homepage` URL** must change — captured in plugin-level changes table.
6. **`agentics-kit` marketplace bump** to `3.1.0` MINOR — captured in stress-test findings.

### Recommended Next Steps (applied to plan)

- ✅ Plugin rename added as fix #0a (skill rename is fix #0b).
- ✅ Critical files section rewritten — single comprehensive list with plugin-level + skill-level + cross-reference subtables.
- ✅ Verification expanded to cover plugin install path, JSON parsing, `CLAUDE.local.md` post-merge cleanup.
- ✅ CHANGELOG template now includes explicit Migration subsection with uninstall/reinstall commands.
- ✅ H1 heading updated to reflect plugin rename.
- ✅ Stress-test findings updated to reflect new scope (asymmetry resolved, `git mv` discipline added, marketplace version bump captured).

### Simplification Opportunities

- **Fix #3 deferral to 2.1.0** — surfaced as an optional Next Step. Reduces `2.0.0` mechanical scope (rename + repointing + behavior fixes) by removing the only feature-addition. The user can decide at implementation time whether to defer.
