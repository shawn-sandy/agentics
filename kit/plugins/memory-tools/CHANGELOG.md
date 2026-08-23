# Changelog

## v4.3.1 — 2026-08-23 — implementing-insights resolves repos more strictly

### Fixed

- **Step 2 triages the user's own plugins against the plugin repo's `origin/main`,
  not the installed mirror.** The mirror lags merged PRs by days; a verification run
  found it missing a skill that had merged that morning, which would have re-opened
  and re-implemented a shipped item.
- **Step 3 reads each project's real path from its session files instead of
  decoding the directory name.** Every `~/.claude/projects/<dir>/*.jsonl` line
  carries `"cwd"`; the name-decoding fallback (each `-` is one non-alphanumeric
  character — `/`, `-`, or a space) is kept only for directories with no sessions.
  Matching is by the resolved path's basename, not a suffix: `plugins` had resolved
  to `acss-plugins` silently. Two checkouts sharing a basename now means ask.
- **Step 3 gives the no-repo-named case a procedure.** Grep the report's cited
  identifiers across each inventory checkout's `git log` and `package.json`; one hit
  is the target, zero or several means ask. Session counts are topic clusters and
  are never used as repo keys.
- **Step 3 drops temp-dir and worktree paths from the inventory by path prefix,
  not by directory-name substring.** A session sandbox under `/private/tmp` had
  resolved as a repo; a substring filter would also have hidden a real repo whose
  name happened to contain the word.

## v4.3.0 — 2026-08-20 — implementing-insights discovers repos on its own

### Changed

- **`implementing-insights` now resolves target repos discover-first, ask-last.**
  Step 3 previously asked the user for a path the moment a repo named in a
  finding was not immediately found. It now builds a repo inventory from
  `~/.claude/projects/` (the same usage data the insights report is generated
  from, so every repo the report can name has a slug there), filters out
  session-worktree slugs, verifies each match is a real git checkout, and only
  falls back to asking the user to point at their projects directory when a
  repo still cannot be resolved. No machine-specific layout is assumed — the
  inventory is rebuilt from scratch on every run, so the skill works for any
  plugin user, not just this machine.
- **Workflow-shaped items fall back to `~/.claude/` for users without their own
  plugin repo.** The layer-placement step assumed every user maintains a
  personal plugin repo; when none exists, those items now route to the
  machine-wide `~/.claude/` layer as the next-best fit.

## v4.2.0 — 2026-08-19 — usage-insights follow-through

### Added

- **New skill `implementing-insights`** — takes a Claude Code usage-insights
  report, triages every recommendation against the config that already exists
  (`~/.claude/`, installed plugins, each target repo), and implements only the
  genuinely open items — each at the correct config layer (plugin / user-global
  / repo), one PR per change, with worktree isolation for parallel agents and a
  verified outcome ledger at the end. Encodes the triage-before-implement
  workflow from the 2026-08-19 usage-insights session: insights reports repeat
  themselves, so already-implemented and rule-conflicting suggestions are cited
  and skipped, never re-implemented. Promoted from a personal skill into the
  plugin so it is versioned and synced across machines.

## v4.1.1 — 2026-08-17 — the write gate actually runs

### Fixed

- **The mandatory post-write verification gate is now executable.** Both
  call sites (`agentic-memory-management` Step 7 and `path-rules-advisor`'s
  write-verification reference) shipped a bash block containing `TARGET=...`
  expansions the Bash tool textually refuses — the repo's own guard test
  ledgered them as known-broken call sites, so the skills' central check
  errored on first run, every run. The check now ships as
  `bin/memory-verify-write` (wrapper) + `scripts/verify_write.py` (the exact
  former inline semantics: diff vs git, frontmatter parse, non-empty body),
  invoked by bare name with a literal path. The KNOWN_BROKEN ledger entries
  are deleted and the guard test now mutation-tests the shipped wrapper in
  both pass and fail directions. `allowed-tools` narrows from
  `Bash(git *), Bash(python3 *)` to `Bash(memory-verify-write *)`.

## v4.1.0 — 2026-07-29 — Split `path-rules-advisor` into a core plus references

### Changed

- **`path-rules-advisor` is now a 522-word core plus three reference files, down
  from 1,546 words in a single body.**
  - `references/rule-modes.md` — Mode A Steps 1–7 and Mode B Steps 1–7 in full
  - `references/rule-file-format.md` — the generated-file template, brace
    expansion, and the Notes section
  - `references/write-verification.md` — the diff-back plus the Python
    frontmatter parse check and the pre-write gate
- The core keeps what must load unconditionally: mode selection, both hard-stop
  confirmations, the run-after-every-write rule with its non-zero-exit **STOP**,
  and the `REPORT rather than write` pre-write gate. Only the executable check
  moved behind a link.

