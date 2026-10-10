# Stop paying 10,545 words every time these six skills fire

> Six monolithic SKILL.md files across five plugins each loaded 1,202–3,153 words on every trigger. Each was split into a small core under 600 words plus per-topic reference files, cutting the combined context payload from 10,681 to 3,392 words (68%) with all safety gates confirmed intact.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [split-remaining-plugin-skills.md](plans/split-remaining-plugin-skills.md)
**Type:** refactor

## What shipped

- Recorded a pre-split baseline (word counts and `description:` lines verbatim) into the scratchpad before any edit.
- Split `skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md` (3,153 words) into a core plus `references/description-rules.md`, `references/invocation-control.md`, `references/measurement.md`, and `references/budget-advisory.md`.
- Split `memory-tools/skills/path-rules-advisor/SKILL.md` (1,546 words) into a core plus `references/rule-modes.md`, `references/rule-file-format.md`, and `references/write-verification.md`; updated `tests/plugins/test-memory-doctor-guard.sh` to extract the parse check and bash commands from the core and its references, and fixed a SIGPIPE defect that caused the harness to abort silently when the content after the heredoc exceeded the pipe buffer.
- Split `code-testing-agent/skills/tdd-fix/SKILL.md` (1,202 words) into a core plus `references/fix-loop.md` and `references/handoff.md`, matching the per-skill `references/` layout its four siblings already used.
- Split `content-tools/skills/artifact-to-post/SKILL.md` (1,430 words) into a core plus `kit/plugins/content-tools/references/source-resolution.md` and `references/post-assembly.md` at the plugin level, matching the existing `content-config.md` / `mdx-safety.md` layout; kept the Phase 2 scrub gate and its "write nothing and end the turn" language in the core.
- Split `artifact-tools/skills/diff-artifact/SKILL.md` (1,549 words) into a core plus `references/diff-sources.md`, `references/diff-page.md`, and `references/diff-publishing.md` at the plugin level; kept the Step 2 scrub gate, the Step 5 rendered-page rescan, and all `## Step N —` headings in the core.
- Split `artifact-tools/skills/prompt-artifact/SKILL.md` (1,665 words) into a core plus `references/prompt-resolution.md`, `references/prompt-page.md`, and `references/prompt-publishing.md`; kept the Step 4 scrub gate and the never-publish-empty-gallery stop in the core.
- Updated `tests/plugins/test-artifact-tools.sh` so moved literals are asserted against the reference files that now hold them; the scrub-before-publish ordering check remains anchored on both cores.
- Updated `tests/plugins/test-artifact-to-post.sh` for moved config keys and ladder assertions.
- Wrote `tests/plugins/test-remaining-skill-splits.sh` asserting all four objective conditions for the six targets, including the presence of `security-scrub` and hard-stop language in both artifact-tools cores.
- Wired all five affected unit tests and the new objective test into `.github/workflows/check-plugin-versions.yml` (the five pre-existing tests were not previously wired to CI).
- Bumped five plugins in `.claude-plugin/marketplace.json`: skill-reviewer, memory-tools, code-testing-agent, content-tools, and artifact-tools to 1.9.0 (not 1.8.0 as planned — `main` already carried 1.8.0 so the version guard required the next minor).
- Fixed a locale-dependent word counter: `wc -w` under the container's C locale undercounted cores by 9–23 words (multibyte chars like `—`, `≤`, `→`); the objective test now counts in Python for locale-independent results, and all six cores were trimmed to 566–583 words.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md` | Core: overview, When-not-to-use, Step 0–6 names | Modified |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references/description-rules.md` | Rules 1–5, worked examples A and B | Created |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references/invocation-control.md` | Step 4b classification table, confirmation options, apply rules | Created |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references/measurement.md` | Steps 2, 5, 6 bash measuring loops | Created |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references/budget-advisory.md` | `skillListingBudgetFraction` advisory, installed-skills table, `/doctor` guidance | Created |
| `kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md` | Core: mode selection, both hard-stop confirmations, write-verification rule | Modified |
| `kit/plugins/memory-tools/skills/path-rules-advisor/references/rule-modes.md` | Mode A and Mode B Steps 1–7 in full | Created |
| `kit/plugins/memory-tools/skills/path-rules-advisor/references/rule-file-format.md` | Generated-file template, brace expansion, Notes section | Created |
| `kit/plugins/memory-tools/skills/path-rules-advisor/references/write-verification.md` | Diff-back bash, Python frontmatter parse check, pre-write gate | Created |
| `kit/plugins/code-testing-agent/skills/tdd-fix/SKILL.md` | Core: freedom-level marker, When-not-to-use, Step 0–9 names | Modified |
| `kit/plugins/code-testing-agent/skills/tdd-fix/references/fix-loop.md` | Step 2 red phase, Step 3 iteration log and 3a–3c, Step 4 hard cap | Created |
| `kit/plugins/code-testing-agent/skills/tdd-fix/references/handoff.md` | Step 5 regression sweep, Step 6 summary block, Steps 7–8 handoffs | Created |
| `kit/plugins/content-tools/skills/artifact-to-post/SKILL.md` | Core: Phase 0 asset locating, Phase 2 scrub gate verbatim, Phase 1–10 names | Modified |
| `kit/plugins/content-tools/references/source-resolution.md` | Phase 1 source table, claude.ai refusal text, Markdown-source rule | Created |
| `kit/plugins/content-tools/references/post-assembly.md` | Phases 4, 5, 7, 8, 10 mechanics | Created |
| `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` | Core: Step 2 scrub gate, Step 5 rescan, Step 1–8 headings | Modified |
| `kit/plugins/artifact-tools/references/diff-sources.md` | Mode table, default-branch resolution, PR-mode degradation script | Created |
| `kit/plugins/artifact-tools/references/diff-page.md` | Severity table, cap-and-summarize budget, page requirements, 16 MiB shrink loop | Created |
| `kit/plugins/artifact-tools/references/diff-publishing.md` | Durable-copy keying, publish and URL recording, failure fallback, render verification | Created |
| `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` | Core: Step 4 scrub gate, empty-library stop, Step 1–8 headings | Modified |
| `kit/plugins/artifact-tools/references/prompt-resolution.md` | Mode table, `PROMPTS_DIR` Python resolver, single/library resolution | Created |
| `kit/plugins/artifact-tools/references/prompt-page.md` | Page requirements, six-value escaping table, copy-button script | Created |
| `kit/plugins/artifact-tools/references/prompt-publishing.md` | URL-record table, `.artifact-url` sidecar, render verification, fallback | Created |
| `tests/plugins/test-remaining-skill-splits.sh` | Objective test for all six splits including security-gate assertions | Created |
| `tests/plugins/test-artifact-tools.sh` | Literal assertions follow moved content into references/ | Modified |
| `tests/plugins/test-artifact-to-post.sh` | Config-key and ladder assertions follow moved content | Modified |
| `tests/plugins/test-memory-doctor-guard.sh` | Extracts parse check and bash commands from core plus references; SIGPIPE fix | Modified |
| `.github/workflows/check-plugin-versions.yml` | Added step for objective test plus wired five previously un-wired tests | Modified |
| `.claude-plugin/marketplace.json` | Five minor version bumps | Modified |

