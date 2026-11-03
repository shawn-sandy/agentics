# Stop paying 10,545 words every time these six skills fire

> Splits the six remaining monolithic SKILL.md files across skill-reviewer, artifact-tools, memory-tools, content-tools, and code-testing-agent into small cores plus per-topic reference files, each core under 600 words, with every skill's behavior and description left byte-identical.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [split-remaining-plugin-skills](plans/split-remaining-plugin-skills.md)
**Type:** refactor

## What shipped

- Split `skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md` (3,153 words) into a core plus `references/description-rules.md`, `references/invocation-control.md`, `references/measurement.md`, and `references/budget-advisory.md`
- Split `memory-tools/skills/path-rules-advisor/SKILL.md` (1,546 words) into a core plus `references/rule-modes.md`, `references/rule-file-format.md`, and `references/write-verification.md`; kept the "run this after every write, STOP on non-zero" rule in the core
- Split `code-testing-agent/skills/tdd-fix/SKILL.md` (1,202 words) into a core plus `references/fix-loop.md` and `references/handoff.md`
- Split `content-tools/skills/artifact-to-post/SKILL.md` (1,430 words) into a core plus plugin-level `references/source-resolution.md` and `references/post-assembly.md`; kept the Phase 2 scrub gate in the core
- Split `artifact-tools/skills/diff-artifact/SKILL.md` (1,549 words) into a core plus plugin-level `references/diff-sources.md`, `references/diff-page.md`, and `references/diff-publishing.md`; kept the Step 2 scrub gate and Step 5 rescan in the core
- Split `artifact-tools/skills/prompt-artifact/SKILL.md` (1,665 words) into a core plus plugin-level `references/prompt-resolution.md`, `references/prompt-page.md`, and `references/prompt-publishing.md`; kept the Step 4 scrub gate in the core
- Updated `tests/plugins/test-artifact-tools.sh`, `test-artifact-to-post.sh`, `test-memory-doctor-guard.sh`, and `test-proposal-prompt-pipeline.sh` to read moved content from its new locations
- Created `tests/plugins/test-remaining-skill-splits.sh`; added it and four previously-unregistered tests to `.github/workflows/check-plugin-versions.yml`
- Bumped skill-reviewer to 2.3.0, memory-tools to 4.1.0, code-testing-agent to 3.5.0, content-tools to 1.1.0, artifact-tools to 1.9.0

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md` | Skill core | Modified |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references/` | Four new reference files | Created |
| `kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md` | Skill core — write guard kept | Modified |
| `kit/plugins/memory-tools/skills/path-rules-advisor/references/` | Three new reference files | Created |
| `kit/plugins/code-testing-agent/skills/tdd-fix/SKILL.md` | Skill core | Modified |
| `kit/plugins/code-testing-agent/skills/tdd-fix/references/` | Two new reference files | Created |
| `kit/plugins/content-tools/skills/artifact-to-post/SKILL.md` | Skill core — scrub gate kept | Modified |
| `kit/plugins/content-tools/references/source-resolution.md` | Plugin-level reference — new | Created |
| `kit/plugins/content-tools/references/post-assembly.md` | Plugin-level reference — new | Created |
| `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` | Skill core — both gates kept | Modified |
| `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` | Skill core — scrub gate kept | Modified |
| `kit/plugins/artifact-tools/references/diff-sources.md` | Plugin-level reference — new | Created |
| `kit/plugins/artifact-tools/references/diff-page.md` | Plugin-level reference — new | Created |
| `kit/plugins/artifact-tools/references/diff-publishing.md` | Plugin-level reference — new | Created |
| `kit/plugins/artifact-tools/references/prompt-resolution.md` | Plugin-level reference — new | Created |
| `kit/plugins/artifact-tools/references/prompt-page.md` | Plugin-level reference — new | Created |
| `kit/plugins/artifact-tools/references/prompt-publishing.md` | Plugin-level reference — new | Created |
| `tests/plugins/test-remaining-skill-splits.sh` | Smoke test — objective gate | Created |
| `tests/plugins/test-artifact-tools.sh` | Smoke test — updated assertions | Modified |
| `tests/plugins/test-artifact-to-post.sh` | Smoke test — updated assertions | Modified |
| `tests/plugins/test-memory-doctor-guard.sh` | Smoke test — updated extractors | Modified |
| `tests/plugins/test-proposal-prompt-pipeline.sh` | Smoke test — chip assertions moved to reference | Modified |
| `.github/workflows/check-plugin-versions.yml` | CI — five newly wired tests | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry — five version bumps | Modified |

## How it works

These six skills were the last single-file SKILL.md bodies over 1,200 words in the repository, completing the progressive-disclosure audit that started with `split-plan-agent-skills`. The pattern is identical: move mechanics to reference files, keep the core to trigger, arguments, and step names, link every reference file by name from the step that needs it.

Two layout conventions coexist in the repo — per-skill `references/` (skill-reviewer, memory-tools, code-testing-agent) and plugin-level `references/` (artifact-tools, content-tools). Each plugin's existing convention was matched rather than standardized.

**Security-gate invariant**: both `diff-artifact` and `prompt-artifact` run a `security-scrub` gate before any publish. That gate — the `Skill` invocation, the `GATE RESULT: BLOCKED/CANCELLED/APPROVED` verdicts, and the hard-stop language — stayed in the core of both skills. The `test-remaining-skill-splits.sh` objective test asserts this directly: `security-scrub` and `GATE RESULT: BLOCKED` must appear in the core, not merely somewhere in the plugin. `test-artifact-tools.sh` separately asserts the gate precedes the `select:Artifact` publish bootstrap by line order.

`test-memory-doctor-guard.sh` extracts the bash and Python parse check from `path-rules-advisor` and actually runs them — so moving the check to a reference file required updating the test's extractor, not relaxing the assertion. A pipe-buffer bug in the original test (the producer took SIGPIPE before all bytes were read) was fixed during this work: extraction now buffers to a file instead, which was verified by appending 480 KB of data after the heredoc and confirming all 11 checks still ran.

`optimizing-skill-frontmatter` is self-referential: it is the rubric that defines the three-part description format, the ≤200-char budget, and the ≤80-char first sentence that everything else in the repo is measured against. The split was verified by running `/skill-reviewer:reviewing-skills` against the split core, which must pass its own audit including the reference-depth-≤1 and progressive-disclosure criteria it defines.

**Deviation from plan**: artifact-tools was planned to ship at 1.8.0, but `main` already carried 1.8.0 from a concurrent change. The shipped version is 1.9.0, with a `## [1.9.0] - 2026-07-29` CHANGELOG heading in the bracketed form `test-artifact-tools.sh` parses.

**Post-CI corrections**: the word ceiling test initially used `wc -w`, which undercounts files with multibyte characters (em dashes, ≤, →) by 9–23 words per file under the C locale but overcounts them in C.UTF-8. Three cores shipped over the ceiling on the first CI run. The test now counts in Python (locale-independent); the cores were trimmed to 566–583 with genuine restatement removed. Four previously-unregistered tests (`test-artifact-tools.sh`, `test-artifact-to-post.sh`, `test-memory-doctor-guard.sh`, `test-generator-skills-verify-output.sh`) were wired into CI in the same fix.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [split-remaining-plugin-skills](plans/split-remaining-plugin-skills.md)
