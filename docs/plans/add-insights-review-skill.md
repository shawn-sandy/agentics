---
status: todo
type: feature
created: 2026-08-14
effort: high
issue: https://github.com/shawn-sandy/agentics/issues/557
glance: Every few weeks the Claude Code /insights command produces a report full of good suggestions, and acting on them is currently a manual copy-paste job that has no memory of what was already done. This adds a skill that reads the report, works out where each suggestion belongs, and skips the ones already applied without burying the ones that were reworded. We will know it worked when the shipped parser turns a fixture report into five memory suggestions and seven capability prompts, and splits those five into two already applied, one drifted, and two new.
---

# Plan: Turn the /insights report into changes that actually land

## Objective

Add an `insights-review` skill to the `memory-tools` plugin that reads a Claude Code `/insights` report, classifies each recommendation into one of four destinations, separates the already-applied from the genuinely new, and then either applies the accepted items or emits an implementation plan instead.

## Context

Claude Code ships an `/insights` command that analyses recent sessions and writes an HTML report to `~/.claude/usage-data/report.html`. The report is not free-form advice: it has seven sections with stable HTML ids (`section-work`, `section-usage`, `section-wins`, `section-friction`, `section-features`, `section-patterns`, `section-horizon`) and two distinct payload types. One is a set of checkbox-selectable markdown blocks under "Suggested CLAUDE.md Additions"; the other is a set of "Paste into Claude Code" prompts describing a capability worth having. Those two shapes map onto two different kinds of destination, which is what makes automatic routing tractable.

This work is already happening by hand. Commit `a99b1a7` turned one report into three implementation plans. The **Verification**, **Formatting & Scope**, and **Ship / PR Workflow** sections of the maintainer's global `~/.claude/CLAUDE.md` are report suggestions pasted in by hand, and `~/.claude/rules/review-bot-loops.md` is a third report item hand-written as a path-scoped rule file. Nine reports exist locally, dated 2026-07-16 through 2026-08-14, so this is a recurring cadence rather than a one-off.

The load-bearing risk is duplication. In the 2026-08-14 report, three of the five suggested CLAUDE.md sections are already present verbatim in the global memory file. A skill that applies suggestions without checking would re-add them on every run, so already-applied detection is a requirement rather than a refinement. The mirror risk is over-skipping: when the report rewords a rule you already tuned, a heading-only match would mark it applied and bury a genuine improvement. The detector therefore reports three statuses rather than two, and the drifted case is shown rather than silently dropped. A second risk is that the report's markup is undocumented and could change between Claude Code releases; the mitigation is to assert every expected section id is present and fail naming the missing one, rather than silently returning zero recommendations. A third is that two of the four destinations live outside the repository in unversioned files, so the skill copies the target to a timestamped backup before its first write and never writes before its confirmation gate resolves.

The plugin choice follows from what already exists. `memory-tools` v4.1.0 ships `agentic-memory-management`, which owns auditing and rewriting `CLAUDE.md`, and `path-rules-advisor`, which owns creating `.claude/rules/` files and explicitly defers global memory to its sibling. Two of the four destinations are therefore already owned, and the new skill delegates to them rather than reimplementing their writes. Because the skill runs in whatever project invokes it, and a plain application has no `kit/plugins/` layout, routing probes the calling project and marks a destination unavailable rather than scaffolding a structure the project has no concept of. Full research and the decisions behind this approach are in `docs/prompts/proposal-add-insights-review-skill.md`.

## Files

- kit/plugins/memory-tools/skills/insights-review/SKILL.md (new) — skill core: invocation, the confirmation gate, and the apply-versus-plan fork
- kit/plugins/memory-tools/skills/insights-review/references/parse-report.md (new) — the extractable report parser and its section-id assertions
- kit/plugins/memory-tools/skills/insights-review/references/already-applied.md (new) — the extractable three-status already-applied detector, covering both memory and capability records
- kit/plugins/memory-tools/skills/insights-review/references/routing-and-gate.md (new) — the four-destination routing table, the availability probe, and the delegation seams
- tests/fixtures/insights-report/report.html (new) — minimal synthetic report carrying all seven section ids, five suggestions, seven prompts
- tests/fixtures/insights-report/claude-md-before.md (new) — fixture memory file containing three of the five suggestions, one deliberately reworded
- tests/fixtures/insights-report/skills/ (new) — one stub SKILL.md whose name and description match a paste-prompt, so capability already-applied detection has something to match
- tests/plugins/test-insights-review.sh (new) — extracts the shipped parser and detector and runs them against the fixtures
- .github/workflows/check-plugin-versions.yml (modified) — run the new test in CI
- .claude-plugin/marketplace.json (modified) — bump memory-tools to 4.2.0
- kit/plugins/memory-tools/CHANGELOG.md (modified) — v4.2.0 entry
- kit/plugins/memory-tools/README.md (modified) — document the third skill
- README.md (generated) — regenerated Plugin Reference Table

