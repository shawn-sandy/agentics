# Stop paying 10,545 words every time these six skills fire

> Six skills across five plugins each dumped between 1,202 and 3,153 words into context every time they fired, and the largest was the rubric that told every other skill not to do that. All six split into cores under 600 words with mechanics in reference files; security-scrub gates stayed in both artifact-tools cores where the model cannot fail to load them.

<!-- generated:start -->

**Status:** Shipped 2026-07-29 **Plan:** [split-remaining-plugin-skills.md](plans/split-remaining-plugin-skills.md)
**Type:** refactor

## What shipped

- Split `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md` (3,153 words) into a core plus `references/description-rules.md`, `references/invocation-control.md`, `references/measurement.md`, and `references/budget-advisory.md`.
- Split `kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md` (1,546 words) into a core plus `references/rule-modes.md`, `references/rule-file-format.md`, and `references/write-verification.md`; kept "run this after every write, STOP on non-zero" and the pre-write gate sentence in the core.
- Split `kit/plugins/code-testing-agent/skills/tdd-fix/SKILL.md` (1,202 words) into a core plus `references/fix-loop.md` and `references/handoff.md`; matching the per-skill `references/` layout its four siblings already use.
- Split `kit/plugins/content-tools/skills/artifact-to-post/SKILL.md` (1,430 words) into a core plus plugin-level `references/source-resolution.md` and `references/post-assembly.md`; kept Phase 2 scrub gate and "write nothing and end the turn" language in the core.
- Split `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` (1,549 words) into a core plus plugin-level `references/diff-sources.md`, `references/diff-page.md`, and `references/diff-publishing.md`; kept Step 2 scrub gate, Step 5 rendered-page rescan, and all `## Step N — ` headings in the core.
- Split `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` (1,665 words) into a core plus plugin-level `references/prompt-resolution.md`, `references/prompt-page.md`, and `references/prompt-publishing.md`; kept Step 4 scrub gate and never-publish-an-empty-gallery stop in the core.
- Added `tests/plugins/test-remaining-skill-splits.sh`: asserts all six cores under 600 words (Python counter), security-scrub gate in both artifact-tools cores ahead of `select:Artifact`, every reference resolves, no orphans.
- Updated `tests/plugins/test-artifact-tools.sh`, `tests/plugins/test-artifact-to-post.sh`, `tests/plugins/test-memory-doctor-guard.sh` so literal assertions follow moved content into references; added `test-proposal-prompt-pipeline.sh` update for moved prompt-page chips.
- Wired five previously-unwired tests plus the new objective test into `.github/workflows/check-plugin-versions.yml`.
- Fixed `test-memory-doctor-guard.sh` pipe-abort: `extract_check` now buffers to a file rather than piping through `awk`, eliminating a silent exit-141 that could skip checks 3–10 on larger files.
- Fixed locale-dependent word counter: CI runner's C.UTF-8 locale counted 9–23 more words than the C locale; test and all six cores now use Python, returning the same count everywhere. Post-split cores: 579 / 522 / 571 / 571 / 566 / 583 words.
- Bumped: skill-reviewer 2.3.0, memory-tools 4.1.0, code-testing-agent 3.5.0, content-tools 1.1.0, artifact-tools **1.9.0** (`main` already shipped 1.8.0).

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md` | Core under 600 words | Modified |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references/` | 4 reference files | Created |
| `kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md` | Core, write-guard rule kept | Modified |
| `kit/plugins/memory-tools/skills/path-rules-advisor/references/` | 3 reference files | Created |
| `kit/plugins/code-testing-agent/skills/tdd-fix/SKILL.md` | Core under 600 words | Modified |
| `kit/plugins/code-testing-agent/skills/tdd-fix/references/` | 2 reference files | Created |
| `kit/plugins/content-tools/skills/artifact-to-post/SKILL.md` | Core, scrub gate kept | Modified |
| `kit/plugins/content-tools/references/source-resolution.md` | Phase 1 source table | Created |
| `kit/plugins/content-tools/references/post-assembly.md` | Phases 4–8, 10 | Created |
| `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` | Core, scrub gates kept | Modified |
| `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` | Core, scrub gate kept | Modified |
| `kit/plugins/artifact-tools/references/diff-sources.md` | Mode table, default-branch resolution | Created |
| `kit/plugins/artifact-tools/references/diff-page.md` | Severity table, cap-and-summarize | Created |
| `kit/plugins/artifact-tools/references/diff-publishing.md` | Publish, URL recording, fallback | Created |
| `kit/plugins/artifact-tools/references/prompt-resolution.md` | Mode table, PROMPTS_DIR resolver | Created |
| `kit/plugins/artifact-tools/references/prompt-page.md` | Escaping table, copy-button script | Created |
| `kit/plugins/artifact-tools/references/prompt-publishing.md` | URL-record table, render verification | Created |
| `tests/plugins/test-remaining-skill-splits.sh` | Objective verification test | Created |
| `tests/plugins/test-artifact-tools.sh` | Literals follow moved content | Modified |
| `tests/plugins/test-artifact-to-post.sh` | Literals follow moved content | Modified |
| `tests/plugins/test-memory-doctor-guard.sh` | Pipe-abort fix, extracts from references | Modified |
| `.github/workflows/check-plugin-versions.yml` | Wire 6 tests | Modified |
| `.claude-plugin/marketplace.json` | 5 plugin version bumps | Modified |
| `kit/plugins/skill-reviewer/CHANGELOG.md` | 2.3.0 entry | Modified |
| `kit/plugins/memory-tools/CHANGELOG.md` | 4.1.0 entry | Modified |
| `kit/plugins/code-testing-agent/CHANGELOG.md` | 3.5.0 entry | Modified |
| `kit/plugins/content-tools/CHANGELOG.md` | 1.1.0 entry | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | `## [1.9.0] - 2026-07-29` entry | Modified |

