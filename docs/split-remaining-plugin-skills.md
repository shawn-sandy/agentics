# Stop paying 10,545 words every time these six skills fire

> Split the six remaining monolithic SKILL.md files across five plugins into small cores plus per-topic reference files, reducing always-loaded context while keeping every security gate in the core.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [split-remaining-plugin-skills.md](plans/split-remaining-plugin-skills.md)
**Type:** refactor

## What shipped

- Split six remaining monolithic SKILL.md files — `optimizing-skill-frontmatter` (3,153 words), `prompt-artifact` (1,665), `diff-artifact` (1,549), `path-rules-advisor` (1,546), `artifact-to-post` (1,430), and `tdd-fix` (1,202) — into cores under 600 words plus reference files.
- Created 17 new reference files placed per-skill (`skill-reviewer`, `memory-tools`, `code-testing-agent`) or at plugin level (`artifact-tools`, `content-tools`), matching each plugin's existing convention.
- Kept the `security-scrub` gate, `GATE RESULT: BLOCKED/CANCELLED/APPROVED` verdicts, and hard-stop language in the *core* of both `diff-artifact` and `prompt-artifact` — not in a reference file the model might not load.
- Added `tests/plugins/test-remaining-skill-splits.sh` asserting all six cores are under 600 words, have the correct number of reference files, every `references/*.md` link resolves, no reference is orphaned, and the security-scrub gate appears in both artifact-tools cores.
- Updated four existing tests (`test-artifact-tools.sh`, `test-artifact-to-post.sh`, `test-memory-doctor-guard.sh`, `test-generator-skills-verify-output.sh`) to follow moved content into reference files.
- Wired five previously CI-unwired tests into `.github/workflows/check-plugin-versions.yml`.
- Bumped five plugins: `skill-reviewer` 2.4.0, `memory-tools` 4.1.0, `code-testing-agent` 3.5.0, `content-tools` 1.1.0, `artifact-tools` 1.9.0 (planned 1.8.0 was preempted by a concurrent PR; see plan Completion Report).

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md` | Skill core | Modified |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references/description-rules.md` | Reference — Rules 1-5 and worked examples | Created |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references/invocation-control.md` | Reference — Step 4b classification and apply rules | Created |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references/measurement.md` | Reference — measuring bash loops | Created |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references/budget-advisory.md` | Reference — budget fraction and /doctor guidance | Created |
| `kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md` | Skill core — hard-stop confirmations kept | Modified |
| `kit/plugins/memory-tools/skills/path-rules-advisor/references/rule-modes.md` | Reference — Mode A and Mode B steps | Created |
| `kit/plugins/memory-tools/skills/path-rules-advisor/references/rule-file-format.md` | Reference — generated-file template | Created |
| `kit/plugins/memory-tools/skills/path-rules-advisor/references/write-verification.md` | Reference — diff-back bash + python parse check | Created |
| `kit/plugins/code-testing-agent/skills/tdd-fix/SKILL.md` | Skill core | Modified |
| `kit/plugins/code-testing-agent/skills/tdd-fix/references/fix-loop.md` | Reference — red phase, iteration log | Created |
| `kit/plugins/code-testing-agent/skills/tdd-fix/references/handoff.md` | Reference — regression sweep, commit/PR handoffs | Created |
| `kit/plugins/content-tools/skills/artifact-to-post/SKILL.md` | Skill core — Phase 2 scrub gate kept | Modified |
| `kit/plugins/content-tools/references/source-resolution.md` | Reference — Phase 1 source table | Created |
| `kit/plugins/content-tools/references/post-assembly.md` | Reference — Phase 4-10 assembly and publish | Created |
| `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` | Skill core — Step 2 scrub + Step 5 rescan kept | Modified |
| `kit/plugins/artifact-tools/references/diff-sources.md` | Reference — mode table, default-branch resolution | Created |
| `kit/plugins/artifact-tools/references/diff-page.md` | Reference — severity table, cap-and-summarize | Created |
| `kit/plugins/artifact-tools/references/diff-publishing.md` | Reference — durable-copy keying, URL recording | Created |
| `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` | Skill core — Step 4 scrub gate kept | Modified |
| `kit/plugins/artifact-tools/references/prompt-resolution.md` | Reference — PROMPTS_DIR resolver | Created |
| `kit/plugins/artifact-tools/references/prompt-page.md` | Reference — escaping table, copy-button script | Created |
| `kit/plugins/artifact-tools/references/prompt-publishing.md` | Reference — URL-record table, .artifact-url sidecar | Created |
| `tests/plugins/test-remaining-skill-splits.sh` | Objective test | Created |
| `.github/workflows/check-plugin-versions.yml` | CI — five tests wired, one new | Modified |

## How it works

The most constrained split was `optimizing-skill-frontmatter` — the rubric that defines the 200-char description budget and progressive-disclosure requirements every other skill is measured against. Splitting it required satisfying its own advice, including the reference-depth-≤1 constraint. The core keeps only `## When not to use`, the step names, and links to four reference files; the measurement loops, worked examples, invocation-control table, and budget-advisory section moved into references.

Both artifact-tools security gates stayed in their respective cores, not in references. Publishing is irreversible and outward-facing; a gate a model might not load is a secret leak. The objective test asserts `security-scrub` appears in the *core* of both `diff-artifact` and `prompt-artifact`, anchored ahead of the `select:Artifact` publish step.

`path-rules-advisor` presented a specific challenge: `test-memory-doctor-guard.sh` extracts the python frontmatter parse check from the skill body and executes it directly. After the split, the check moved to `references/write-verification.md`. The test was updated to extract from core plus all reference files — and a buffer-to-file fix was required to prevent SIGPIPE when the skill body is large enough to exceed the pipe buffer.

The word ceiling is measured in Python rather than `wc -w` because these files contain multibyte characters (`—`, `≤`, `→`) that produce different counts in C vs C.UTF-8 locale (~20-word swing per file). The C locale undercount was how three cores appeared to pass locally but failed on the CI runner.

## How to use it

The split is transparent to users. All six skills activate and behave identically to before. Security gates fire from the core, so they load unconditionally on every trigger.

```bash
/skill-reviewer:optimizing-skill-frontmatter kit/plugins/my-plugin/skills/my-skill/SKILL.md
/memory-tools:path-rules-advisor
/code-testing-agent:tdd-fix
/content-tools:artifact-to-post
/artifact-tools:diff-artifact
/artifact-tools:prompt-artifact
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `e460fcc5` | 2026-10-26 | test: drop the stale path-rules-advisor drift-ledger entry (#659) |
| `02136c1d` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [split-remaining-plugin-skills.md](plans/split-remaining-plugin-skills.md)
