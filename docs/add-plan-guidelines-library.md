# Ship the guidelines library and markdown-first authoring for implementation-plan

> Replaced the prescriptive 2,015-line HTML skeleton in `implementation-plan` with a four-document guidelines library and a markdown spec → render pipeline, cutting ~60k tokens per plan run.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [add-plan-guidelines-library.md](plans/add-plan-guidelines-library.md)
**Type:** feature

## What shipped

- Created four guideline documents under `skills/implementation-plan/guidelines/`: `planning-principles.md`, `section-catalog.md`, `right-sizing.md`, and `writing-style.md`. These carry the judgment (what sections to include, how to size a plan) that was previously embedded as rigid HTML rules.
- Rewrote `implementation-plan/SKILL.md` around a five-step pipeline: explore → read guidelines → author a markdown spec → render with `build-plan-html.mjs` → deliver. No step instructs the agent to hand-write plan HTML.
- Rewrote `reference/SKELETON.md` as a copyable spec starter using the exact heading and marker syntax `parseSpecMarkdown()` accepts. The old skeleton used headings the renderer rejected.
- Updated `tests/plugins/test-goal-prompt.sh` and `tests/plugins/test-resources-section.sh` to drop references to retired `{goal-prompt}` and resource placeholder strings.
- Bumped plan-agent to **2.19.0** in `.claude-plugin/marketplace.json`; updated description.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/planning-principles.md` | Guideline — falsifiable done, what/why/verify, scope discipline | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Guideline — section menu with purpose, triggers, exact spec syntax | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/right-sizing.md` | Guideline — depth profiles and calibration table | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/writing-style.md` | Guideline — tone and plain-language rules | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill instructions — rewritten around markdown pipeline | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Spec starter — headers and markers for the parser | Modified |
| `tests/plugins/test-goal-prompt.sh` | Smoke test — updated assertions | Modified |
| `tests/plugins/test-resources-section.sh` | Smoke test — updated assertions | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin documentation | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Version history | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry — 2.19.0 | Modified |

## How it works

Phase 1 of this work (plan-agent 2.18.0) shipped the deterministic renderer: `build-plan-html.mjs` parses a markdown plan spec and emits the full styled HTML with the exact DOM contract downstream tools depend on. Phase 2 (this plan) inverted the authoring flow.

Before the change, `implementation-plan/SKILL.md` instructed the agent to copy a 2,015-line HTML skeleton and fill placeholders — roughly 60k tokens of pure mechanics per plan run. After the change, the skill loads the four guideline documents via progressive disclosure: the agent reads the relevant guideline for the plan being authored, writes a small markdown spec, and renders it with `node build-plan-html.mjs`.

The four guideline documents separate concerns cleanly. `planning-principles.md` encodes the "what makes a good plan" judgments (falsifiable acceptance criteria, explicit *Why:* rationale, scope discipline). `section-catalog.md` is the machine-readable registry of every section the renderer knows, with purpose, trigger, and exact syntax. `right-sizing.md` maps a plan to a depth profile (minimal, standard, deep) based on team size and risk. `writing-style.md` carries the tone rules that were previously scattered inside the HTML skeleton.

The `reference/SKELETON.md` file was rewritten from scratch because the old skeleton used humanized headings (`## The Plan`, `## Acceptance`) that the renderer's parser did not accept. The new skeleton uses the exact heading strings and `[ ]` / `[x]` step markers the parser expects, so copying it produces a parseable spec rather than an error.

Existing tests that pinned placeholder strings (`{goal-prompt}`, `{Resources}`) in SKILL.md were updated to assert the new pipeline's contracts — the render command and the Step 8 menu structure.

## How to use it

**Skill:** activates on "create an implementation plan" or "write a plan" (description-driven).

```
/plan-agent:implementation-plan add rate limiting to the auth endpoint
```

The skill opens in explore mode, reads the relevant guidelines, authors a markdown spec, renders it, and delivers the plan HTML alongside the spec.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `43d18eec` | 2026-10-31 | fix(plan-agent,social-media-tools): remove model pins from skills (9.22.0, 2.25.0) (#668) |
| `02136c1d` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `1c315692` | 2026-10-14 | fix: stop goal loops on blocked checks (plan-agent 9.19.2) (#652) |
| `c16fe83f` | 2026-10-13 | feat(plan-agent): live UI previews inside plan pages (9.20.0) (#651) |
| `417a9579` | 2026-09-26 | feat(plan-agent): offer prototype and design canvas together in Step 8 (9.19.0) (#640) |
| `19a9ae83` | 2026-09-20 | fix(plan-agent): lead the goal prompt with `/goal` (9.18.1) (#637) |
| `77aa33e8` | 2026-09-12 | fix(plan-agent): lead the goal prompt with "Goal:" (9.17.2) (#631) |
| `f3be0249` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract — lanes in the renderer, authoring, and build (9.14.0–9.17.0) (#628) |
| `43a7fd92` | 2026-09-01 | feat(plan-agent): take review-plan off the experimental Agent Teams flag (#614) |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [add-plan-guidelines-library.md](plans/add-plan-guidelines-library.md)
- Related: `docs/proposals/plan-generation-from-markdown-guidelines.md`
