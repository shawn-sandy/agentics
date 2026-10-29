# Stop paying 10,545 words every time these six skills fire

> Split the six remaining monolithic SKILL.md files across `skill-reviewer`, `artifact-tools`, `memory-tools`, `content-tools`, and `code-testing-agent` into small cores plus per-topic reference files, achieving a 68% word-count reduction while leaving every security gate in the core.

<!-- generated:start -->

**Status:** Shipped 2026-08-15 **Plan:** [split-remaining-plugin-skills.md](plans/split-remaining-plugin-skills.md)
**Type:** refactor

## What shipped

- Recorded a pre-split baseline: word counts and verbatim `description:` lines for all six skills (pre-split canonical total 10,681 words).
- Split `optimizing-skill-frontmatter/SKILL.md` (3,153 words → 579) into a core plus `references/description-rules.md`, `references/invocation-control.md`, `references/measurement.md`, and `references/budget-advisory.md`; the split must satisfy the rubric it teaches.
- Split `path-rules-advisor/SKILL.md` (1,546 words → 571) into a core plus `references/rule-modes.md`, `references/rule-file-format.md`, and `references/write-verification.md`; the "STOP on non-zero" contract stayed in the core; updated `test-memory-doctor-guard.sh` to extract executable code from the reference.
- Split `tdd-fix/SKILL.md` (1,202 words → 566) into a core plus `references/fix-loop.md` and `references/handoff.md`, matching the per-skill `references/` layout its four siblings already use.
- Split `artifact-to-post/SKILL.md` (1,430 words → 583) into a core plus plugin-level `references/source-resolution.md` and `references/post-assembly.md`; the Phase 2 scrub gate and "write nothing and end the turn" language stayed in the core; updated `test-artifact-to-post.sh`.
- Split `diff-artifact/SKILL.md` (1,549 words → 566) into a core plus plugin-level `references/diff-sources.md`, `references/diff-page.md`, and `references/diff-publishing.md`; the Step 2 scrub gate, the Step 5 rendered-page rescan, and all `## Step N —` headings stayed in the core; updated `test-artifact-tools.sh`.
- Split `prompt-artifact/SKILL.md` (1,665 words → 522) into a core plus plugin-level `references/prompt-resolution.md`, `references/prompt-page.md`, and `references/prompt-publishing.md`; the Step 4 scrub gate and the never-publish-empty-gallery stop stayed in the core; updated `test-artifact-tools.sh` and `test-proposal-prompt-pipeline.sh`.
- Added `tests/plugins/test-remaining-skill-splits.sh` asserting all four objective conditions for all six targets, and wired it into `.github/workflows/check-plugin-versions.yml`; also wired the five pre-existing tests that grep these skills into CI.
- Bumped five plugins in `.claude-plugin/marketplace.json` and added CHANGELOG entries (artifact-tools landed at 1.9.0, not 1.8.0, because `main` already shipped 1.8.0); all version bumps confirmed by `BASE_REF=main node scripts/check-plugin-versions.mjs`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md` | Core — overview, When not to use, step names | Modified |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references/description-rules.md` | Rules 1–5 plus worked examples A and B | Created |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references/invocation-control.md` | Step 4b classification table, confirmation options, grep-then-Edit apply rules | Created |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references/measurement.md` | Step 2, 5, and 6 bash measuring loops | Created |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references/budget-advisory.md` | `skillListingBudgetFraction` advisory, installed-skills table, `/doctor` guidance | Created |
| `kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md` | Core — mode selection, both hard-stop confirmations, write-verification rule | Modified |
| `kit/plugins/memory-tools/skills/path-rules-advisor/references/rule-modes.md` | Mode A Steps 1–7 and Mode B Steps 1–7 | Created |
| `kit/plugins/memory-tools/skills/path-rules-advisor/references/rule-file-format.md` | Generated-file template, brace expansion, Notes section | Created |
| `kit/plugins/memory-tools/skills/path-rules-advisor/references/write-verification.md` | Diff-back bash, python frontmatter parse check, pre-write gate | Created |
| `kit/plugins/code-testing-agent/skills/tdd-fix/SKILL.md` | Core — freedom-level marker, When not to use, step names | Modified |
| `kit/plugins/code-testing-agent/skills/tdd-fix/references/fix-loop.md` | Step 2 red phase, Step 3 iteration log and 3a–3c, Step 4 hard cap | Created |
| `kit/plugins/code-testing-agent/skills/tdd-fix/references/handoff.md` | Step 5 regression sweep, Step 6 summary block, Steps 7–8 handoffs | Created |
| `kit/plugins/content-tools/skills/artifact-to-post/SKILL.md` | Core — Phase 0 asset locating, Phase 2 scrub gate, Phase 1–10 names | Modified |
| `kit/plugins/content-tools/references/source-resolution.md` | Phase 1 source table, claude.ai refusal text, Markdown-source rule | Created |
| `kit/plugins/content-tools/references/post-assembly.md` | Phases 4, 5, 7, 8, 10 mechanics | Created |
| `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` | Core — Step 2 scrub gate, Step 5 rescan, Step 1–8 headings | Modified |
| `kit/plugins/artifact-tools/references/diff-sources.md` | Mode table, default-branch resolution, PR-mode degradation script | Created |
| `kit/plugins/artifact-tools/references/diff-page.md` | Severity table, cap-and-summarize budget, page requirements, 16 MiB shrink loop | Created |
| `kit/plugins/artifact-tools/references/diff-publishing.md` | Durable-copy keying, publish/URL recording, failure fallback, render verification | Created |
| `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` | Core — Step 4 scrub gate, empty-library stop, Step 1–8 headings | Modified |
| `kit/plugins/artifact-tools/references/prompt-resolution.md` | Mode table, `PROMPTS_DIR` python resolver, single/library prompt resolution | Created |
| `kit/plugins/artifact-tools/references/prompt-page.md` | Page requirements, six-value escaping table, copy-button script | Created |
| `kit/plugins/artifact-tools/references/prompt-publishing.md` | URL-record table, `.artifact-url` sidecar, render verification, fallback | Created |
| `tests/plugins/test-remaining-skill-splits.sh` | Objective test — word ceiling, reference integrity, gate presence in both artifact cores | Created |
| `tests/plugins/test-artifact-tools.sh` | Updated — literal assertions follow moved content into `references/` | Modified |
| `tests/plugins/test-artifact-to-post.sh` | Updated — config-key and ladder assertions follow moved content | Modified |
| `tests/plugins/test-memory-doctor-guard.sh` | Updated — extracts parse check and bash commands from core plus references | Modified |
| `.github/workflows/check-plugin-versions.yml` | CI — new steps wiring the objective test and five pre-existing tests | Modified |
| `.claude-plugin/marketplace.json` | Five minor version bumps | Modified |
| `kit/plugins/skill-reviewer/CHANGELOG.md` | 2.3.0 release entry | Modified |
| `kit/plugins/memory-tools/CHANGELOG.md` | 4.1.0 release entry | Modified |
| `kit/plugins/code-testing-agent/CHANGELOG.md` | 3.5.0 release entry | Modified |
| `kit/plugins/content-tools/CHANGELOG.md` | 1.1.0 release entry | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | `## [1.9.0] - 2026-07-29` release entry | Modified |