## Steps

1. Scaffold kit/plugins/memory-tools/skills/insights-review/SKILL.md with `name: insights-review`, a three-part `description` of 200 characters or fewer whose first sentence is 80 characters or fewer, an `allowed-tools` list covering AskUserQuestion, Bash(python3 *), Glob, Grep, Read, Write, Edit, Skill, ToolSearch and ExitPlanMode, and the repo's plan-mode guard line verbatim as its first step Why: the skill writes files, so `.claude/rules/plugin-patterns.md` requires both the guard line and — because `ExitPlanMode` is a deferred tool — `ToolSearch` alongside it in `allowed-tools`, or the guard stops for a permission prompt mid-run; the budget script enforces the first-sentence limit as well as the total Verify: `python3 tests/plugins/measure_description_budget.py kit/plugins/memory-tools/skills/insights-review/SKILL.md` exits 0 and prints two numbers within 200 and 80, and `bash tests/plugins/test-exitplanmode-guard.sh` exits 0.
2. Write references/parse-report.md shipping a single extractable `python3` block that reads a report path, asserts all seven section ids are present, exits non-zero naming the first missing id, and prints one JSON record per recommendation tagged `memory` or `capability` Why: the report has no embedded JSON so extraction is structural, and a parser that returns nothing on changed markup would look identical to a report with no suggestions Verify: run the extracted block against tests/fixtures/insights-report/report.html and confirm it prints 5 `memory` records and 7 `capability` records.
3. Write references/already-applied.md shipping an extractable `python3` block that assigns every record one of three statuses — `applied`, `applied-drifted`, `new` — using a per-kind comparison: a `memory` record matches its heading against the target file's headings and then its bullet text with whitespace and punctuation normalised, while a `capability` record matches its prompt against the `name` and `description` frontmatter of the skills already discoverable in the calling project Why: three of five suggestions in a real report are already applied, and a reworded suggestion matched on heading alone would otherwise be skipped silently and its improvement lost; leaving `capability` records unchecked would offer to scaffold a skill the project already ships, on every run Verify: run the extracted block over the fixture pair and confirm the `memory` split is 2 `applied`, 1 `applied-drifted`, 2 `new`, and that a `capability` prompt naming a skill present in the fixture skills directory comes back `applied` rather than `new`.
4. Write references/routing-and-gate.md defining the four destinations — global `CLAUDE.md`, path-scoped `.claude/rules/`, a project skill, a repo plugin — with the shape test that selects each, an availability probe naming the marker path that makes a destination viable in the calling project, and the delegation seams to `agentic-memory-management`, `path-rules-advisor` and `plan-agent:implementation-plan` Why: two destinations are already owned by sibling skills, and the skill runs in whatever project invokes it, so a plain application with no plugin layout must be told a destination is unavailable rather than have one scaffolded into it Verify: `grep -c` finds all four destination names and all three delegate skill names in the file, and every destination names both its owner and its probe path.
5. Write the SKILL.md body: resolve the report path defaulting to `~/.claude/usage-data/report.html` and warning when its modification time is more than 14 days old, present one summary table of every item with its destination, reason and three-way status, exit cleanly with a message when no item is new or drifted, gate on a single question offering apply, plan, or cancel, and copy the target memory file to a timestamped backup before the first write Why: the gate is the only thing standing between a parsed report and writes to unversioned files outside the repository, and a summary that hides already-applied items would make a false match invisible Verify: read the summary contract back and confirm every extracted item appears in the table including the skipped ones, that the all-applied path exits before the gate, and that no write is described before the gate resolves.
6. Create tests/fixtures/insights-report/report.html and tests/fixtures/insights-report/claude-md-before.md as minimal synthetic files carrying all seven section ids, five suggestion blocks of which three match headings in the fixture memory file with one of those three deliberately reworded, and seven paste-prompt blocks, plus tests/fixtures/insights-report/skills/ holding one stub SKILL.md whose `name` and `description` match one of those seven prompts Why: the tests must never read or write a real `~/.claude` file, the drift case has to exist in the fixture or the third detector status ships with no regression cover, and the capability side of the detector needs an existing skill to match against or it ships untested Verify: `grep -c 'id="section-' tests/fixtures/insights-report/report.html` returns 7, the fixture memory file carries exactly 3 of the 5 suggestion headings with one body deliberately differing, and the fixture skills directory contains exactly 1 SKILL.md whose name appears in one of the seven prompts.
7. Add tests/plugins/test-insights-review.sh following the repo's bundle-and-extract pattern, running the shipped parser and detector against the fixtures in a temp directory with a cleanup trap, asserting the 5-and-7 parse split, the 2-applied and 1-drifted and 2-new detector split on the memory records, the `applied` verdict on the capability prompt matching the fixture skill, a non-zero exit naming the id when a section is removed, and that the fixture report is byte-identical after the run, then wire it into .github/workflows/check-plugin-versions.yml Why: this repo's tests execute the code a skill actually ships so a check cannot go green when content moves behind a reference link Verify: `bash tests/plugins/test-insights-review.sh` exits 0, and it exits non-zero when a section id is deleted from a copy of the fixture.
8. Bump memory-tools to 4.2.0 in .claude-plugin/marketplace.json, add the v4.2.0 CHANGELOG entry and a README section documenting the third skill, then regenerate the root table with `node scripts/build-readme-table.mjs` Why: any edit under kit/plugins/ requires a marketplace version bump in the same pull request or the version-guard job fails, and the root plugin table is generated rather than hand-edited Verify: `BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0 and `node scripts/build-readme-table.mjs --check` exits 0.

## Acceptance Criteria

- [ ] `bash tests/plugins/test-insights-review.sh` exits 0
- [ ] The shipped parser extracts exactly 5 memory records and 7 capability records from tests/fixtures/insights-report/report.html
- [ ] The shipped detector splits the 5 fixture memory suggestions into 2 `applied`, 1 `applied-drifted`, and 2 `new`
- [ ] The shipped detector reports a capability prompt as `applied` when a skill with a matching name and description already exists in the calling project, rather than offering to scaffold it again
- [ ] A suggestion whose heading matches but whose bullets differ is reported as `applied-drifted` and appears in the summary rather than being skipped silently
- [ ] Removing a `section-` id from a copy of the fixture report makes the parser exit non-zero with the missing id named in its output
- [ ] Every destination in routing-and-gate.md names both its owning skill and the marker path that makes it available, and an unavailable destination is reported as skipped rather than scaffolded
- [ ] The skill exits with a stated message, before the gate, when no item is `new` or `applied-drifted`
- [ ] The target memory file is copied to a timestamped backup before the first write of an apply run
- [ ] The fixture report is byte-identical before and after the test run, and nothing under `~/.claude/usage-data/` is ever written
- [ ] `python3 tests/plugins/measure_description_budget.py kit/plugins/memory-tools/skills/insights-review/SKILL.md` exits 0, reporting a total of 200 or fewer characters and a first sentence of 80 or fewer
- [ ] `bash tests/plugins/test-exitplanmode-guard.sh` exits 0 with the new skill present
- [ ] `BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0 and marketplace.json records memory-tools at 4.2.0
- [ ] `node scripts/build-readme-table.mjs --check` exits 0
- [ ] No file under tests/ reads from or writes to a path under `~/.claude`

