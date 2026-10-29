# Stop Paying 10,545 Words Every Time These Six Skills Fire

> Six skills across five plugins each dump between 1,202 and 3,153 words into context every single time they fire, and the largest of them is the rubric that tells every other skill not to do that. We will know it worked when each core reads under 600 words, every reference file resolves from a link in its own core, and the blocking security-scrub gate is still sitting in both artifact-tools cores where the model cannot fail to load it.

<!-- generated:start -->

**Status:** Shipped 2026-07-29  **Plan:** [split-remaining-plugin-skills.md](plans/split-remaining-plugin-skills.md)
**Type:** refactor

## What shipped

- Split six monolithic SKILL.md files across five plugins into small cores (566–583 words each, post-split) plus 17 new reference files: `optimizing-skill-frontmatter` (4 references), `path-rules-advisor` (3 references), `tdd-fix` (2 references), `artifact-to-post` (2 references at plugin level), `diff-artifact` (3 references at plugin level), `prompt-artifact` (3 references at plugin level).
- Kept the `security-scrub` gate and all hard-stop language in the cores of both `diff-artifact` and `prompt-artifact` — never behind a reference — so the gate is always loaded before any publish.
- Kept the `write-verification` rule and STOP contract in the `path-rules-advisor` core, with the executable parse-check block moved to `references/write-verification.md`.
- Updated four existing tests to resolve assertions across cores and references: `test-artifact-tools.sh`, `test-artifact-to-post.sh`, `test-memory-doctor-guard.sh`, `test-generator-skills-verify-output.sh`.
- Added `tests/plugins/test-remaining-skill-splits.sh` asserting: cores under 600 words (Python counter, locale-independent), at least two reference files per skill, all links resolve, no orphans, and security-scrub gate present in both artifact-tools cores.
- Wired the new test and five previously-unwired tests into `.github/workflows/check-plugin-versions.yml`.
- Bumped five plugins: `skill-reviewer` to 2.4.0 (main had reached 2.3.0), `memory-tools` to 4.1.0, `code-testing-agent` to 3.5.0, `content-tools` to 1.1.0, `artifact-tools` to 1.9.0 (main had already shipped 1.8.0).

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md` | Core — overview, When not to use, step names | Modified |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references/description-rules.md` | Reference — Rules 1–5 and worked examples | Created |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references/invocation-control.md` | Reference — Step 4b classification table, apply rules | Created |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references/measurement.md` | Reference — measuring loops for Steps 2, 5, 6 | Created |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references/budget-advisory.md` | Reference — budget fraction advisory and `/doctor` guidance | Created |
| `kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md` | Core — mode selection, hard-stop confirmations, write-verification rule | Modified |
| `kit/plugins/memory-tools/skills/path-rules-advisor/references/rule-modes.md` | Reference — Mode A and Mode B steps in full | Created |
| `kit/plugins/memory-tools/skills/path-rules-advisor/references/rule-file-format.md` | Reference — generated-file template and brace expansion | Created |
| `kit/plugins/memory-tools/skills/path-rules-advisor/references/write-verification.md` | Reference — diff-back bash and python frontmatter parse check | Created |
| `kit/plugins/code-testing-agent/skills/tdd-fix/SKILL.md` | Core — freedom-level marker, When not to use, step names | Modified |
| `kit/plugins/code-testing-agent/skills/tdd-fix/references/fix-loop.md` | Reference — Step 2 red phase, Step 3 iteration log, hard cap | Created |
| `kit/plugins/code-testing-agent/skills/tdd-fix/references/handoff.md` | Reference — regression sweep, summary block, commit/pr handoffs | Created |
| `kit/plugins/content-tools/skills/artifact-to-post/SKILL.md` | Core — Phase 0 asset locating, Phase 2 scrub gate, phase names | Modified |
| `kit/plugins/content-tools/references/source-resolution.md` | Reference — Phase 1 source table and Markdown-source rule | Created |
| `kit/plugins/content-tools/references/post-assembly.md` | Reference — Phase 4–5 extraction, Phase 7–8 write, Phase 10 publish gate | Created |
| `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` | Core — Step 2 scrub gate, Step 5 rescan, step headings | Modified |
| `kit/plugins/artifact-tools/references/diff-sources.md` | Reference — mode table, default-branch resolution, PR-mode degradation | Created |
| `kit/plugins/artifact-tools/references/diff-page.md` | Reference — severity table, cap-and-summarize budget, 16 MiB shrink loop | Created |
| `kit/plugins/artifact-tools/references/diff-publishing.md` | Reference — durable-copy keying, publish, URL recording, failure fallback | Created |
| `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` | Core — Step 4 scrub gate, empty-library stop, step headings | Modified |
| `kit/plugins/artifact-tools/references/prompt-resolution.md` | Reference — mode table, PROMPTS_DIR resolver, library resolution | Created |
| `kit/plugins/artifact-tools/references/prompt-page.md` | Reference — page requirements, escaping table, copy-button script | Created |
| `kit/plugins/artifact-tools/references/prompt-publishing.md` | Reference — URL-record table, sidecar, render verification, fallback | Created |
| `tests/plugins/test-remaining-skill-splits.sh` | Test — objective verification for all six splits | Created |
| `tests/plugins/test-artifact-tools.sh` | Test — literal assertions follow moved content into references/ | Modified |
| `tests/plugins/test-artifact-to-post.sh` | Test — config-key and ladder assertions follow moved content | Modified |
| `tests/plugins/test-memory-doctor-guard.sh` | Test — extracts parse check from core plus references | Modified |
| `tests/plugins/test-generator-skills-verify-output.sh` | Test — path-rules-advisor wiring assertion stays in core | Modified |
| `.github/workflows/check-plugin-versions.yml` | CI workflow — new test step and five previously-unwired tests | Modified |
| `.claude-plugin/marketplace.json` | Marketplace manifest — five minor version bumps | Modified |
| `kit/plugins/skill-reviewer/CHANGELOG.md` | Plugin changelog — version entry | Modified |
| `kit/plugins/memory-tools/CHANGELOG.md` | Plugin changelog — version entry | Modified |
| `kit/plugins/code-testing-agent/CHANGELOG.md` | Plugin changelog — version entry | Modified |
| `kit/plugins/content-tools/CHANGELOG.md` | Plugin changelog — version entry | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | Plugin changelog — `## [1.9.0]` bracketed entry | Modified |