## How it works

This plan completed the progressive-disclosure refactor begun by `split-plan-agent-skills`: the six remaining SKILL.md files over 1,200 words, spread across five plugins. Each body was paid in full on every trigger with no partial load. The combined before-count of 10,681 words (canonical Python count) dropped to 3,392 after the split, a 68% reduction.

Three hazards shaped the work. First, `optimizing-skill-frontmatter` is self-referential — it is the rubric that defines the three-part description format and ≤200-char budget every other SKILL.md is measured against. A split that violates the rules it teaches is incoherent. Mitigation: Step 9 required `/skill-reviewer:reviewing-skills` to give the split core a passing score. Second, `diff-artifact` and `prompt-artifact` each run a blocking `security-scrub` gate before publishing; a gate the model does not load is a secret leak. Mitigation: the objective test asserts the gate is in both cores (not in a reference), and `test-artifact-tools.sh`'s ordering assertion kept it anchored ahead of the `select:Artifact` publish bootstrap. Third, each plugin already had a reference layout convention and the plan matched it rather than imposing uniformity: `artifact-tools` and `content-tools` use plugin-level `references/`, while `skill-reviewer`, `memory-tools`, and `code-testing-agent` use per-skill `references/`.

The real blast radius was the test suite. Four existing tests read skill bodies as data (`test-artifact-tools.sh`, `test-artifact-to-post.sh`, `test-memory-doctor-guard.sh`, `test-generator-skills-verify-output.sh`). Each was updated in the same step as the corresponding split. Notably, `test-generator-skills-verify-output.sh` required no change because the core kept the three `run [Verify the write](#verify-the-write)` call sites its existing regex matched — a cleaner outcome than the plan anticipated.

A locale defect surfaced during PR review: `wc -w` in the C locale undercounts files containing `—`, `≤`, `→` (treating multibyte chars as non-words), producing counts 9–23 words below the Python count. Three cores that read under 600 with `wc` were actually over with Python. All six were trimmed by removing genuine restatement (Step 5 in `diff-artifact` no longer repeats Step 2's verdict list; `tdd-fix` no longer paraphrases steps its references already state; `artifact-to-post` drops a lead paragraph restating its description). The objective test now uses Python, giving the same count on every machine.

A `test-memory-doctor-guard.sh` defect: `awk` exited at the heredoc terminator, closing the read end of a pipe while the producer was still writing; under `set -o pipefail` + `set -e` the test aborted at exit 141, skipping checks 3–10 silently. The fix buffers extraction to a file (no reader to close). Verified by appending 480 KB after the heredoc: all 11 checks still run where the piped form exits 141.

Five of the tests this plan depended on were not wired into CI at all. Step 8's rationale ("without CI wiring the guarantee decays on the next edit") applied to them just as much as to the new objective test. All five were added to the workflow as named steps.

Behavioral verification ran all six skills through `claude -p` in throwaway temp dirs. Every skill reached and read its references at the right steps, and every gate held: `artifact-to-post` stopped dead at Phase 2 and wrote nothing; `diff-artifact` stopped at the Step 2 gate before building a page; `prompt-artifact` stopped at Step 4 with no page written; `path-rules-advisor` refused to write without explicit confirmation; `optimizing-skill-frontmatter` reached all four references and rewrote a fixture description to three-part form; `tdd-fix` wrote a failing test, entered the loop, fixed the bug, and swept the suite green.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |

<!-- generated:end -->

## References

- Plan: [split-remaining-plugin-skills.md](plans/split-remaining-plugin-skills.md)
