---
status: completed
type: refactor
created: 2026-07-27
effort: high
glance: Six skills across five plugins each dump between 1,202 and 3,153 words into context every single time they fire, and the largest of them is the rubric that tells every other skill not to do that. We will know it worked when each core reads under 600 words, every reference file resolves from a link in its own core, and the blocking security-scrub gate is still sitting in both artifact-tools cores where the model cannot fail to load it.
workflow: true
---

# Plan: Stop paying 10,545 words every time these six skills fire

## Objective

Split the six remaining monolithic SKILL.md files — across `skill-reviewer`, `artifact-tools`, `memory-tools`, `content-tools`, and `code-testing-agent` — into small cores plus per-topic reference files, each core under 600 words, with every skill's behavior and frontmatter `description` left byte-identical.

## Context

Anthropic's "The new rules of context engineering for Claude 5 generation models" makes progressive disclosure (Rule 3) the load-bearing rule for skills: move detail out of the always-loaded body into references the model pulls on demand, and split long skills into multiple files. A SKILL.md body is paid in **full** whenever the skill triggers — there is no partial load, no lazy tail. A measured audit of this repo found 17 SKILL.md files over 1,200 words shipping as a single file with zero sibling files. This plan takes the last six of them: `optimizing-skill-frontmatter` (3,153 words), `prompt-artifact` (1,665), `diff-artifact` (1,549), `path-rules-advisor` (1,546), `artifact-to-post` (1,430), and `tdd-fix` (1,202) — 10,545 words across five plugins.

The pattern is already proven in-repo and is not being invented here. `plan-agent/skills/implementation-plan/` ships a core plus `guidelines/` and `reference/SKELETON.md`; `code-testing-agent` carries `references/` on four of its five skills; `wcag-compliance-reviewer` and `skill-reviewer/reviewing-skills` do the same. The alternative — trimming prose in place per Rule 1 (judgment over rules) — was weighed and rejected as the primary move for these six: it deletes information rather than relocating it, and these bodies are mostly executable mechanics (bash blocks, escaping tables, apply rules) that the model genuinely needs *once it is already mid-step*. Trimming is a follow-up, not this plan.

Three hazards shape the work. **First, `optimizing-skill-frontmatter` is self-referential.** It is `skill-reviewer`'s own authoring rubric — the file that defines the three-part description format, the ≤200-char budget, and the ≤80-char first sentence that everything else in the repo is measured against. Splitting the rubric that governs skill authoring means the split must itself satisfy the rubric it teaches, or the plugin ships advice it visibly ignores. Mitigation: Step 9 runs `/skill-reviewer:reviewing-skills` against the split core and requires a passing score, and the split must not touch its own `description:`.

**Second, `diff-artifact` and `prompt-artifact` both run a blocking `security-scrub` gate before publishing.** Publishing is outward-facing and irreversible; a gate the model does not load is a secret leak, not a style regression. That gate — the `security-scrub` invocation, the `GATE RESULT: BLOCKED` / `CANCELLED` / `APPROVED` verdicts, and the hard-stop language — stays in the core of both skills, and so does the second rescan of the rendered page in `diff-artifact` Step 5. Mitigation: the objective test asserts the gate is present in the core (not merely somewhere under the plugin), and `tests/plugins/test-artifact-tools.sh` already asserts the gate is documented *before* the `select:Artifact` publish bootstrap by line order — that ordering assertion stays anchored on the core file.

**Third, each plugin already has a layout, and this plan matches it rather than imposing one.** `artifact-tools` puts references at the plugin level (`kit/plugins/artifact-tools/references/titles.md`, read via `${CLAUDE_PLUGIN_ROOT}/references/`), and so does `content-tools` (`references/content-config.md`, `references/mdx-safety.md`, read via `$SKILL_DIR/../../references/`). `code-testing-agent`, `memory-tools`, and `skill-reviewer` put them per-skill (`skills/<name>/references/`). Both are correct; mixing them inside one plugin is what breaks reader expectations.

