# Changelog

## v3.5.2 — 2026-08-17 — the output guide shows a finished suggestion

### Changed

- **`references/output-guide.md` gains a Worked Example**: a filled
  suggestion for a `parseDuration("1h30m")` helper — behavior-sentence test
  name, concrete What/Why/Code-reference/Approach, and a runnable Vitest
  snippet — where the template was bracket-placeholders end to end. Step 5
  points at it as the specificity bar every suggestion should match.

## v3.5.1 — 2026-08-17 — The tests you write get run before you say done

### Changed

- **`code-testing-agent` Step 6a runs the test files it writes.** The skill
  wrote files and ended with "Suggest `[test command]` to verify" — handing
  verification to the user despite having Bash. Done is redefined: files
  written **and** the runner executed them, output shown. Compile/import/
  collection errors are defects with a bounded fix loop (max 3 iterations,
  then an honest hard stop); failing assertions that expose real behavior
  gaps are findings, never weakened to force a pass.
- **`reviewing-tests` Step 7 verifies its own edits the same way**: run the
  edited file(s), report pass/fail with runner output, and if the edits broke
  collection or previously-passing tests, fix within 3 iterations or revert
  and report which fixes were reverted. A new P1 gap test failing against
  current source is the coverage gap being confirmed — a finding, not a
  defect.
- **Stale-mock findings need paired evidence**: the mock's return shape or
  signature **and** the current real signature it stands in for. No paired
  quotes, no finding.

## v3.5.0 — 2026-07-29 — Split `tdd-fix` into a core plus references

### Changed

- **`tdd-fix` is now a 571-word core plus two reference files, down from 1,202
  words in a single body.** It was the only skill in this plugin without a
  `references/` directory; it now matches the per-skill layout its four siblings
  already use.
  - `references/fix-loop.md` — Step 2's red phase, Step 3's iteration log and
    3a–3c, Step 4's hard cap
  - `references/handoff.md` — Step 5's regression sweep, Step 6's summary block,
    Steps 7–8's commit-agent and pr-agent handoffs
- The core keeps the strict freedom-level marker, `## When not to use`, every
  Step 0–9 heading, and each step's hard stop.

Behaviour, `description:`, `allowed-tools:`, and `disable-model-invocation: true`
are unchanged.

## v3.4.5 — 2026-07-28 — Collapse the plan-mode guard to one line

- `tdd-loop` replaces its four-line `ExitPlanMode` preamble with the canonical
  one-line guard. The skill still exits plan mode before its first git mutation.

## v3.4.3 — 2026-06-05 — Use portable plugin-dir path in README

### Fixed

- `README.md`: local-development example now uses the repo-relative `./kit/plugins/code-testing-agent` path instead of an author-specific home directory.

---

## v3.4.1 — README: sync usage documentation with current skill behavior

- Updated README.md to accurately reflect current plugin capabilities, component inventory, and usage patterns.

## [3.4.0] - 2026-05-12

### Changed

- `disable-model-invocation: true` on `tdd-fix` — manual invocation only via `/code-testing-agent:tdd-fix`; no longer auto-triggers on intent match.
- `disable-model-invocation: true` on `tdd-loop` — manual invocation only via `/code-testing-agent:tdd-loop`; no longer auto-triggers on intent match.

## [3.3.0] - 2026-05-08

### Added

- New skill: `tdd-loop` — test-first feature dev with a bounded autonomous implementation loop
- Given a feature description, writes a comprehensive failing test suite (red phase), commits it as `test:`, then loops hypothesis → edit → re-run up to 20 iterations until green
- Each iteration logs a one-sentence hypothesis in the shared iteration-log format (see `references/tdd-log-format.md`)
- EARLY_GREEN guard: stops if tests pass in iteration 1 (likely too lenient or pre-implemented) — requires human review before committing
- Test-edit escape hatch: one test correction allowed per loop run, logged loudly, costs 2 iterations against the cap
- Hard stop at 20 impl iterations or 5 gate-fix iterations: no commit or PR created; branch left intact for manual inspection
- Quality gates (Step 5): typecheck + lint + full regression sweep, each failure triggers a separate gate-fix loop capped at 5
- Two-commit outcome: `test: …` followed by `feat: …` on the branch for clean reviewer experience
- PR body includes the full `## TDD iterations` table and optional `## Gate fixes` section
- Shared iteration-log format in `references/tdd-log-format.md` (to be backported to `tdd-fix` in a follow-up)

## [3.2.2] - 2026-05-07

### Changed

- Reordered `reviewing-tests` skill description to start with "Use when..." for reliable auto-activation

## [3.2.1] - 2026-05-07

### Changed

- Collapsed `code-testing-agent`, `running-tests`, and `tdd-fix` skill descriptions from multi-line YAML to single-line inline strings starting with "Use when..." for reliable auto-activation