## Tests

Tier 1 — This plan creates skill source files and a new test script that ship with the plugin
- Objective: the skill turns a report into routed, deduplicated recommendations. File: tests/plugins/test-insights-review.sh; Type: integration; Asserts: the parser and detector extracted from the skill's own reference files turn the fixture report into 5 memory and 7 capability records, split the memory records 2 applied and 1 drifted and 2 new, and assign every record one of the four destination names; Run: bash tests/plugins/test-insights-review.sh
- Unit: parser section-id assertions. File: tests/plugins/test-insights-review.sh; Targets: the extractable python3 block in references/parse-report.md; Key cases: all seven ids present, a deleted id exits non-zero naming that id, a report with zero suggestion blocks is reported as empty rather than crashing
- Unit: three-status detection. File: tests/plugins/test-insights-review.sh; Targets: the extractable python3 block in references/already-applied.md; Key cases: heading and bullets both match yields applied, heading matches with reworded bullets yields applied-drifted, heading absent yields new, bullet whitespace and punctuation differences alone do not count as drift, a capability prompt matching an existing skill's name and description yields applied, and a capability prompt with no matching skill yields new
- Integration: read-only treatment of the report. File: tests/plugins/test-insights-review.sh; Targets: the parser invocation path; Key cases: fixture report checksum unchanged after a full parse-and-detect run
- Integration: repo guard suite still passes with the new skill. File: tests/plugins/test-exitplanmode-guard.sh and tests/plugins/measure_description_budget.py; Targets: the new SKILL.md frontmatter and guard line; Key cases: guard string present verbatim, description within the 200-character budget