The real blast radius is the tests, and it is wider than the six files. Four existing tests read these skill bodies as data and will fail the moment content moves: `tests/plugins/test-artifact-tools.sh` greps literals from `diff-artifact` and `prompt-artifact` (`cap-and-summarize`, `16 MiB`, `sticky file sidebar`, `prefers-color-scheme`, `severity legend`, `git remote get-url origin`, `16 * 1024 * 1024`, the `${DEFAULT_BRANCH}...HEAD` fallback line); `tests/plugins/test-artifact-to-post.sh` greps config keys and compares `## Phase 5` / `## Phase 6` line numbers; `tests/plugins/test-memory-doctor-guard.sh` *extracts the bash and python parse check out of `path-rules-advisor/SKILL.md` and executes it*, and separately derives commands from its ` ```bash ` blocks to check `allowed-tools` coverage; `tests/plugins/test-generator-skills-verify-output.sh` requires a `## Step N — Publish` heading in both artifact skills and the literal `run [Verify the write](#verify-the-write)` link in `path-rules-advisor`. Mitigation: every step that moves content also updates the test that reads it, in the same step, and the step's Verify runs that test.

One deliberate decision worth flagging: in `path-rules-advisor` the executable parse check moves to `references/write-verification.md` while the *rule* it enforces (run it after every write; on non-zero exit STOP and report) stays in the core. Keeping the 400-word block inline would leave that core near 700 words. The risk is that a safety check behind a reference is a safety check that might not load — mitigated by keeping the STOP contract in the core, keeping the in-core link, and repointing `test-generator-skills-verify-output.sh` at the reference so the wiring is still asserted.

Five plugins are touched, so five `marketplace.json` version bumps and five CHANGELOG entries are required — the widest blast radius of the three splitting plans. `artifact-tools` additionally requires its CHANGELOG heading in the exact `## [1.8.0] - YYYY-MM-DD` form, because `tests/plugins/test-artifact-tools.sh` asserts the marketplace version equals the newest `## [x.y.z]` heading.

## Files

- kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md (modified) — core keeps overview, `## When not to use`, and Step 0–6 names; mechanics move out
- kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references/description-rules.md (new) — Rules 1, 2, 2b, 3, 4, 5 plus worked examples A and B
- kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references/invocation-control.md (new) — Step 4b classification table, confirmation options, and the grep-then-Edit apply rules
- kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references/measurement.md (new) — the Step 2, Step 5, and Step 6 bash measuring loops
- kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references/budget-advisory.md (new) — the `skillListingBudgetFraction` advisory, the installed-skills table, and the `/doctor` guidance
- kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md (modified) — core keeps mode selection, both hard-stop confirmations, and the write-verification rule
- kit/plugins/memory-tools/skills/path-rules-advisor/references/rule-modes.md (new) — Mode A Steps 1–7 and Mode B Steps 1–7 in full
- kit/plugins/memory-tools/skills/path-rules-advisor/references/rule-file-format.md (new) — the generated-file template, brace expansion, and the Notes section
- kit/plugins/memory-tools/skills/path-rules-advisor/references/write-verification.md (new) — the diff-back bash plus the python frontmatter parse check and the pre-write gate
- kit/plugins/code-testing-agent/skills/tdd-fix/SKILL.md (modified) — core keeps the freedom-level marker, `## When not to use`, and Step 0–9 names
- kit/plugins/code-testing-agent/skills/tdd-fix/references/fix-loop.md (new) — Step 2 red phase, Step 3 iteration log and 3a–3c, Step 4 hard cap
- kit/plugins/code-testing-agent/skills/tdd-fix/references/handoff.md (new) — Step 5 regression sweep, Step 6 summary block, Steps 7–8 commit-agent and pr-agent handoffs
- kit/plugins/content-tools/skills/artifact-to-post/SKILL.md (modified) — core keeps Phase 0 asset locating, the Phase 2 scrub gate verbatim, and Phase 1–10 names
- kit/plugins/content-tools/references/source-resolution.md (new) — the Phase 1 source table, the claude.ai refusal text, and the "It skips nothing else." Markdown-source rule
- kit/plugins/content-tools/references/post-assembly.md (new) — Phase 4 extraction and ceiling behavior, Phase 5 prose rewrite, Phase 7 screenshots, Phase 8 write, Phase 10 publish gate
- kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md (modified) — core keeps the Step 2 scrub gate, the Step 5 rescan, and Step 1–8 headings
- kit/plugins/artifact-tools/references/diff-sources.md (new) — mode table, default-branch resolution, and the PR-mode degradation script
- kit/plugins/artifact-tools/references/diff-page.md (new) — severity table, cap-and-summarize budget, page requirements, and the 16 MiB shrink loop
- kit/plugins/artifact-tools/references/diff-publishing.md (new) — durable-copy keying, publish and URL recording, failure fallback, render verification
- kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md (modified) — core keeps the Step 4 scrub gate, the empty-library stop, and Step 1–8 headings
- kit/plugins/artifact-tools/references/prompt-resolution.md (new) — mode table, the `PROMPTS_DIR` python resolver, and single/library prompt resolution
- kit/plugins/artifact-tools/references/prompt-page.md (new) — page requirements, the six-value escaping table, and the copy-button script with its three failure modes
- kit/plugins/artifact-tools/references/prompt-publishing.md (new) — the URL-record table, the `.artifact-url` sidecar, render verification, and the fallback
- tests/plugins/test-remaining-skill-splits.sh (new) — objective-verification test for all six splits
- tests/plugins/test-artifact-tools.sh (modified) — literal assertions follow the moved content into `references/`
- tests/plugins/test-artifact-to-post.sh (modified) — config-key and ladder assertions follow the moved content
- tests/plugins/test-memory-doctor-guard.sh (modified) — extracts the parse check and the bash commands from core plus references
- tests/plugins/test-generator-skills-verify-output.sh (modified) — `path-rules-advisor` wiring regex repointed at the reference link
- .github/workflows/check-plugin-versions.yml (modified) — new step running the objective test
- .claude-plugin/marketplace.json (modified) — five minor version bumps
- kit/plugins/skill-reviewer/CHANGELOG.md (modified) — v2.3.0 entry
- kit/plugins/memory-tools/CHANGELOG.md (modified) — v4.1.0 entry
- kit/plugins/code-testing-agent/CHANGELOG.md (modified) — v3.5.0 entry
- kit/plugins/content-tools/CHANGELOG.md (modified) — 1.1.0 entry
- kit/plugins/artifact-tools/CHANGELOG.md (modified) — `## [1.8.0]` entry in bracketed form

