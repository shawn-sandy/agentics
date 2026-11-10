# Stop paying 10,545 words every time these six skills fire

> Split six remaining monolithic SKILL.md files across five plugins into small cores plus per-topic reference files, each core under 600 words, with every skill's behavior and frontmatter description left byte-identical.

<!-- generated:start -->

**Status:** Shipped 2026-08-12 **Plan:** [split-remaining-plugin-skills](plans/split-remaining-plugin-skills.md)
**Type:** refactor

## What shipped

- Split six SKILL.md files — `optimizing-skill-frontmatter` (3,153 words), `prompt-artifact` (1,665), `diff-artifact` (1,549), `path-rules-advisor` (1,546), `artifact-to-post` (1,430), and `tdd-fix` (1,202) — into small cores plus 17 new reference files.
- Post-split cores measure 566–583 words each (68% cut from 10,681 pre-split total), counted in Python for locale-independent results.
- Security-scrub gates remain in the cores of both `diff-artifact` and `prompt-artifact`, ahead of the `select:Artifact` publish bootstrap.
- Updated four existing tests (`test-artifact-tools.sh`, `test-artifact-to-post.sh`, `test-memory-doctor-guard.sh`, `test-generator-skills-verify-output.sh`) so their literal assertions follow moved content to the reference files that now hold it.
- Added `tests/plugins/test-remaining-skill-splits.sh` as an objective gate wired into CI.
- Bumped five plugins in `.claude-plugin/marketplace.json` with matching CHANGELOG entries; `artifact-tools` shipped as 1.9.0 because 1.8.0 was already on `main`.
- All 43 existing tests in `tests/plugins/` pass; all four tautology-break cases were exercised and each correctly failed.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md` | Core — overview, When not to use, Step 0–6 names | Modified |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references/description-rules.md` | Rules 1–5 plus worked examples | Created |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references/invocation-control.md` | Step 4b classification table, confirmation options, apply rules | Created |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references/measurement.md` | Steps 2, 5, 6 bash measuring loops | Created |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references/budget-advisory.md` | Budget fraction advisory, installed-skills table, `/doctor` guidance | Created |
| `kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md` | Core — mode selection, hard-stop confirmations, write-verification rule | Modified |
| `kit/plugins/memory-tools/skills/path-rules-advisor/references/rule-modes.md` | Mode A and Mode B steps 1–7 in full | Created |
| `kit/plugins/memory-tools/skills/path-rules-advisor/references/rule-file-format.md` | Generated-file template, brace expansion, Notes | Created |
| `kit/plugins/memory-tools/skills/path-rules-advisor/references/write-verification.md` | Diff-back bash, Python frontmatter parse check, pre-write gate | Created |
| `kit/plugins/code-testing-agent/skills/tdd-fix/SKILL.md` | Core — freedom-level marker, When not to use, Step 0–9 names | Modified |
| `kit/plugins/code-testing-agent/skills/tdd-fix/references/fix-loop.md` | Step 2 red phase, Step 3 iteration log and 3a–3c, Step 4 hard cap | Created |
| `kit/plugins/code-testing-agent/skills/tdd-fix/references/handoff.md` | Step 5 regression sweep, Step 6 summary block, Steps 7–8 handoffs | Created |
| `kit/plugins/content-tools/skills/artifact-to-post/SKILL.md` | Core — Phase 0 asset locating, Phase 2 scrub gate, Phase 1–10 names | Modified |
| `kit/plugins/content-tools/references/source-resolution.md` | Phase 1 source table, claude.ai refusal text, Markdown-source rule | Created |
| `kit/plugins/content-tools/references/post-assembly.md` | Phases 4, 5, 7, 8, 10 mechanics | Created |
| `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` | Core — Step 2 scrub gate, Step 5 rescan, Step 1–8 headings | Modified |
| `kit/plugins/artifact-tools/references/diff-sources.md` | Mode table, default-branch resolution, PR-mode degradation script | Created |
| `kit/plugins/artifact-tools/references/diff-page.md` | Severity table, cap-and-summarize budget, 16 MiB shrink loop | Created |
| `kit/plugins/artifact-tools/references/diff-publishing.md` | Durable-copy keying, publish and URL recording, failure fallback | Created |
| `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` | Core — Step 4 scrub gate, empty-library stop, Step 1–8 headings | Modified |
| `kit/plugins/artifact-tools/references/prompt-resolution.md` | Mode table, `PROMPTS_DIR` resolver, prompt resolution logic | Created |
| `kit/plugins/artifact-tools/references/prompt-page.md` | Page requirements, six-value escaping table, copy-button script | Created |
| `kit/plugins/artifact-tools/references/prompt-publishing.md` | URL-record table, `.artifact-url` sidecar, render verification, fallback | Created |
| `tests/plugins/test-remaining-skill-splits.sh` | Objective test — word ceilings, reference counts, gate presence | Created |
| `tests/plugins/test-artifact-tools.sh` | Literal assertions repointed at references that now hold them | Modified |
| `tests/plugins/test-artifact-to-post.sh` | Config-key and ladder assertions repointed | Modified |
| `tests/plugins/test-memory-doctor-guard.sh` | Parse check and bash commands extracted from core plus references | Modified |
| `.github/workflows/check-plugin-versions.yml` | Five previously-unwired tests added; new objective test step added | Modified |
| `.claude-plugin/marketplace.json` | Five minor version bumps | Modified |
| `kit/plugins/skill-reviewer/CHANGELOG.md` | 2.3.0 entry (later superseded by 2.4.0 via prune plan) | Modified |
| `kit/plugins/memory-tools/CHANGELOG.md` | 4.1.0 entry | Modified |
| `kit/plugins/code-testing-agent/CHANGELOG.md` | 3.5.0 entry | Modified |
| `kit/plugins/content-tools/CHANGELOG.md` | 1.1.0 entry | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | `## [1.9.0]` entry in bracketed form | Modified |

