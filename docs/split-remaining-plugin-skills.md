# Split the six remaining monolithic plugin skills

> Splits optimizing-skill-frontmatter, prompt-artifact, diff-artifact, path-rules-advisor, artifact-to-post, and tdd-fix from single SKILL.md files (10,545 words total) into cores under 600 words each plus per-topic reference files, keeping every security-scrub gate in the core.

<!-- generated:start -->

**Status:** Shipped 2026-07-27  **Plan:** [split-remaining-plugin-skills.md](plans/split-remaining-plugin-skills.md)
**Type:** refactor

## What shipped

- Split `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md` into a core plus `references/description-rules.md`, `references/invocation-control.md`, `references/measurement.md`, and `references/budget-advisory.md`; the core satisfies its own progressive-disclosure rubric.
- Split `kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md` into a core plus `references/rule-modes.md`, `references/rule-file-format.md`, and `references/write-verification.md`; kept the write-after-every-write STOP rule in the core.
- Split `kit/plugins/code-testing-agent/skills/tdd-fix/SKILL.md` into a core plus `references/fix-loop.md` and `references/handoff.md`, matching the per-skill `references/` layout its four siblings already use.
- Split `kit/plugins/content-tools/skills/artifact-to-post/SKILL.md` into a core plus plugin-level `references/source-resolution.md` and `references/post-assembly.md`; kept the Phase 2 scrub gate and `write nothing and end the turn` language in the core.
- Split `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` into a core plus plugin-level `references/diff-sources.md`, `references/diff-page.md`, and `references/diff-publishing.md`; kept the Step 2 scrub gate and Step 5 rendered-page rescan in the core.
- Split `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` into a core plus plugin-level `references/prompt-resolution.md`, `references/prompt-page.md`, and `references/prompt-publishing.md`; kept the Step 4 scrub gate and never-publish-empty-gallery stop in the core.
- Added `tests/plugins/test-remaining-skill-splits.sh` — asserts all six cores are under 600 words, reference files exist and resolve, and the security-scrub gate with hard-stop language is present in both artifact-tools cores; wired into `.github/workflows/check-plugin-versions.yml`.
- Updated `tests/plugins/test-artifact-tools.sh`, `tests/plugins/test-artifact-to-post.sh`, `tests/plugins/test-memory-doctor-guard.sh`, and `tests/plugins/test-proposal-prompt-pipeline.sh` to assert moved literals against their new reference files.
- Added five previously-unwired tests as named steps in `.github/workflows/check-plugin-versions.yml`.
- Bumped skill-reviewer to `2.3.0`, memory-tools to `4.1.0`, code-testing-agent to `3.5.0`, content-tools to `1.1.0`, and artifact-tools to `1.9.0` in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md` | Skill core | Modified |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references/` | Reference files (4) | Created |
| `kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md` | Skill core | Modified |
| `kit/plugins/memory-tools/skills/path-rules-advisor/references/` | Reference files (3) | Created |
| `kit/plugins/code-testing-agent/skills/tdd-fix/SKILL.md` | Skill core | Modified |
| `kit/plugins/code-testing-agent/skills/tdd-fix/references/` | Reference files (2) | Created |
| `kit/plugins/content-tools/skills/artifact-to-post/SKILL.md` | Skill core | Modified |
| `kit/plugins/content-tools/references/` | Reference files (2) | Created |
| `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` | Skill core | Modified |
| `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` | Skill core | Modified |
| `kit/plugins/artifact-tools/references/` | Reference files (6) | Created |
| `tests/plugins/test-remaining-skill-splits.sh` | Objective test | Created |
| `tests/plugins/test-artifact-tools.sh` | Behavior test | Modified |
| `tests/plugins/test-artifact-to-post.sh` | Behavior test | Modified |
| `tests/plugins/test-memory-doctor-guard.sh` | Behavior test | Modified |
| `tests/plugins/test-proposal-prompt-pipeline.sh` | Behavior test | Modified |
| `.github/workflows/check-plugin-versions.yml` | CI configuration | Modified |
| `.claude-plugin/marketplace.json` | Marketplace versions | Modified |
| `kit/plugins/skill-reviewer/CHANGELOG.md` | Release notes | Modified |
| `kit/plugins/memory-tools/CHANGELOG.md` | Release notes | Modified |
| `kit/plugins/code-testing-agent/CHANGELOG.md` | Release notes | Modified |
| `kit/plugins/content-tools/CHANGELOG.md` | Release notes | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | Release notes | Modified |

## How it works

These six skills were the last monolithic SKILL.md files in the repo over 1,200 words shipping without sibling reference files, totalling 10,545 words (10,681 by the canonical Python counter). The split follows the patterns already established by `plan-agent/skills/implementation-plan/` and `code-testing-agent` — a core under 600 words holding trigger, step names, and any safety gates, with mechanics in per-topic reference files.

The security-scrub gate in `diff-artifact` and `prompt-artifact` was the primary constraint shaping both splits. Publishing is outward-facing and irreversible; a gate behind a reference file the model might not load is a potential leak. Both gates — the `security-scrub` invocation, the `GATE RESULT: BLOCKED/CANCELLED/APPROVED` verdicts, and the hard-stop language — remain in the cores. The objective test asserts this specifically: it fails if the gate is only in a reference file.

Each plugin keeps its existing reference layout rather than adopting a new one. `artifact-tools` and `content-tools` already resolved references at plugin level via `${CLAUDE_PLUGIN_ROOT}/references/`; `skill-reviewer`, `memory-tools`, and `code-testing-agent` use per-skill `references/` directories. Both are valid; mixing them inside one plugin would break reader expectations.

Four test files asserted literals by reading the original skill bodies directly. Updating them to follow the moved content was part of each step, not a cleanup pass — a test that reads an empty file because the content moved is a passing test that measures nothing.

Two CI-invisible defects were found and fixed during implementation. The Python word counter was added when CI initially failed because `wc -w` undercounted UTF-8 punctuation in the C locale by 9–23 words per file, causing three cores to ship over the ceiling. A `SIGPIPE` abort in `test-memory-doctor-guard.sh` was fixed by buffering the extracted code to a file rather than piping it through `awk`, which closed the reader mid-write under `set -o pipefail`. Five previously-written tests that were not wired into CI were also added as named steps, since their assertions now depended on content that had moved.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|

<!-- generated:end -->

## References

- Plan: [split-remaining-plugin-skills.md](plans/split-remaining-plugin-skills.md)