## Steps

1. [x] Record a pre-split baseline into the scratchpad: `for f in <the six SKILL.md paths>; do echo "$(wc -w < $f) $f"; done` plus `git show origin/main:<path> | sed -n '1,6p'` for each, capturing every `description:` line verbatim. Why: the split is only correct if word counts fall and descriptions do not move, and neither claim is checkable later without the before-state. Verify: the scratchpad file lists six word counts summing to 10,545 and six `description:` lines.
2. [x] Split `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md` into a core plus `references/description-rules.md`, `references/invocation-control.md`, `references/measurement.md`, and `references/budget-advisory.md`, linking each from the step that needs it and leaving `description:`, `allowed-tools:`, and `disable-model-invocation: true` untouched. Why: at 3,153 words it is the single largest monolithic skill in the repo, and it is the rubric every other skill is judged against — it cannot keep violating its own progressive-disclosure advice. Verify: `wc -w < kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md` is under 600 and `git diff origin/main -- kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md | grep '^[-+]description:'` prints nothing.
3. [x] Split `kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md` into a core plus `references/rule-modes.md`, `references/rule-file-format.md`, and `references/write-verification.md`, keeping the "run this after every write, STOP on non-zero" rule and the pre-write gate sentence in the core, then update `tests/plugins/test-memory-doctor-guard.sh` to extract the parse check and the bash commands from the core *and* its `references/*.md`, and repoint the `path-rules-advisor` wiring regex in `tests/plugins/test-generator-skills-verify-output.sh` at the reference link. Why: two tests execute code lifted straight out of this body, so moving it without moving their extraction turns a passing safety guard into a silent no-op. Verify: `bash tests/plugins/test-memory-doctor-guard.sh` and `bash tests/plugins/test-generator-skills-verify-output.sh` both exit 0, and the core is under 600 words.
4. [x] Split `kit/plugins/code-testing-agent/skills/tdd-fix/SKILL.md` into a core plus `references/fix-loop.md` and `references/handoff.md`, matching the per-skill `references/` layout its four siblings (`code-testing-agent`, `reviewing-tests`, `running-tests`, `tdd-loop`) already use. Why: `tdd-fix` is the only skill in its plugin without a `references/` dir, so this is the one split that costs nothing in convention design. Verify: `ls -d kit/plugins/code-testing-agent/skills/*/references | wc -l` prints 5 (up from 4) and `wc -w < kit/plugins/code-testing-agent/skills/tdd-fix/SKILL.md` is under 600.
5. [x] Split `kit/plugins/content-tools/skills/artifact-to-post/SKILL.md` into a core plus `kit/plugins/content-tools/references/source-resolution.md` and `references/post-assembly.md` at the plugin level beside the existing `content-config.md` and `mdx-safety.md`, keeping the Phase 2 scrub gate and its `write nothing and end the turn` language in the core, then update `tests/plugins/test-artifact-to-post.sh` so the config-key, literal, and ladder assertions read whichever file now holds them. Why: this plugin already resolves references as `$SKILL_DIR/../../references/`, and a second per-skill dir would give one plugin two conventions. Verify: `bash tests/plugins/test-artifact-to-post.sh` exits 0 and the core is under 600 words.
6. [x] Split `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` into a core plus `references/diff-sources.md`, `references/diff-page.md`, and `references/diff-publishing.md` at the plugin level, keeping the Step 2 scrub gate, the Step 5 rendered-page rescan, and every `## Step N — ` heading in the core. Why: the gate is what stands between a diff and an irreversible external publish, and `test-generator-skills-verify-output.sh` matches the `## Step N — Publish` heading in this file. Verify: `grep -c 'security-scrub' kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` is at least 2 and the core is under 600 words.
7. [x] Split `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` into a core plus `references/prompt-resolution.md`, `references/prompt-page.md`, and `references/prompt-publishing.md`, keeping the Step 4 scrub gate and the never-publish-an-empty-gallery stop in the core, then update `tests/plugins/test-artifact-tools.sh` so each moved literal is asserted against the reference that now holds it while the scrub-before-publish ordering check stays anchored on both cores. Why: that ordering check is the only thing proving content cannot ship unscanned, and it is meaningless if it starts reading a reference file the model may never load. Verify: `bash tests/plugins/test-artifact-tools.sh` exits 0 and both artifact-tools cores are under 600 words.
8. [x] Write `tests/plugins/test-remaining-skill-splits.sh` asserting all four objective conditions for the six targets, and wire it into `.github/workflows/check-plugin-versions.yml` as a named step after the existing `test-merge-gallery-index.sh` step. Why: without CI wiring the guarantee decays on the next edit, and this repo has no test runner that would pick the file up on its own. Verify: `bash tests/plugins/test-remaining-skill-splits.sh` exits 0 and `grep -c test-remaining-skill-splits .github/workflows/check-plugin-versions.yml` returns 1.
9. [x] Bump `skill-reviewer` to 2.3.0, `memory-tools` to 4.1.0, `code-testing-agent` to 3.5.0, `content-tools` to 1.1.0, and `artifact-tools` to 1.8.0 in `.claude-plugin/marketplace.json`, add a matching CHANGELOG entry to each plugin (artifact-tools using the bracketed `## [1.8.0] - 2026-07-27` heading its own test parses), and add no `version` key to any `plugin.json`. Why: any edit under `kit/plugins/<name>/` requires a bump higher than main, and artifact-tools' test fails if its marketplace version and newest CHANGELOG heading disagree. Verify: `BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0 and `bash tests/plugins/test-artifact-tools.sh` exits 0.