Behaviour, `description:`, and `allowed-tools:` are unchanged.
`tests/plugins/test-memory-doctor-guard.sh` now extracts the parse check and the
declared-command scan from the core *and* its references, so it still executes
real shipped code rather than going green on relocated content.

## v4.0.0 — 2026-07-20 — Rename `agentic-memory-doctor` to `agentic-memory-management`

### Changed

- **Breaking:** skill renamed from `agentic-memory-doctor` to `agentic-memory-management`. New invocation: `memory-tools:agentic-memory-management`.
- `@import` references to `skills/agentic-memory-doctor/SKILL.md` must be updated to `skills/agentic-memory-management/SKILL.md`.

---

## v3.2.0 — 2026-07-19 — Verify the write before reporting success

### Added

- `agentic-memory-doctor`: new Step 7 runs after the write — shows `git diff` for the audited file, then asserts it still parses with valid frontmatter (where present) and a non-empty body. A pre-write gate refuses to overwrite a file whose own frontmatter is malformed, reporting the offending line instead.
- `path-rules-advisor`: same diff-back and parse check after writing a rules file.
- Both skills rewrite the files that configure every future session, so a corrupted CLAUDE.md or rules file degrades every later conversation silently and outlives the session that caused it.
- `allowed-tools` extended with `Bash(git diff:*)` and `Bash(python3:*)` for the new check.

---

## v3.1.3 — 2026-06-05 — Use portable plugin-dir path in README

### Fixed

- `README.md`: local-development example now uses the repo-relative `./kit/plugins/memory-tools` path instead of an author-specific home directory.

---

## v3.1.1 — README: sync usage documentation with current skill behavior

- Updated README.md to accurately reflect current plugin capabilities, component inventory, and usage patterns.

## [3.1.0] - 2026-05-20

### Changed

- `agentic-memory-doctor`: Added an explicit **optimization principle** near the top of `SKILL.md` — "keep only rules that change Claude's behavior vs. built-in defaults; tighten load-bearing rules to crisp imperatives."
- `agentic-memory-doctor`: Added **Default-restating rules** as a 4th hygiene item in Dimension 5 (`references/audit-steps.md`). Includes a concrete definition and examples; existing 0 / 1 / 2+ scoring scale is unchanged.
- `agentic-memory-doctor`: Added two new transformation bullets to Step 5 — "cut default-restating rules" and "tighten kept rules to crisp imperatives" — so the principle is enforced during the in-chat rewrite.
- `agentic-memory-doctor`: Added a Step 4 callout instructing the model to name "default-restating rules" by phrase when they drive a Dimension 5 deduction, so the audit report and the rewrite use consistent vocabulary.

## [3.0.0] - 2026-05-10

### BREAKING CHANGE

- Primary skill renamed from `memory-doctor` to `agentic-memory-doctor`. New invocation: `memory-tools:agentic-memory-doctor`.
- Existing `@import` references to `skills/memory-doctor/SKILL.md` will break — update to `skills/agentic-memory-doctor/SKILL.md`.

### Migration

1. Find and update any `@import` references in your CLAUDE.md:
   - Old: `@<plugin-dir>/skills/memory-doctor/SKILL.md`
   - New: `@<plugin-dir>/skills/agentic-memory-doctor/SKILL.md`
   - Find references with: `grep -rn 'skills/memory-doctor/SKILL.md' .`

## [2.0.1] - 2026-05-07

### Changed

- Added "Does NOT..." scope boundary to `path-rules-advisor` description clarifying it does not update CLAUDE.md or memory entries (use memory-doctor for that)

## [2.0.0] - 2026-05-04

### BREAKING CHANGE

- Plugin renamed from `claude-md-optimizer` to `memory-tools`.
- Primary skill renamed from `md-optimizer` to `memory-doctor`. New invocation: `memory-tools:memory-doctor`.
- Existing `@import` references to `skills/claude-md-optimizer/SKILL.md` will break — update to `skills/memory-doctor/SKILL.md`.

### Migration

1. `/plugin uninstall claude-md-optimizer@agentics-kit`
2. `/plugin install memory-tools@agentics-kit`
3. Find and update any `@import` references in your CLAUDE.md:
   - Old: `@<plugin-dir>/skills/claude-md-optimizer/SKILL.md`
   - New: `@<plugin-dir>/skills/memory-doctor/SKILL.md`
   - Find references with: `grep -rn 'skills/claude-md-optimizer/SKILL.md' .`
4. Update `--plugin-dir` paths in any local scripts or `CLAUDE.local.md` from `kit/plugins/claude-md-optimizer` to `kit/plugins/memory-tools`.

### Added

