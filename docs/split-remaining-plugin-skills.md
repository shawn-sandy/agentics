# Stop paying 10,681 words every time these six skills fire

> Split six monolithic SKILL.md files across skill-reviewer, artifact-tools, memory-tools, content-tools, and code-testing-agent into small cores under 600 words plus on-demand reference files, cutting always-loaded skill context by 68% while keeping every security gate in the core where the model cannot fail to load it.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [split-remaining-plugin-skills.md](plans/split-remaining-plugin-skills.md)
**Type:** refactor

## What shipped

- Split `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md` (3,153 words) into a core plus four reference files: `description-rules.md`, `invocation-control.md`, `measurement.md`, and `budget-advisory.md`.
- Split `kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md` (1,546 words) into a core plus `rule-modes.md`, `rule-file-format.md`, and `write-verification.md`; the executable parse check moved to `write-verification.md` while the STOP contract stayed in the core; updated `test-memory-doctor-guard.sh` and `test-generator-skills-verify-output.sh` to extract from core plus references.
- Split `kit/plugins/code-testing-agent/skills/tdd-fix/SKILL.md` (1,202 words) into a core plus `fix-loop.md` and `handoff.md`, matching the per-skill `references/` layout its four siblings already use.
- Split `kit/plugins/content-tools/skills/artifact-to-post/SKILL.md` (1,430 words) into a core plus `source-resolution.md` and `post-assembly.md` at the plugin level beside the existing `content-config.md` and `mdx-safety.md`; updated `test-artifact-to-post.sh`.
- Split `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` (1,549 words) into a core plus `diff-sources.md`, `diff-page.md`, and `diff-publishing.md` at the plugin level; the Step 2 security-scrub gate and Step 5 rendered-page rescan stayed in the core.
- Split `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` (1,665 words) into a core plus `prompt-resolution.md`, `prompt-page.md`, and `prompt-publishing.md`; the Step 4 scrub gate and the never-publish-an-empty-gallery stop stayed in the core; updated `test-artifact-tools.sh`.
- Added `tests/plugins/test-remaining-skill-splits.sh` as the objective CI gate, wired into `.github/workflows/check-plugin-versions.yml`.
- Fixed a locale-dependent word-count bug where the CI runner's C.UTF-8 locale counted multibyte characters (`—`, `≤`, `→`) as words while the C locale did not (~20-word swing per file); the test now counts in Python, which is locale-independent.
- Bumped skill-reviewer to 2.3.0, memory-tools to 4.1.0, code-testing-agent to 3.5.0, content-tools to 1.1.0, and artifact-tools to 1.9.0 (plan specified 1.8.0 but main was already at 1.8.0 by ship time).

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md` | Skill core — overview, When not to use, Step 0–6 names | Modified |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references/description-rules.md` | Reference — Rules 1–5, worked examples A and B | Created |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references/invocation-control.md` | Reference — Step 4b classification table, confirmation options, grep-then-Edit apply rules | Created |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references/measurement.md` | Reference — Step 2, 5, 6 bash measuring loops | Created |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references/budget-advisory.md` | Reference — `skillListingBudgetFraction` advisory, installed-skills table, `/doctor` guidance | Created |
| `kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md` | Skill core — mode selection, both hard-stop confirmations, write-verification rule | Modified |
| `kit/plugins/memory-tools/skills/path-rules-advisor/references/rule-modes.md` | Reference — Mode A Steps 1–7 and Mode B Steps 1–7 | Created |
| `kit/plugins/memory-tools/skills/path-rules-advisor/references/rule-file-format.md` | Reference — generated-file template, brace expansion, Notes | Created |
| `kit/plugins/memory-tools/skills/path-rules-advisor/references/write-verification.md` | Reference — diff-back bash, Python frontmatter parse check, pre-write gate | Created |
| `kit/plugins/code-testing-agent/skills/tdd-fix/SKILL.md` | Skill core — freedom-level marker, When not to use, Step 0–9 names | Modified |
| `kit/plugins/code-testing-agent/skills/tdd-fix/references/fix-loop.md` | Reference — Step 2 red phase, Step 3 iteration log and 3a–3c, Step 4 hard cap | Created |
| `kit/plugins/code-testing-agent/skills/tdd-fix/references/handoff.md` | Reference — Step 5 regression sweep, Step 6 summary block, Steps 7–8 commit/pr-agent handoffs | Created |
| `kit/plugins/content-tools/skills/artifact-to-post/SKILL.md` | Skill core — Phase 0 asset locating, Phase 2 scrub gate verbatim, Phase 1–10 names | Modified |
| `kit/plugins/content-tools/references/source-resolution.md` | Reference — Phase 1 source table, claude.ai refusal text, Markdown-source rule | Created |
| `kit/plugins/content-tools/references/post-assembly.md` | Reference — Phase 4–5 extraction/rewrite, Phase 7–8 screenshots/write, Phase 10 publish gate | Created |
| `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` | Skill core — Step 2 scrub gate, Step 5 rescan, Step 1–8 headings | Modified |
| `kit/plugins/artifact-tools/references/diff-sources.md` | Reference — mode table, default-branch resolution, PR-mode degradation script | Created |
| `kit/plugins/artifact-tools/references/diff-page.md` | Reference — severity table, cap-and-summarize budget, page requirements, 16 MiB shrink loop | Created |
| `kit/plugins/artifact-tools/references/diff-publishing.md` | Reference — durable-copy keying, publish and URL recording, failure fallback, render verification | Created |
| `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` | Skill core — Step 4 scrub gate, empty-library stop, Step 1–8 headings | Modified |
| `kit/plugins/artifact-tools/references/prompt-resolution.md` | Reference — mode table, `PROMPTS_DIR` Python resolver, single/library prompt resolution | Created |
| `kit/plugins/artifact-tools/references/prompt-page.md` | Reference — page requirements, six-value escaping table, copy-button script | Created |
| `kit/plugins/artifact-tools/references/prompt-publishing.md` | Reference — URL-record table, `.artifact-url` sidecar, render verification, fallback | Created |
| `tests/plugins/test-remaining-skill-splits.sh` | Objective test — word ceiling plus link integrity plus security-gate assertions | Created |
| `tests/plugins/test-artifact-tools.sh` | Test suite — literal assertions updated to reference files holding moved content | Modified |
| `tests/plugins/test-artifact-to-post.sh` | Test suite — config-key and ladder assertions updated | Modified |
| `tests/plugins/test-memory-doctor-guard.sh` | Test suite — extracts parse check from core plus references | Modified |
| `tests/plugins/test-generator-skills-verify-output.sh` | Test suite — path-rules-advisor wiring regex repointed at reference link | Modified |
| `.github/workflows/check-plugin-versions.yml` | CI — step running `test-remaining-skill-splits.sh` | Modified |
| `.claude-plugin/marketplace.json` | Marketplace — five minor version bumps | Modified |
| `kit/plugins/skill-reviewer/CHANGELOG.md` | Changelog — 2.3.0 entry | Modified |
| `kit/plugins/memory-tools/CHANGELOG.md` | Changelog — 4.1.0 entry | Modified |
| `kit/plugins/code-testing-agent/CHANGELOG.md` | Changelog — 3.5.0 entry | Modified |
| `kit/plugins/content-tools/CHANGELOG.md` | Changelog — 1.1.0 entry | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | Changelog — `## [1.9.0]` entry | Modified |