## [3.2.0] - 2026-04-14

### Added

- New skill: `tdd-fix` — autonomous test-driven bug-fix loop with a hard cap of 10 iterations
- Given a bug description, writes a failing test (red phase), iterates hypothesis → edit → re-run until green, then commits with a `fix:` prefix and opens a PR
- Each iteration logs a one-sentence hypothesis and diff summary in a markdown table
- Hard stop at 10 failed iterations: no commit or PR is created; full iteration log is surfaced for the user
- Regression sweep after green: runs the full suite before committing; stops cleanly if regressions are detected
- Delegates commit and PR creation to `commit-agent` and `pr-agent` from the `git-agent` plugin

## [3.1.0] - 2026-04-09

### Changed
- Explicitly declare `allowed-tools` frontmatter on all skills.
  Makes tool requirements explicit and removes reliance on session baseline
  permissions. No behavior change — tools were already available via session default.

## [3.0.0] - 2026-03-06

### Changed

- BREAKING CHANGE: plugin renamed from `code-test-suggestion` to `code-testing-agent`
- Plugin directory renamed: `plugins/code-test-suggestion/` → `plugins/code-testing-agent/`
- Skill directory renamed: `skills/code-test-suggestion/` → `skills/code-testing-agent/`
- Skill frontmatter name updated: `code-test-suggestion` → `code-testing-agent`
- Keyword `test-suggestion` replaced with `testing-agent` in `plugin.json` and `marketplace.json`
- Homepage URL updated to reflect new directory name
- Users who installed `code-test-suggestion@agentics-kit` must reinstall as `code-testing-agent@agentics-kit`

## [2.2.1] - 2026-03-02

### Changed

- Renamed skill `test-review` → `reviewing-tests` to follow the gerund naming convention for skills (non-breaking; skill activates by description match, not by name)

## [2.2.0] - 2026-03-02

### Fixed

- Removed non-compliant cross-skill reference in `test-review` SKILL.md Step 4 (`../code-test-suggestion/references/test-analysis-guide.md`). The `../` path escapes the skill root and is not supported by Claude Code's skill reference spec. Step 4's built-in heuristics (4a–4e) are self-sufficient.

## [2.1.0] - 2026-03-01

### Added

- Step 1 now parses invocation message for explicit file path and function/method arguments
- File paths (backtick, quoted, or bare tokens with known extensions) are prioritized over git inspection
- Function/method scoping: when a function name is provided, analysis in Step 3 is limited to that function
- Error reporting when a provided file path does not exist (no silent fallback)

## [2.0.0] - 2026-03-01

### Removed

- **BREAKING:** Removed `suggest-tests` command (`/code-test-suggestion:suggest-tests`)
- **BREAKING:** Removed `review-tests` command (`/code-test-suggestion:review-tests`)
- Removed `commands/` directory

### Note

Both workflows remain fully available as auto-activated skills. Say "suggest tests for ..." or "review my tests" to trigger them.

## [1.1.0] - 2026-03-01

### Added

- New skill: `test-review` — reviews existing tests for quality, coverage gaps, and alignment with code behavior and developer intent
- 7-step review workflow: identify tests → locate source code → search for plan → analyze source → detect infrastructure → review tests across 9 dimensions → offer to apply fixes
- Review dimensions: behavior vs implementation, test naming, assertion focus, coverage gaps, mock hygiene, test fragility, setup/teardown isolation, plan alignment, coverage target progress
- Reference file: test-quality-checklist.md with detailed heuristics for each review dimension, anti-patterns, and language-specific review patterns
- Command: `/code-test-suggestion:review-tests [test-file-path]` for explicit invocation

## [1.0.0] - 2026-03-01

### Added

- Initial release: 6-step code test suggestion skill
- Step 1: Identifies target code from explicit paths, conversation context, or recent git changes
- Step 2: Searches for implementation plans in docs/plans/, ~/.claude/plans/, commit messages, and inline comments to understand developer intent
- Step 3: Analyzes code for behavioral summary, critical paths, integration points, implicit contracts, and fragility areas
- Step 4: Detects project test framework and learns existing test patterns from nearby test files
- Step 5: Suggests prioritized tests with rationale — each tied to specific code behavior, organized by Priority 1 (critical behavior), Priority 2 (error handling/edge cases), and Priority 3 (integration contracts)
- Step 6: Offers to write complete test files using detected project conventions
- Reference file: test-analysis-guide.md with detailed heuristics for code analysis, language-specific patterns (TypeScript/JS, Python, Go, Rust), and mock strategy guidance
- Command: `/code-test-suggestion:suggest-tests [file-path]` for explicit invocation
- Coverage-aware: Step 4d detects project coverage targets from jest.config, pyproject.toml, .nycrc, codecov.yml; Step 5 includes Coverage Assessment section and `[coverage-only]` tagged tests for trivial code needed to meet the target
