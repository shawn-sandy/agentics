# Stop paying 10,545 words every time these six skills fire

> Split six remaining monolithic SKILL.md files across five plugins into small cores plus reference files, cutting 10,681 words to 3,392 while preserving every security gate, all frontmatter descriptions, and the full behavior of each skill.

<!-- generated:start -->

**Status:** Shipped 2026-08-18 **Plan:** [split-remaining-plugin-skills.md](plans/split-remaining-plugin-skills.md)
**Type:** refactor

## What shipped

- Split `skill-reviewer/optimizing-skill-frontmatter` (3,153 words) into a core plus `references/description-rules.md`, `references/invocation-control.md`, `references/measurement.md`, and `references/budget-advisory.md`
- Split `memory-tools/path-rules-advisor` (1,546 words) into a core plus `references/rule-modes.md`, `references/rule-file-format.md`, and `references/write-verification.md`; kept the STOP contract and pre-write gate in the core
- Split `code-testing-agent/tdd-fix` (1,202 words) into a core plus `references/fix-loop.md` and `references/handoff.md`, matching the layout of its four sibling skills
- Split `content-tools/artifact-to-post` (1,430 words) into a core plus plugin-level `references/source-resolution.md` and `references/post-assembly.md`; Phase 2 scrub gate stayed in the core
- Split `artifact-tools/diff-artifact` (1,549 words) into a core plus plugin-level `references/diff-sources.md`, `references/diff-page.md`, and `references/diff-publishing.md`; Step 2 scrub gate and Step 5 rescan stayed in the core
- Split `artifact-tools/prompt-artifact` (1,665 words) into a core plus plugin-level `references/prompt-resolution.md`, `references/prompt-page.md`, and `references/prompt-publishing.md`; Step 4 scrub gate stayed in the core
- Wrote `tests/plugins/test-remaining-skill-splits.sh` asserting all four objective conditions (word ceiling, reference count, no orphans, no dangling links, security gates in cores)
- Updated `tests/plugins/test-artifact-tools.sh`, `test-artifact-to-post.sh`, `test-memory-doctor-guard.sh`, and `test-proposal-prompt-pipeline.sh` so literal assertions follow moved content into reference files
- Wired five tests without CI coverage into `.github/workflows/check-plugin-versions.yml` as named steps
- Bumped all five plugins: `skill-reviewer` 2.3.0, `memory-tools` 4.1.0, `code-testing-agent` 3.5.0, `content-tools` 1.1.0, `artifact-tools` 1.9.0

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md` | Core: overview, When not to use, step names | Modified |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references/description-rules.md` | Rules 1–5 and worked examples | Created |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references/invocation-control.md` | Step 4b classification table, apply rules | Created |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references/measurement.md` | Steps 2, 5, 6 bash measuring loops | Created |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references/budget-advisory.md` | Budget fraction advisory and `/doctor` guidance | Created |
| `kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md` | Core: mode selection, both hard-stop confirmations, write-verification rule | Modified |
| `kit/plugins/memory-tools/skills/path-rules-advisor/references/rule-modes.md` | Mode A and Mode B steps in full | Created |
| `kit/plugins/memory-tools/skills/path-rules-advisor/references/rule-file-format.md` | Generated-file template, brace expansion | Created |
| `kit/plugins/memory-tools/skills/path-rules-advisor/references/write-verification.md` | Diff-back bash, Python frontmatter parse check, pre-write gate | Created |
| `kit/plugins/code-testing-agent/skills/tdd-fix/SKILL.md` | Core: freedom-level marker, When not to use, step names | Modified |
| `kit/plugins/code-testing-agent/skills/tdd-fix/references/fix-loop.md` | Step 2 red phase, Step 3 iteration log, Step 4 hard cap | Created |
| `kit/plugins/code-testing-agent/skills/tdd-fix/references/handoff.md` | Steps 5–8: regression sweep, summary block, commit/PR handoffs | Created |
| `kit/plugins/content-tools/skills/artifact-to-post/SKILL.md` | Core: Phase 0 asset locating, Phase 2 scrub gate, phase names | Modified |
| `kit/plugins/content-tools/references/source-resolution.md` | Phase 1 source table, Markdown-source rule | Created |
| `kit/plugins/content-tools/references/post-assembly.md` | Phases 4, 5, 7, 8, 10 | Created |
| `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` | Core: Step 2 scrub gate, Step 5 rescan, all Step N headings | Modified |
| `kit/plugins/artifact-tools/references/diff-sources.md` | Mode table, default-branch resolution, PR-mode degradation | Created |
| `kit/plugins/artifact-tools/references/diff-page.md` | Severity table, cap-and-summarize budget, 16 MiB shrink loop | Created |
| `kit/plugins/artifact-tools/references/diff-publishing.md` | Durable-copy keying, publish URL recording, failure fallback | Created |
| `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` | Core: Step 4 scrub gate, empty-library stop, all Step N headings | Modified |
| `kit/plugins/artifact-tools/references/prompt-resolution.md` | Mode table, PROMPTS_DIR resolver, single/library resolution | Created |
| `kit/plugins/artifact-tools/references/prompt-page.md` | Page requirements, escaping table, copy-button script | Created |
| `kit/plugins/artifact-tools/references/prompt-publishing.md` | URL-record table, `.artifact-url` sidecar, render verification | Created |
| `tests/plugins/test-remaining-skill-splits.sh` | Objective test: word ceiling, reference integrity, gate presence | Created |
| `tests/plugins/test-artifact-tools.sh` | Literal assertions repointed to reference files | Modified |
| `tests/plugins/test-artifact-to-post.sh` | Config-key and ladder assertions repointed | Modified |
| `tests/plugins/test-memory-doctor-guard.sh` | Parse check extraction reads core plus references | Modified |
| `.github/workflows/check-plugin-versions.yml` | New CI step plus five previously unwired tests added as named steps | Modified |
| `.claude-plugin/marketplace.json` | Five minor version bumps | Modified |
| `kit/plugins/skill-reviewer/CHANGELOG.md` | v2.3.0 entry | Modified |
| `kit/plugins/memory-tools/CHANGELOG.md` | v4.1.0 entry | Modified |
| `kit/plugins/code-testing-agent/CHANGELOG.md` | v3.5.0 entry | Modified |
| `kit/plugins/content-tools/CHANGELOG.md` | 1.1.0 entry | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | `## [1.9.0]` entry | Modified |