## How it works

A SKILL.md body is paid in full every time the skill triggers. `optimizing-skill-frontmatter` at 3,153 words was the single largest monolithic skill in the repo — and the rubric that every other skill is judged against. It could not keep violating its own progressive-disclosure advice. The other five ranged from 1,202 to 1,665 words; together the six totaled 10,681 canonical words loaded every time any of them fired.

The split pattern was already proven in-repo. `code-testing-agent` already ships `references/` on four of its five skills; `content-tools` already resolves plugin-level references via `$SKILL_DIR/../../references/`; `artifact-tools` already has plugin-level `references/titles.md`. Each split matched the convention already present in its own plugin rather than imposing a new layout.

Two constraints shaped the artifact-tools splits. The security-scrub gate in both `diff-artifact` and `prompt-artifact` — the invocation, the `GATE RESULT: BLOCKED`/`CANCELLED`/`APPROVED` verdicts, and the hard-stop language — stayed in the core of both skills, not in a reference file. Publishing is outward-facing and irreversible; a gate behind a lazy reference is a gate that might not load. The objective test asserts the gate words appear in the *core* file. The existing `test-artifact-tools.sh` ordering assertion (scrub gate precedes `select:Artifact`) was kept anchored on both cores.

The `path-rules-advisor` split exposed a subtler tension: the executable parse check (400 words of bash and Python) needed to move to `write-verification.md` to bring the core under 600 words, but the *rule* it enforces — run this after every write, STOP on non-zero — stayed in the core with an in-core link to the reference. The `test-memory-doctor-guard.sh` test executes code extracted directly from the skill, so it was updated to search both the core and `references/*.md` rather than just the core.

The locale-dependent word-count bug was found when CI first ran. The cores measured 573–594 words in the C locale used in the development container and 589–617 on the runner's C.UTF-8 locale — a ~20-word swing per file caused by multibyte characters (`—`, `≤`, `→`) counting as one word in C.UTF-8 but zero in C. The objective test was rewritten to count in Python (`len(open(f).read().split())`), which decodes UTF-8 regardless of ambient locale. Post-split word counts: 579 / 522 / 571 / 571 / 566 / 583 — each with 17+ words of margin.

The `artifact-tools` CHANGELOG uses a bracketed heading format (`## [1.8.0] - YYYY-MM-DD`) because `test-artifact-tools.sh` asserts the marketplace version equals the newest `## [x.y.z]` heading. The shipped version is 1.9.0 rather than the planned 1.8.0 because PR #658 had already landed 1.8.0 on main before this shipped.

> See the respective plugin CHANGELOGs for the authoritative feature lists.

## How to use it

The skills invoke identically — the split is transparent to users. The only observable change is that a session invoking these skills now loads only the core on trigger and reads reference files on demand as steps are executed.

```bash
# These invocations are unchanged
/skill-reviewer:optimizing-skill-frontmatter
/memory-tools:path-rules-advisor
/code-testing-agent:tdd-fix
/content-tools:artifact-to-post
/artifact-tools:diff-artifact
/artifact-tools:prompt-artifact
```

The objective test verifies the split is correct:

```bash
bash tests/plugins/test-remaining-skill-splits.sh
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `02136c1` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `052d88c` | 2026-10-08 | refactor(git-agent): commit-agent pushes without asking (4.23.0) (#646) |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [split-remaining-plugin-skills.md](plans/split-remaining-plugin-skills.md)
- Related docs: [split-plan-agent-skills.md](split-plan-agent-skills.md)
- Changelogs: `kit/plugins/skill-reviewer/CHANGELOG.md` — 2.3.0 entry; `kit/plugins/memory-tools/CHANGELOG.md` — 4.1.0 entry; `kit/plugins/code-testing-agent/CHANGELOG.md` — 3.5.0 entry; `kit/plugins/content-tools/CHANGELOG.md` — 1.1.0 entry; `kit/plugins/artifact-tools/CHANGELOG.md` — 1.9.0 entry