## Tests

Tier 1 — This plan changes application code

- Objective: proves the split actually landed and did not gut a safety gate. File: tests/plugins/test-remaining-skill-splits.sh; Type: smoke; Asserts: each of the six SKILL.md cores is under 600 words, each has at least two reference files in the directory its plugin's convention dictates, every `references/*.md` path mentioned in a core resolves to a file on disk, every reference file on disk is linked from at least one core (no orphans), and `security-scrub` plus `GATE RESULT: BLOCKED` plus hard-stop language appear in the *core* of both `diff-artifact` and `prompt-artifact`; Run: bash tests/plugins/test-remaining-skill-splits.sh
- Unit: frontmatter is untouched by the split. File: tests/plugins/test-remaining-skill-splits.sh; Targets: the `description:`, `name:`, `allowed-tools:`, and `disable-model-invocation:` lines of all six targets; Key cases: each line is byte-identical to `git show origin/main:<path>`; a deliberately reworded description fails the check
- Unit: artifact-tools contract survives relocation. File: tests/plugins/test-artifact-tools.sh; Targets: diff-artifact and prompt-artifact cores plus their six new references; Key cases: scrub gate precedes `select:Artifact` in the core; `cap-and-summarize`, `16 MiB`, `sticky file sidebar`, `severity legend`, `prefers-color-scheme`, `16 * 1024 * 1024`, `git remote get-url origin`, and the `${DEFAULT_BRANCH}...HEAD` fallback line each still assert against the file that now holds them; the inbox key is still not date-derived
- Unit: artifact-to-post contract survives relocation. File: tests/plugins/test-artifact-to-post.sh; Targets: the artifact-to-post core and the two new content-tools references; Key cases: Phase 5 still precedes Phase 6 in the core; `write nothing and end the turn` stays in the core; all six config keys and `no block is ever dropped` still resolve; no hardcoded site literal reappears
- Unit: memory-tools write guard still executes real shipped code. File: tests/plugins/test-memory-doctor-guard.sh; Targets: path-rules-advisor core plus `references/write-verification.md`; Key cases: the parse check extracted from the reference rejects unterminated frontmatter and accepts valid frontmatter; the `allowed-tools` coverage scan still finds at least two commands after the bash blocks move
- Unit: description budget sweep is unaffected. File: tests/plugins/test-description-budget.sh; Targets: every shipped SKILL.md; Key cases: all six split cores still pass the ≤200 total and ≤80 first-sentence limits