## How it works

This plan completed the split begun in `split-plan-agent-skills`, handling the six remaining monolithic SKILL.md files across five plugins. The pattern — a small core under 600 words holding trigger, arguments, and step names, with mechanics in on-demand `references/<topic>.md` files — was established in `plan-agent` and applied here wholesale.

Three hazards shaped the work. The most subtle was `optimizing-skill-frontmatter` being self-referential: it is `skill-reviewer`'s own authoring rubric — the file that defines the three-part description format, the ≤200-char budget, and the ≤80-char first sentence that everything else in the repo is measured against. Splitting it meant the split itself had to satisfy the rubric it teaches. After shipping, `/skill-reviewer:reviewing-skills` was run against the split core as final verification.

The second hazard was the `security-scrub` gate in `diff-artifact` and `prompt-artifact`. Publishing is outward-facing and irreversible; a gate the model fails to load is a secret leak, not a style regression. The gate — the `security-scrub` invocation, the `GATE RESULT: BLOCKED/CANCELLED/APPROVED` verdicts, and the hard-stop language — was kept in the core of both skills and never moved to a reference. `tests/plugins/test-remaining-skill-splits.sh` asserts the gate text is present in the cores specifically, not merely somewhere in the plugin, and that it precedes the `select:Artifact` publish bootstrap by line order.

The third hazard was the existing test suite. Four tests read these skill bodies as data: `test-artifact-tools.sh` greps literals like `cap-and-summarize`, `16 MiB`, and the `${DEFAULT_BRANCH}...HEAD` fallback line; `test-artifact-to-post.sh` greps config keys and compares phase line numbers; `test-memory-doctor-guard.sh` extracts the bash and Python parse check out of `path-rules-advisor/SKILL.md` and executes it; `test-generator-skills-verify-output.sh` requires a `## Step N — Publish` heading in the artifact skill cores. Every step that moved content also updated the affected test in the same step, and each step's Verify ran that test before proceeding.

The plugins use two layouts for reference files — `artifact-tools` and `content-tools` put them at plugin level, read via `${CLAUDE_PLUGIN_ROOT}/references/` or `$SKILL_DIR/../../references/`; `skill-reviewer`, `memory-tools`, and `code-testing-agent` put them per-skill under `skills/<name>/references/`. This plan matched each plugin's existing convention rather than imposing a uniform layout.

Word counting required care: `wc -w` is locale-dependent on files with multibyte characters (`—`, `≤`, `→`, `…`). A standalone `—` is not a word in the C locale but is one in C.UTF-8, a ~20-word swing per file. Three cores initially read under 600 in the dev container's C locale but over 600 on the CI runner's C.UTF-8 locale. The objective test was fixed to count in Python, which decodes UTF-8 regardless of ambient locale. All six cores were then trimmed to 566–583 words (canonical counter), each with at least 17 words of margin.

A late review finding exposed that five tests this work depended on were not wired into CI at all — including four retargeted to follow moved content and one whose unmodified pass was cited as the reason for not touching it. All five were added as named steps in `.github/workflows/check-plugin-versions.yml`, verified by running the check job's full step list under the runner's locale.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |

<!-- generated:end -->

## References

- Plan: [split-remaining-plugin-skills.md](plans/split-remaining-plugin-skills.md)