## How it works

**Security gates in cores**: Publishing is outward-facing and irreversible. The `security-scrub` gate, `GATE RESULT: BLOCKED` / `CANCELLED` / `APPROVED` verdicts, and hard-stop language stay in both artifact-tools cores — a gate behind a reference is a gate that might not load. `test-remaining-skill-splits.sh` asserts the gate is in the core and precedes `select:Artifact`.

**Plugin-level vs per-skill references**: `artifact-tools` and `content-tools` already resolved references at plugin level via `${CLAUDE_PLUGIN_ROOT}/references/`; this plan matched that convention rather than imposing a new one. `skill-reviewer`, `memory-tools`, and `code-testing-agent` use per-skill `references/`; `tdd-fix` gains the same layout as its four siblings.

**Self-referential split**: `optimizing-skill-frontmatter` is the rubric every other skill is judged against. The split itself was verified with `/skill-reviewer:reviewing-skills` against its own core, which passed the progressive-disclosure and reference-depth criteria it defines.

**Canonical word count**: `wc -w` is locale-dependent on these files (multibyte characters like `—`, `≤`, `→`). Python counts 9–23 more words per file than the C locale. The test and all cores now use Python; CI went red on first run because three cores were over-ceiling in `C.UTF-8`, then trimmed to 566–583 by removing genuine restatement.

## How to use it

The changes are automatic for anyone installing the five updated plugins from the marketplace. Skills load their reference files on demand as steps are reached.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| — | 2026-07-29 | refactor: split six remaining monolithic skills into cores plus references (skill-reviewer 2.3.0, memory-tools 4.1.0, code-testing-agent 3.5.0, content-tools 1.1.0, artifact-tools 1.9.0) |

<!-- generated:end -->

## References

- Plan: [split-remaining-plugin-skills.md](plans/split-remaining-plugin-skills.md)