## How it works

**Pre-split baseline.** Before any file was edited, word counts and `description:` lines were recorded for all six targets, totalling 10,681 words (canonical Python counter; `wc -w` gives a lower figure due to multibyte characters in these files). The before and after figures are comparable only when the same counter is used on both sides — this is why the objective test counts in Python.

**Splitting `optimizing-skill-frontmatter`.** The largest skill (3,153 words) was split into a 579-word core plus four references. The core retains the overview, `## When not to use`, and step names; the description rules, invocation-control table, measuring loops, and budget advisory each moved to their own `references/` file linked from the step that needs them. The skill is self-referential — it defines the progressive-disclosure rubric every other skill is measured against — so the split itself had to satisfy the rubric it teaches. `/skill-reviewer:reviewing-skills` was run against the split core and confirmed a passing score.

**Splitting `path-rules-advisor`.** The core keeps mode selection, both hard-stop confirmations, and the write-verification rule (the "run this after every write, STOP on non-zero" contract). The executable parse check moved to `references/write-verification.md`, but the STOP contract stays in the core with an in-core link so the safety guarantee does not disappear behind a reference. `tests/plugins/test-memory-doctor-guard.sh` was updated to extract the parse check from the reference rather than the core, and to buffer via a file to avoid SIGPIPE on large reads. `test-generator-skills-verify-output.sh` was left unmodified because the core retains the `run [Verify the write](#verify-the-write)` call sites its existing regex already matches.

**Splitting `tdd-fix`.** This was the one skill in `code-testing-agent` without a `references/` directory; its four siblings already use the per-skill layout. The core keeps the freedom-level marker, `## When not to use`, and step names; the fix-loop mechanics and handoff steps moved to two reference files matching the sibling convention.

**Splitting `artifact-to-post`.** The Phase 2 scrub gate and its "write nothing and end the turn" language stays in the core. Source resolution and post-assembly mechanics moved to plugin-level references beside the existing `content-config.md` and `mdx-safety.md`, matching the plugin's own `$SKILL_DIR/../../references/` convention. `tests/plugins/test-artifact-to-post.sh` was updated so config-key, literal, and ladder assertions read whichever file now holds them.

**Splitting `diff-artifact` and `prompt-artifact`.** For both artifact-tools skills, the security-scrub gate — including `GATE RESULT: BLOCKED/CANCELLED/APPROVED` verdicts and the hard-stop language — stays in the core ahead of the `select:Artifact` publish bootstrap. `diff-artifact`'s Step 5 rendered-page rescan also stays in the core. Moved mechanics include mode tables, default-branch resolution, severity/escaping tables, cap-and-summarize budgets, the 16 MiB shrink loop, durable-copy keying, and URL recording. `tests/plugins/test-artifact-tools.sh` was updated so its literal assertions (`cap-and-summarize`, `16 MiB`, `severity legend`, etc.) target the reference files that now hold them, while the scrub-gate ordering check stays anchored on the cores.

**The objective test.** `tests/plugins/test-remaining-skill-splits.sh` asserts four conditions: all six cores are under 600 words (Python counter), each has at least two reference files in the correct location, every `references/` path named in a core resolves on disk, and the security-scrub gate plus hard-stop language is present in both artifact-tools cores. Additionally, every frontmatter block of all six targets is byte-identical to the pre-split baseline — verified by a break-and-revert cycle that confirmed a reworded description exits 1.

**CI gap closed.** During review it was found that five tests this work depends on (`test-artifact-tools.sh`, `test-artifact-to-post.sh`, `test-memory-doctor-guard.sh`, `test-generator-skills-verify-output.sh`, `test-description-budget.sh`) were not wired into CI. All five were added to `.github/workflows/check-plugin-versions.yml` alongside the new objective test.

**Locale-independent word counting.** Three cores initially shipped over the 600-word ceiling under the C.UTF-8 locale used by CI (the C locale undercount caused local runs to pass). The test was fixed to use Python for counting, and the three cores were trimmed by removing genuine restatement — not by reshuffling prose.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `745584e` | 2026-07-29 | refactor(skills): split six monolithic skills into cores plus per-topic references (#487) |

<!-- generated:end -->

## References

- Plan: [split-remaining-plugin-skills](plans/split-remaining-plugin-skills.md)
- Changelog: `kit/plugins/artifact-tools/CHANGELOG.md` — 1.9.0 entry; `kit/plugins/memory-tools/CHANGELOG.md` — 4.1.0; `kit/plugins/code-testing-agent/CHANGELOG.md` — 3.5.0; `kit/plugins/content-tools/CHANGELOG.md` — 1.1.0; `kit/plugins/skill-reviewer/CHANGELOG.md` — 2.3.0
- Anthropic context engineering guidance: https://claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models
