# Changelog

## v3.3.5 — 2026-08-21 — Checklist names the bugs that survive review

### Changed

- **`references/review-checklist.md` section 2 gains an "Escape-Prone Classes"
  subsection** naming the five defect classes that repeatedly reached PR review
  bots in 652 sessions of usage data: pagination and sort tie-breakers,
  unvalidated `parseInt`/`Number()` on user input, derived state left stale
  after a client-side update, timezone-dependent date anchors, and scripts that
  continue after a failed step. `agent-code-reviewer` is the subagent that
  `git-agent`'s pre-PR review dispatches to, so the checklist it reads now
  names the same defects that review prompt does.

## v3.3.4 — 2026-08-17 — Findings must survive a re-read before they are reported

### Changed

- **`code-review-agent` gains a Verify Findings step** between the checklist
  and the report: every finding's cited file:line is re-Read, the verbatim
  snippet is pasted into the finding, and anything the snippet does not
  substantiate is dropped or explicitly labeled **Unconfirmed**. The review is
  not complete until every Critical Issue and Breaking Change carries a
  verbatim quote from the current file. Reviewers that skip the re-read
  produce plausible-looking-but-wrong findings — the audit that prompted this
  found the workflow went checklist → format → report with only a passive
  "be specific" tip in between.
- **The background `agent-code-reviewer` gets the same gate as a workflow
  step** ("Verify evidence"): re-Read cited lines, attach the exact snippet,
  discard unsubstantiated findings, and check new findings against the known
  false positives in agent memory before reporting. It runs unattended, where
  a wrong finding flows straight to another agent — the passive
  "high confidence" filter had no procedure behind it.
- **A filled example finding now sits under the agent's output schema** (SQL
  injection, with snippet and fix), so the unattended path carries a worked
  example instead of bracket placeholders only.

## v3.3.3 — 2026-07-16 — Delegate agent-file review to skill-reviewer

### Fixed

- `commands/fix-branch.md`, `README.md`: changed `**/agents/*.md` files are now reviewed by `skill-reviewer:reviewing-skills`. The previous target, `agent-reviewer:reviewing-agents`, belonged to a plugin de-registered in v4.0.0 and now deleted, so `/code-review:fix-branch` would have hit a missing skill on any branch touching an agent file.

---

## v3.3.2 — 2026-06-05 — Use portable plugin-dir path in README

### Fixed

- `README.md`: local-development example now uses the repo-relative `./kit/plugins/code-review` path instead of an author-specific home directory.

---

## v3.3.1 — README: sync usage documentation with current skill behavior

- Updated README.md to accurately reflect current plugin capabilities, component inventory, and usage patterns.

## [3.3.0] - 2026-05-13

### Added

- `fix-branch` command (`/code-review:fix-branch`) — reviews all branch changes vs the default branch, classifies findings as blocking/major/minor/unfixable using a concrete severity rubric, applies fixes autonomously via `Edit`/`Write`, retries once (cap = 2), and leaves fixes uncommitted with a summary pointing to `git diff` and `/git-agent:commit-agent`.

## [3.2.1] - 2026-05-07

### Changed

- Reordered `code-review-agent` skill description to start with "Use when..." for reliable auto-activation

## [3.2.0] - 2026-04-09

### Changed
- Explicitly declare `allowed-tools` frontmatter on all skills.
  Makes tool requirements explicit and removes reliance on session baseline
  permissions. No behavior change — tools were already available via session default.

## [3.0.1] - 2026-03-08

### Fixed

- Resolved activation conflict between skill and agent — both had overlapping trigger descriptions causing redundant or unpredictable activation
- Skill (`code-review-agent`) now owns all direct, interactive user review requests
- Agent (`agent-code-reviewer`) rewritten as internal-only, for delegation from other agents or automated workflows
- Agent retained for future delegation workflows; not triggered by direct user requests

## [3.0.0] - 2026-03-08

### Changed

- BREAKING CHANGE: agent renamed from `code-reviewer` to `agent-code-reviewer` to avoid conflict with built-in code-reviewer agent
- Agent file renamed: `agents/code-reviewer.md` -> `agents/agent-code-reviewer.md`

## [2.3.0] - 2026-03-08

### Changed

- Removed `WebFetch` and `WebSearch` from agent tools (unnecessary for code review)
- Switched agent tools format to comma-separated (docs convention)
- Fixed workflow step 1: `git status` runs via Bash, not Grep/Glob
- Enhanced agent description with proactive delegation language

### Added

- `permissionMode: plan` for enforced read-only behavior at framework level
- `disallowedTools` blocking Write, Edit, NotebookEdit (defense-in-depth)
- `memory: project` for persistent learning of project patterns across sessions
- Memory instructions section in agent prompt body
- `background: true` for non-blocking execution

## [2.2.0] - 2026-03-08

### Added

- New `code-reviewer` agent (`agents/code-reviewer.md`) for sub-agent invocation from other contexts
- Agent uses Read-Only tools (Read, Glob, Grep, WebFetch, WebSearch) with sonnet model and 10-turn limit
- Confidence-based filtering to surface only high-priority findings
- Structured output matching the existing skill review format

## [2.1.1] - 2026-03-06

### Fixed

- Optimized skill description for improved trigger accuracy: now describes the structured 6-dimension checklist, complexity rating system, and automatic file resolution
- Removed self-referential "use this skill -- not built-in" language in favor of content-rich description
- Added informal trigger phrases ("take a look at this", "anything wrong with this code")
- Expanded scope exclusions to include accessibility audits
- Updated README to reflect all six review dimensions and the Breaking Changes output section
- Updated marketplace.json description to include complexity rating

## [2.1.0] - 2026-03-05

### Added

- Breaking Changes & Regressions checklist section (section 6) covering: public API surface, shared/internal contracts, data & config contracts, regression risk, and call site assessment
- Breaking Changes & Regressions output section in Review Format, placed between Complexity Rating and Critical Issues
- No-duplicate guidance: breaking changes listed in the new section are omitted from Critical Issues
- No-git-context fallback: when git history is unavailable, assess API surface visually from reviewed code only
- DB schema checks marked conditional: apply only when reviewing migration files or schema definitions
- Detection approach uses question-based guidance consistent with the rest of the checklist
- Example breaking change entry added to the Example Review section
- Updated frontmatter description to trigger on "detect breaking changes", "check if this change breaks anything", and "could this cause a regression" intents
- Added `breaking-changes` and `regressions` tags to marketplace.json entry

## [2.0.0] - 2026-03-03

### Changed

- BREAKING CHANGE: skill renamed from `code-review` to `code-review-agent` to avoid conflict with Anthropic's built-in `code-review` skill
- Skill directory renamed: `skills/code-review/` → `skills/code-review-agent/`

## [1.2.0] - 2026-03-03

### Added

- Code complexity rating (Low/Medium/High/Very High) to Review Checklist (#5)
- Complexity Rating section in Review Format output (after Summary)
- Rating guide table with signals for each level
- Multi-file guidance: per-file rating, aggregate only when reviewing 3+ files
- Small-file handling: trivially simple files noted as Low without full breakdown
- Scope clarification: complexity covers code-level coupling, not architecture
- Updated frontmatter description to include complexity
- Updated example review to demonstrate complexity output
- Added "complexity" keyword to plugin.json

## [1.1.0] - 2026-03-03

### Added

- Adaptive file resolution (Step 0): supports explicit path, git status, branch diff, and fallback prompt
- Table of contents

### Fixed

- Description rewritten to third person with scope exclusion
- Second-person "your review" corrected to "the review"
- Freedom level statement added to opening paragraph