## How it works

Three hazards shaped the split order and placement decisions. First, `optimizing-skill-frontmatter` is self-referential — it defines the three-part description format, the ≤200-character budget, and the ≤80-character first-sentence limit that everything else in the repo is measured against. Splitting it required the split itself to satisfy the rubric it teaches. Second, `diff-artifact` and `prompt-artifact` both gate on a blocking `security-scrub` invocation before publishing: that gate is outward-facing and irreversible, so it stayed in the core of both skills (along with the second rendered-page rescan in `diff-artifact` Step 5), and the objective test asserts the gate is in the core specifically — not merely somewhere under the plugin. Third, each plugin already had a reference layout convention — `artifact-tools` and `content-tools` place references at plugin level, while `code-testing-agent`, `memory-tools`, and `skill-reviewer` place them per-skill — and the plan matched each plugin's existing convention rather than imposing a new one.

Step 1 recorded the pre-split baseline into a scratchpad: word counts and verbatim `description:` lines for all six targets. This was a prerequisite for the description-stability assertion in the objective test — comparing against a golden file rather than `origin/main`, so a deliberate future description change updates the golden file as an explicit act rather than silently breaking CI.

Steps 2 through 7 performed the splits. Text moved verbatim from the core into topic reference files; each moved section was replaced in the core with a named step line linking its reference. The real blast radius was the tests: four existing tests (`test-artifact-tools.sh`, `test-artifact-to-post.sh`, `test-memory-doctor-guard.sh`, `test-generator-skills-verify-output.sh`) read these skill bodies as data — some extracting and executing bash blocks out of `path-rules-advisor/SKILL.md`. Each step that moved content also updated the test that read it in the same step.

A locale-sensitivity defect surfaced in CI: `wc -w` undercounts files with multibyte characters (em dashes, `≤`, `→`) by 9–23 words depending on the C locale. Three cores that read compliant in development (`tdd-fix` 603, `diff-artifact` 602, `prompt-artifact` 617) were over the ceiling on the CI runner. The objective test was rewritten to count in Python, which decodes UTF-8 regardless of locale; all six cores were then trimmed to 522–583 words by removing genuine restatement.

A pipe-abort defect was fixed in `test-memory-doctor-guard.sh`: its `extract_check` piped skill content into an `awk` that exits at the heredoc terminator, causing `SIGPIPE` under `set -o pipefail`. The test had been passing only because the bytes trailed within the 64 KiB pipe buffer. Extraction now buffers to a file.

The review cycle surfaced four accepted findings (frontmatter unit check now compares the whole `---` block; `diff-artifact`'s rendered-page rescan asserted to precede publish bootstrap; date-derived-key ban extended to `prompt-publishing.md`; `references/titles.md` joined the resolve/orphan sweep) and four declined findings, each with a stated reason.

A notable discovery: five of the tests this work depended on were not wired into CI at all — including four retargeted here to follow moved content. Step 8's rationale ("without CI wiring the guarantee decays on the next edit") was applied to the new objective test; it applied equally to the retargeted tests. All five are now named steps in the workflow.

## How to use it

The split is transparent to end users — skill triggers and invocation syntax are unchanged. The objective test confirms structural soundness:

```bash
bash tests/plugins/test-remaining-skill-splits.sh
```

Expected output: exit 0 with one line per skill listing its word count (all under 600) and a link-integrity summary. To prove the gate is not a tautology: delete the `security-scrub` paragraph from `prompt-artifact/SKILL.md` and confirm the test exits 1 naming the missing gate, then restore with `git restore <path>`.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d7598ad` | 2026-08-17 | fix: screenshot output verification and plan Context completeness (#571) |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |
| `e1e8840` | 2026-08-15 | feat(git-agent): add post-merge-cleanup skill (4.19.0) (#565) |

<!-- generated:end -->

## References

- Plan: [split-remaining-plugin-skills.md](plans/split-remaining-plugin-skills.md)