## How it works

The six target skills were the last of 17 SKILL.md files identified in a repo-wide audit as exceeding 1,200 words with no sibling reference files. The `split-plan-agent-skills` plan handled five in `plan-agent`; this plan takes the remaining six across five different plugins. The pre-split total was 10,681 words by the canonical Python counter (locale-independent); post-split the six cores total 3,392 words — a 68% reduction. The plan's own 10,545 figure and an early `wc -w` pass of 10,451 are both C-locale undercounts of multibyte characters (`—`, `≤`, `→`); the test counts in Python for this reason.

Each plugin already had a reference file convention, and this plan matched it rather than imposing a new one. `artifact-tools` and `content-tools` put references at the plugin level (`kit/plugins/<name>/references/`), read via `${CLAUDE_PLUGIN_ROOT}/references/` and `$SKILL_DIR/../../references/` respectively. `skill-reviewer`, `memory-tools`, and `code-testing-agent` put them per-skill (`skills/<name>/references/`). Mixing conventions inside one plugin was explicitly avoided.

The security-scrub gate in `diff-artifact` and `prompt-artifact` was the most risk-sensitive item. Publishing is outward-facing and irreversible; a gate behind a reference file that the model might not load is a secret leak. Both cores retained the `security-scrub` invocation, the GATE RESULT verdicts, and the hard-stop language. The test asserts the gate is present in the core and precedes the `select:Artifact` publish bootstrap by line order — the same ordering assertion that the pre-existing `test-artifact-tools.sh` enforced.

The `path-rules-advisor` split was the second hazard. `test-memory-doctor-guard.sh` extracted the Python frontmatter parse check directly out of the SKILL.md body and executed it to verify the shipped code works. Moving the block to `references/write-verification.md` without updating the test would silently convert a passing safety guard into a no-op. The test was updated to buffer its extraction to a file (fixing a latent SIGPIPE abort that would have triggered if the skill grew large enough), and now reads from the core plus its references. The STOP contract and pre-write gate sentence stayed in the core so the rule is always loaded.

A CI issue surfaced from two sources. First, `wc -w` undercounted cores by 9–23 words in the C locale, so three cores shipped over the 600-word ceiling and the new CI step failed on first run. The test and all six cores were fixed: the counter switched to Python, and the cores were trimmed by removing genuine restatement (not reshuffling prose). Second, five tests that were updated to follow moved content had never been wired into CI — a gap in the original step 8 rationale. All five were added to `.github/workflows/check-plugin-versions.yml` in the same PR.

`optimizing-skill-frontmatter`'s split was self-referential: it is the rubric that defines the three-part description format and the ≤200/≤80 budget that every other skill is measured against. The split had to satisfy the rubric it teaches. After the split, `/skill-reviewer:reviewing-skills` was run against the core and returned a passing score. The `description:`, `allowed-tools:`, and `disable-model-invocation: true` frontmatter lines were left untouched in all six files.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| 0fd7b67 | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |

<!-- generated:end -->

## References

- Plan: [split-remaining-plugin-skills.md](plans/split-remaining-plugin-skills.md)
