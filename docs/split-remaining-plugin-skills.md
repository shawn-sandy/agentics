# Stop paying 10,545 words every time these six skills fire

> Six skills across five plugins each dump between 1,202 and 3,153 words into context every single time they fire, and the largest of them is the rubric that t...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [split-remaining-plugin-skills.md](plans/split-remaining-plugin-skills.md)
**Type:** refactor

## What shipped

- Record a pre-split baseline into the scratchpad: `for f in <the six SKILL.md paths>; do echo "$(wc -w < $f) $f"; done...
- Split `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md` into a core plus `references/descript...
- Split `kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md` into a core plus `references/rule-modes.md`, `ref...
- Split `kit/plugins/code-testing-agent/skills/tdd-fix/SKILL.md` into a core plus `references/fix-loop.md` and `referen...
- Split `kit/plugins/content-tools/skills/artifact-to-post/SKILL.md` into a core plus `kit/plugins/content-tools/refere...
- Split `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` into a core plus `references/diff-sources.md`, `refe...
- Split `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` into a core plus `references/prompt-resolution.md`...
- Write `tests/plugins/test-remaining-skill-splits.sh` asserting all four objective conditions for the six targets, and...
- Bump `skill-reviewer` to 2.3.0, `memory-tools` to 4.1.0, `code-testing-agent` to 3.5.0, `content-tools` to 1.1.0, and...

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md` | core keeps overview, `## When not to use`, and Step 0–6 n... | Modified |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references/description-rules.md` | Rules 1, 2, 2b, 3, 4, 5 plus worked examples A and B | Created |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references/invocation-control.md` | Step 4b classification table, confirmation options, and t... | Created |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references/measurement.md` | the Step 2, Step 5, and Step 6 bash measuring loops | Created |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references/budget-advisory.md` | the `skillListingBudgetFraction` advisory, the installed-... | Created |
| `kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md` | core keeps mode selection, both hard-stop confirmations, ... | Modified |
| `kit/plugins/memory-tools/skills/path-rules-advisor/references/rule-modes.md` | Mode A Steps 1–7 and Mode B Steps 1–7 in full | Created |
| `kit/plugins/memory-tools/skills/path-rules-advisor/references/rule-file-format.md` | the generated-file template, brace expansion, and the Not... | Created |
| `kit/plugins/memory-tools/skills/path-rules-advisor/references/write-verification.md` | the diff-back bash plus the python frontmatter parse chec... | Created |
| `kit/plugins/code-testing-agent/skills/tdd-fix/SKILL.md` | core keeps the freedom-level marker, `## When not to use`... | Modified |
| `kit/plugins/code-testing-agent/skills/tdd-fix/references/fix-loop.md` | Step 2 red phase, Step 3 iteration log and 3a–3c, Step 4 ... | Created |
| `kit/plugins/code-testing-agent/skills/tdd-fix/references/handoff.md` | Step 5 regression sweep, Step 6 summary block, Steps 7–8 ... | Created |
| `kit/plugins/content-tools/skills/artifact-to-post/SKILL.md` | core keeps Phase 0 asset locating, the Phase 2 scrub gate... | Modified |
| `kit/plugins/content-tools/references/source-resolution.md` | the Phase 1 source table, the claude.ai refusal text, and... | Created |
| `kit/plugins/content-tools/references/post-assembly.md` | Phase 4 extraction and ceiling behavior, Phase 5 prose re... | Created |
| `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` | core keeps the Step 2 scrub gate, the Step 5 rescan, and ... | Modified |
| `kit/plugins/artifact-tools/references/diff-sources.md` | mode table, default-branch resolution, and the PR-mode de... | Created |
| `kit/plugins/artifact-tools/references/diff-page.md` | severity table, cap-and-summarize budget, page requiremen... | Created |
| `kit/plugins/artifact-tools/references/diff-publishing.md` | durable-copy keying, publish and URL recording, failure f... | Created |
| `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` | core keeps the Step 4 scrub gate, the empty-library stop,... | Modified |
| `kit/plugins/artifact-tools/references/prompt-resolution.md` | mode table, the `PROMPTS_DIR` python resolver, and single... | Created |
| `kit/plugins/artifact-tools/references/prompt-page.md` | page requirements, the six-value escaping table, and the ... | Created |
| `kit/plugins/artifact-tools/references/prompt-publishing.md` | the URL-record table, the `.artifact-url` sidecar, render... | Created |
| `tests/plugins/test-remaining-skill-splits.sh` | objective-verification test for all six splits | Created |
| `tests/plugins/test-artifact-tools.sh` | literal assertions follow the moved content into `referen... | Modified |
| `tests/plugins/test-artifact-to-post.sh` | config-key and ladder assertions follow the moved content | Modified |
| `tests/plugins/test-memory-doctor-guard.sh` | extracts the parse check and the bash commands from core ... | Modified |
| `tests/plugins/test-generator-skills-verify-output.sh` | `path-rules-advisor` wiring regex repointed at the refere... | Modified |
| `.github/workflows/check-plugin-versions.yml` | new step running the objective test | Modified |
| `.claude-plugin/marketplace.json` | five minor version bumps | Modified |
| `kit/plugins/skill-reviewer/CHANGELOG.md` | v2.3.0 entry | Modified |
| `kit/plugins/memory-tools/CHANGELOG.md` | v4.1.0 entry | Modified |
| `kit/plugins/code-testing-agent/CHANGELOG.md` | v3.5.0 entry | Modified |
| `kit/plugins/content-tools/CHANGELOG.md` | 1.1.0 entry | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | `## [1.8.0]` entry in bracketed form | Modified |

## How it works

Split the six remaining monolithic SKILL.md files — across `skill-reviewer`, `artifact-tools`, `memory-tools`, `content-tools`, and `code-testing-agent` — into small cores plus per-topic reference files, each core under 600 words, with every skill's behavior and frontmatter `description` left byte-identical.

Anthropic's "The new rules of context engineering for Claude 5 generation models" makes progressive disclosure (Rule 3) the load-bearing rule for skills: move detail out of the always-loaded body into references the model pulls on demand, and split long skills into multiple files. A SKILL.md body is paid in **full** whenever the skill triggers — there is no partial load, no lazy tail. A measured audit of this repo found 17 SKILL.md files over 1,200 words shipping as a single file with zero sibli...

The implementation proceeded through these steps: Record a pre-split baseline into the scratchpad: `for f in <the six SKILL.md paths>; do echo "$(wc -w < $f) $f"; done...; Split `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md` into a core plus `references/descript...; Split `kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md` into a core plus `references/rule-modes.md`, `ref...; Split `kit/plugins/code-testing-agent/skills/tdd-fix/SKILL.md` into a core plus `references/fix-loop.md` and `referen...; Split `kit/plugins/content-tools/skills/artifact-to-post/SKILL.md` into a core plus `kit/plugins/content-tools/refere....

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates ( |

<!-- generated:end -->

## References

- Plan: [split-remaining-plugin-skills.md](plans/split-remaining-plugin-skills.md)