## Acceptance Criteria

- [x] `wc -w` on each of the six target SKILL.md files returns under 600, against a pre-split total of 10,545 words — measured 10,451 by `wc -w` against `origin/main` (3,058 + 1,831 + 1,489 + 1,519 + 1,367 + 1,187); the plan's 10,545 came from a different counter. Post-split total is 3,431: 573 / 594 / 582 / 513 / 581 / 588
- [x] 17 new reference files exist, placed per-skill under `skill-reviewer`, `memory-tools`, and `code-testing-agent`, and at plugin level under `artifact-tools` and `content-tools`
- [x] `bash tests/plugins/test-remaining-skill-splits.sh` exits 0
- [x] Every `references/` path named in a split core resolves to an existing file, and no reference file is orphaned from every core
- [x] `grep -n 'security-scrub' kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` shows the gate in both cores, ahead of the `select:Artifact` line in each
- [x] `git diff origin/main -- '*/SKILL.md' | grep '^[-+]description:'` prints nothing
- [x] `BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0 with skill-reviewer 2.3.0, memory-tools 4.1.0, code-testing-agent 3.5.0, content-tools 1.1.0, and artifact-tools **1.9.0** — `main` already ships artifact-tools 1.8.0, so the planned 1.8.0 could not clear the version guard; the next minor is 1.9.0, and its CHANGELOG heading is `## [1.9.0] - 2026-07-29`
- [x] Each of the five touched plugins has a CHANGELOG entry naming its new version, and no `plugin.json` gained a `version` key
- [x] `bash tests/plugins/test-artifact-tools.sh`, `bash tests/plugins/test-artifact-to-post.sh`, `bash tests/plugins/test-memory-doctor-guard.sh`, `bash tests/plugins/test-generator-skills-verify-output.sh`, and `bash tests/plugins/test-description-budget.sh` all exit 0
- [x] `.github/workflows/check-plugin-versions.yml` contains a step running `tests/plugins/test-remaining-skill-splits.sh`

## Verification

Run the full local gate in one pass: `bash tests/plugins/test-remaining-skill-splits.sh && bash tests/plugins/test-artifact-tools.sh && bash tests/plugins/test-artifact-to-post.sh && bash tests/plugins/test-memory-doctor-guard.sh && bash tests/plugins/test-generator-skills-verify-output.sh && bash tests/plugins/test-description-budget.sh && BASE_REF=main node scripts/check-plugin-versions.mjs`. Expected result: every command exits 0 and the objective test prints six word counts, all under 600.

Then prove the objective test is not a tautology, one break at a time, reverting after each. Delete the `security-scrub` paragraph from `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` and confirm `bash tests/plugins/test-remaining-skill-splits.sh` exits 1 naming the missing gate; restore it. Change one `references/` link in the `optimizing-skill-frontmatter` core to a filename that does not exist and confirm the test exits 1 on the unresolved reference; restore it. Paste roughly 400 words of the moved rules back into that same core and confirm the test exits 1 on the word ceiling; restore it. A test that passes through all three breaks is measuring nothing.