- `Grep` added to `memory-doctor` `allowed-tools`; Step 2 secret scan now uses `Grep -nE` with exact patterns and reports line numbers (no more eyeball-matching on long files)
- Step 2 `@import` scan now reads each imported file (one level deep) and reports effective line count; imports exceeding 500 lines are skipped with a warning
- Plan-mode pre-check at top of skill: defers Steps 5–6 writes if system indicates plan mode is active
- Step 5 and Step 6 prompts now use `AskUserQuestion` for explicit Yes/No gating (replaces prose questions that could be misread as already-confirmed)
- When Progressive Disclosure scores ≤ 1, Step 4 Top 3 now recommends invoking `memory-tools:path-rules-advisor` as the preferred delegation path; inline flow kept as fallback
- Step 4 and Step 5 include `path-rules-advisor` delegation recommendation

### Changed

- Frontmatter `name` changed from `md-optimizer` to `memory-doctor`
- Frontmatter `description` tightened to two sentences; adds "diagnose" and "project memory file" terminology
- Step 1 priority clarified: when both `CLAUDE.md` and `.claude/CLAUDE.md` exist, root takes priority and alternate location is noted as skipped
- Operational rules paragraph (audit scope, opt-in steps, memory load order) moved from `references/audit-steps.md` Notes section to top of `SKILL.md` so Claude sees them before Step 3 triggers a Read
- `references/audit-steps.md` Notes section removed (content now in `SKILL.md` or covered by Dimension 6)
- `path-rules-advisor`: cross-reference updated from `claude-md-optimizer` to `memory-doctor`
- Self-reference `@import` path updated to `skills/memory-doctor/SKILL.md`

## [1.6.0] - 2026-04-09

### Changed
- Explicitly declare `allowed-tools` frontmatter on all skills.
  Makes tool requirements explicit and removes reliance on session baseline
  permissions. No behavior change — tools were already available via session default.

## [1.5.0] — 2026-02-27

### Changed

- Refactored SKILL.md to follow three-level progressive disclosure pattern
- Extracted Step 3 dimension scoring rubrics, example output, and notes to `references/audit-steps.md`
- Added explicit freedom level statement to skill body
- Added scope boundary to frontmatter description (excludes SKILL.md files and commands)

## [1.4.0] - 2026-02-25

### Fixed

- `claude-md-optimizer` skill: renamed `name` from `claude-md-optimizer` to `md-optimizer` — the `claude` substring is reserved and prohibited in skill names (breaking: skill reference changes from `claude-md-optimizer:claude-md-optimizer` to `claude-md-optimizer:md-optimizer`)
- `claude-md-optimizer` skill: replaced `$ARGUMENTS` and `$PWD` variable references in Step 1 with prose descriptions — these variables only expand in command files, not skills
- `path-rules-advisor` skill: replaced all `$ARGUMENTS` and `$PWD` variable references with prose descriptions for the same reason
- Both skills: added Table of Contents (required for files exceeding 100 lines)

## [1.3.0] - 2026-02-24

### Added

- Step 5: Offers to generate `.claude/rules/` files for each section extracted during optimization
- Step 5: Shows `@import` callout (after the CLAUDE.md block) for referencing the optimizer in any project
- Step 5: Checks for `.claude/rules/` directory existence; prompts to create if missing
- Dimension 4: Added `paths:` frontmatter glob examples and brace expansion patterns from official docs
- Step 4: Added standing recommendation to use Step 5 rule-file generation when Progressive Disclosure scores ≤ 1
- path-rules-advisor: Added brace expansion examples within Rule file format section
- Notes: Added official memory docs URL and self-referencing `@import` usage tip

### Changed

- Step 5: Removed `## Suggested Move to Separate Files` block — replaced by rule-file offer flow

## [1.2.0] - 2026-02-24

### Added

- New skill `path-rules-advisor`: analyzes project and CLAUDE.md to recommend and generate path-specific rule files in `.claude/rules/`
- Supports direct creation via `$ARGUMENTS` (path pattern + description) or analysis mode (no argument)

## [1.1.0] - 2026-02-24

### Added

- Step 1: Added `$PWD/.claude/CLAUDE.md` as a 3rd priority location (between primary project and global user)
- Step 2: Added `@import` scan as a 5th metric — lists any `@path/to/file` references found
- Dimension 4: Expanded Progressive Disclosure to name both delegation mechanisms: `.claude/rules/*.md` (with `paths:` frontmatter support) and external docs via `@import`
- Tips: Added memory load order bullet (project rules → project memory → user memory → project local)
- Tips: Added `/init` command tip for bootstrapping CLAUDE.md from codebase context
- Tips: Added `@path/to/file` import syntax tip
- Tips: Added `.claude/rules/*.md` modular rules tip with `paths:` frontmatter note

### Fixed

- Dimension 6 and Tips: Corrected local override filename from `CLAUDE.md.local` to `CLAUDE.local.md` (official Claude Code convention)
- Tips: Added note that Claude Code auto-adds `CLAUDE.local.md` to `.gitignore`

## [1.0.0] - 2026-02-23

### Added

- Initial release: 6-step CLAUDE.md audit skill with 6-dimension scoring rubric