## Verification

Run `bash tests/plugins/test-insights-review.sh` and confirm it exits 0. The script prints the parsed split, so confirm it reports 5 memory records and 7 capability records, and a detector split of 2 applied, 1 drifted, 2 new — those numbers reproduce the real 2026-08-14 report's shape plus the drift case, and are the regression this plan exists to lock down.

Then exercise the skill end-to-end against a real report without letting it write anything: invoke it on `~/.claude/usage-data/report.html`, confirm the summary table lists every extracted item with a destination and a status, confirm the three sections already present in `~/.claude/CLAUDE.md` (Verification, Formatting & Scope, Ship / PR Workflow) come back as applied or drifted rather than new, and then answer the gate with cancel. Confirm afterwards with `git status --porcelain` in the repo, a modification-time check on `~/.claude/CLAUDE.md`, and a checksum of `~/.claude/usage-data/report.html` that nothing was written in either place.

Finally run the repo guards that the new files must not break: `python3 tests/plugins/measure_description_budget.py kit/plugins/memory-tools/skills/insights-review/SKILL.md` (the script takes a SKILL.md path or `--sweep <dir>` and raises `IndexError` with no argument), `bash tests/plugins/test-exitplanmode-guard.sh`, `BASE_REF=main node scripts/check-plugin-versions.mjs`, and `node scripts/build-readme-table.mjs --check`. All four must exit 0.

## Resources

- docs/prompts/proposal-add-insights-review-skill.md — the converged proposal with the measured report structure and the seven locked decisions
- ~/.claude/usage-data/report-2026-08-14-071004.html — the real report the fixture models, 75,440 bytes
- .claude/rules/plugin-patterns.md — allowed-tools, the plan-mode guard, and the 200-character description format
- .claude/rules/skill-authoring.md — the effective-skills checklist this repo holds skills to
- .claude/rules/testing.md — the one-focused-fixture-per-scenario convention
- tests/plugins/test-memory-doctor-guard.sh — the bundle-and-extract test pattern this plan's test follows

## Next Steps

- Diff two consecutive reports and surface only what changed
  Once the parser is stable, comparing the newest report against the previous one would cut a recurring review to just the new material. Nine reports are already archived locally, so there is a corpus to test against.
  ```text
  In the agentics repo, extend the insights-review skill in kit/plugins/memory-tools
  with a --since flag that parses the two most recent reports under
  ~/.claude/usage-data/ and reports only recommendations absent from the older one.
  Reuse the existing parser in references/parse-report.md rather than writing a
  second one. Add fixtures for the two-report case under tests/fixtures/, extend
  tests/plugins/test-insights-review.sh to cover it, bump the memory-tools minor
  version in .claude-plugin/marketplace.json, and add a CHANGELOG entry. Verify by
  running bash tests/plugins/test-insights-review.sh and confirming it exits 0.
  ```
- Reconcile a drifted suggestion instead of only reporting it
  The three-status detector flags reworded suggestions but leaves the merge to you. A guided reconcile would show the wording difference and offer to adopt, keep, or merge.
  ```text
  In the agentics repo, extend the insights-review skill in kit/plugins/memory-tools
  so an applied-drifted recommendation can be reconciled: show a line-level diff
  between the report's wording and the text currently in the target file, then offer
  adopt, keep, or merge. Do not auto-merge. Add a fixture case under
  tests/fixtures/insights-report/ and extend tests/plugins/test-insights-review.sh,
  bump the memory-tools minor version in .claude-plugin/marketplace.json, and add a
  CHANGELOG entry. Verify by running bash tests/plugins/test-insights-review.sh and
  confirming it exits 0.
  ```
- Wish list: route friction patterns into hook configurations
  The report's friction section often describes something a PreToolUse hook could block outright rather than a rule asking Claude not to do it. This would add a fifth destination and needs its own design pass.
  ```text
  In the agentics repo, research whether the friction entries in a Claude Code
  /insights report (section-friction) can be mechanically turned into hook
  configurations in .claude/settings.json, the way the hookify plugin generates
  hooks. Report on which friction shapes are hook-shaped versus rule-shaped, and
  recommend whether the insights-review skill in kit/plugins/memory-tools should
  gain a fifth destination. Produce a written recommendation only; do not
  implement. Verify by confirming the recommendation names at least three real
  friction entries from a report and classifies each one.
  ```