Behavioral verification is the part word counts cannot cover, and it is not optional. Load the five plugins locally (`claude --plugin-dir kit/plugins/skill-reviewer --plugin-dir kit/plugins/artifact-tools --plugin-dir kit/plugins/memory-tools --plugin-dir kit/plugins/content-tools --plugin-dir kit/plugins/code-testing-agent`) and actually invoke each split skill: run `optimizing-skill-frontmatter` against a throwaway SKILL.md fixture in a temp dir and confirm it still reaches the rewrite rules, the invocation-control table, and the budget advisory by reading the references; run `path-rules-advisor` in Mode A against a scratch repo and confirm it still asks before writing and still runs the parse check after; run `artifact-to-post` against `tests/fixtures/artifact-to-post/sample-artifact.html` and confirm it stops at the scrub gate rather than writing; run `diff-artifact` and `prompt-artifact` far enough to observe the scrub gate fire from the core before any publish; run `tdd-fix` against `tests/demo/` and confirm it still writes a failing test and enters the loop. Any skill that stalls, skips a step, or fails to pull a reference it needs is a failed split regardless of its word count — report it and fix it rather than recording the plan as complete. Finally, run `/skill-reviewer:reviewing-skills` against `optimizing-skill-frontmatter` itself: the rubric must pass its own audit, including the reference-depth-≤1 and progressive-disclosure criteria it defines, since it is now both the judge and the subject. Clean up every temp dir the verification creates.

**Recorded outcome.** The full local gate passes: all six objective checks, the five
named unit tests, `check-plugin-versions.mjs`, and the whole `tests/plugins/` suite
(43 files, 0 failures). All four tautology breaks were exercised and each fails the
objective test, restoring green after revert: the deleted `security-scrub` paragraph
(`core gate lost in: prompt-artifact`), a `references/` link renamed to a
non-existent file (both the unresolved pointer *and* the resulting orphan), ~400
words of moved rules pasted back into the `optimizing-skill-frontmatter` core (965
words, over the ceiling), and a reworded `description:` (`frontmatter drifted:
tdd-fix:[description]`).

Behavioural verification ran all six skills through `claude -p` with the plugins
loaded, in throwaway temp dirs (since removed). Every skill reached and read the
references it needed, and every gate held: `optimizing-skill-frontmatter` read all
four references at the right steps and rewrote a fixture description to three-part
form; `path-rules-advisor` read `rule-modes.md`, `rule-file-format.md`, and
`write-verification.md`, and refused to write without explicit confirmation;
`artifact-to-post` stopped dead at the Phase 2 gate and wrote nothing;
`diff-artifact` ran the default-branch resolution out of `diff-sources.md` and then
stopped at the Step 2 gate before building a page; `prompt-artifact` read all four
references, ran the `PROMPTS_DIR` resolver, and stopped at the Step 4 gate with no
page written and no URL recorded; `tdd-fix` wrote a failing test, confirmed it red,
entered the loop, fixed the bug in one iteration, swept the suite green, and printed
the summary block.

Two verification limits worth recording rather than glossing. **First**, the live
post-write parse check could not be observed end-to-end: this container blocks
headless writes under `.claude/`, so `path-rules-advisor` never got to run the check
on a file it had just written. The read half is confirmed (it loads
`write-verification.md` *before* writing), and the executable half is covered better
than a live run would cover it — `test-memory-doctor-guard.sh` extracts the real
shipped block from the reference and runs it against ten fixtures including the
malformed and empty-body negatives. **Second**, `tests/demo/calculator.sh` no longer
carries the bug its own comment describes (`add()` is already `+`), so the first
`tdd-fix` run correctly hit Step 2's passing-test hard stop; the loop was exercised
on a temp copy with the operator flipped back.

Two deviations from the plan as written, both to reach the plan's own outcome.
**`test-generator-skills-verify-output.sh` was left unmodified.** The plan called for
repointing its `path-rules-advisor` wiring regex at the reference; instead the core
keeps the three `run [Verify the write](#verify-the-write)` call sites the existing
regex already matches, so the wiring stays asserted with no test churn — and the new
objective test separately proves the core's `references/write-verification.md`
pointer resolves. **`test-proposal-prompt-pipeline.sh` needed a change the plan did
not anticipate**: its check 8 greps `prompt-artifact`'s SKILL.md for the five library
filter chips and the tolerant-frontmatter rule, both of which moved into
`prompt-page.md` and `prompt-resolution.md`. It now reads the core plus those two, so
it still fails if a chip is dropped.

## Next Steps

- Trim the split cores under Rule 1 (judgment over rules)
    Progressive disclosure moved the words; it did not ask whether they were needed. The cores likely still carry hedging and restated constraints that a Claude 5 model does not require.

    ```text
    In the agentics repo (a Claude Code plugin marketplace), the six SKILL.md cores at
    kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md,
    kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md,
    kit/plugins/code-testing-agent/skills/tdd-fix/SKILL.md,
    kit/plugins/content-tools/skills/artifact-to-post/SKILL.md,
    kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md, and
    kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md were recently split into a
    small core plus reference files. Apply Rule 1 and Rule 4 from Anthropic's "The new rules
    of context engineering for Claude 5 generation models": remove restated constraints,
    hedging, and instructions the model does not need told twice. Do NOT touch any
    frontmatter `description:` value, do NOT remove any security-scrub gate or hard-stop
    language from the artifact-tools cores, and do NOT move content between files. Bump every
    touched plugin's version in .claude-plugin/marketplace.json (patch), add a CHANGELOG entry
    under kit/plugins/<name>/CHANGELOG.md for each, and verify with
    `BASE_REF=main node scripts/check-plugin-versions.mjs`,
    `bash tests/plugins/test-remaining-skill-splits.sh`, and
    `bash tests/plugins/test-description-budget.sh` — all three must exit 0.
    ```

- Enforce the 600-word core ceiling repo-wide
    Six skills are now compliant and roughly a dozen more are not; nothing stops a new skill from shipping at 2,000 words in one file.

    ```text
    In the agentics repo (a Claude Code plugin marketplace, no package.json and no test
    runner — tests are standalone files under tests/plugins/ wired individually into
    .github/workflows/check-plugin-versions.yml), write
    tests/plugins/test-skill-core-ceiling.sh. It must sweep every
    kit/plugins/*/skills/*/SKILL.md, warn on any body over 600 words that has no sibling
    reference files, and fail on any body over 1,200 words with no sibling reference files.
    Ship an explicit allowlist of currently-failing paths so the test lands green, with a
    comment naming each one. Wire it into .github/workflows/check-plugin-versions.yml as its
    own named step. No plugin files change, so no marketplace.json version bump or CHANGELOG
    entry is needed — say so explicitly in the PR description. Verify by running
    `bash tests/plugins/test-skill-core-ceiling.sh` (expect exit 0), then temporarily removing
    one path from the allowlist and confirming it exits 1.
    ```

## Resources

- The new rules of context engineering for Claude 5 generation models — https://claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models — Rules 1, 3, and 4 are the whole basis for this plan; Rule 3 is why a core-plus-references layout beats a single long body.
- kit/plugins/plan-agent/skills/implementation-plan/ — the in-repo reference implementation of the pattern: a core plus `guidelines/` and `reference/SKELETON.md`.
- kit/plugins/code-testing-agent/skills/running-tests/SKILL.md — a 638-word core that loads `references/test-runner-guide.md` section by section; the linking idiom to copy.
- kit/plugins/skill-reviewer/skills/reviewing-skills/references/ — shows the per-skill `references/` layout that `skill-reviewer` and `memory-tools` already use.
- kit/plugins/artifact-tools/references/titles.md — proof that `artifact-tools` resolves references at plugin level via `${CLAUDE_PLUGIN_ROOT}/references/`, which the two artifact splits must match.
- tests/plugins/test-artifact-tools.sh — the scrub-gate ordering assertion and the literal greps this plan has to keep working.
- tests/plugins/test-memory-doctor-guard.sh — extracts and executes code out of `path-rules-advisor/SKILL.md`; the reason Step 3 updates it in the same step.
- .claude/rules/marketplace.md — the versioning table that makes a split a MINOR bump, and the rule that `version` never goes in `plugin.json`.
- .claude/rules/skill-authoring.md — Anthropic's effective-skills checklist, including "additional details are in separate files" and "file references are one level deep".
