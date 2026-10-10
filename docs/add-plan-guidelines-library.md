# Ship the guidelines library and markdown-first authoring for implementation-plan

> Replaces the prescriptive HTML-skeleton rulebook with a four-document guidelines library and rewrites `implementation-plan` SKILL.md so the agent authors a Markdown spec rendered by the bundled `build-plan-html.mjs` script.

<!-- generated:start -->

**Status:** Shipped 2026-08-15 **Plan:** [add-plan-guidelines-library.md](plans/add-plan-guidelines-library.md)
**Type:** feature

## What shipped

- Created four guideline documents under `kit/plugins/plan-agent/skills/implementation-plan/guidelines/`: `planning-principles.md` (falsifiable done criteria, what/why/verify discipline, scope), `section-catalog.md` (section menu with purpose, triggers, and exact spec syntax), `right-sizing.md` (minimal/standard/deep depth profiles and calibration table), and `writing-style.md` (tone and plain-language rules).
- Rewrote `implementation-plan` SKILL.md around the markdown-spec pipeline: explore, load guidelines, author a Markdown spec, render via `build-plan-html.mjs`, deliver. All nine workflow Steps 0–8 remain intact — only the authoring medium changed.
- Rewrote `reference/SKELETON.md` as the copyable spec starter in the exact format `parseSpecMarkdown()` accepts, replacing the old humanized-headings skeleton whose headings the renderer rejects.
- Updated `tests/plugins/test-goal-prompt.sh` to assert the derived goal-prompt contract against SKILL.md rather than grepping for the `{goal-prompt}` placeholder the renderer now owns.
- Updated `tests/plugins/test-resources-section.sh` to repoint its Resources guidance assertion to the guidelines and spec skeleton.
- Bumped `plan-agent` to `2.19.0` in `marketplace.json` with a CHANGELOG entry, updated `README.md` structure tree and component section, and updated the marketplace description.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/planning-principles.md` | Guidelines — falsifiable done, what/why/verify, scope | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Guidelines — section menu with spec syntax | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/right-sizing.md` | Guidelines — depth profiles and calibration table | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/writing-style.md` | Guidelines — tone and plain-language rules | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill contract — markdown-spec pipeline | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Spec starter — parser-compatible headings and markers | Modified |
| `tests/plugins/test-goal-prompt.sh` | Smoke test — repointed goal-prompt assertion | Modified |
| `tests/plugins/test-resources-section.sh` | Smoke test — repointed Resources assertion | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin documentation — pipeline and structure tree | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release notes — 2.19.0 entry | Modified |
| `.claude-plugin/marketplace.json` | Marketplace version bump to 2.19.0 | Modified |

## How it works

**Phase 2 context.** Phase 1 (plan-agent 2.18.0) shipped `build-plan-html.mjs`, a deterministic renderer that parses a small Markdown plan spec and emits the full styled HTML plan. Phase 1 left the skill still instructing the agent to copy a 2,015-line HTML skeleton and fill placeholders — roughly 60k tokens of pure mechanics per plan run. Phase 2 inverts the authoring flow: guidelines carry the judgment, the spec carries the content, the renderer carries the presentation.

**Guidelines library.** The four documents are loaded via progressive disclosure as the agent needs them. `planning-principles.md` establishes the epistemological contract: every step must state a falsifiable done criterion, and every step body follows the what/why/verify structure. `section-catalog.md` is the section menu — each entry names the section, its purpose, when to include it, and the exact Markdown syntax `parseSpecMarkdown()` accepts. `right-sizing.md` gives three depth profiles (minimal, standard, deep) with a calibration table so the agent can select the right profile for the plan's scope. `writing-style.md` carries tone and plain-language rules previously buried in a workflow document.

**SKILL.md rewrite.** The new SKILL.md follows a five-stage pipeline: explore the codebase, read the relevant guidelines, author a Markdown spec (using SKELETON.md as the starter), render the spec with `node kit/plugins/plan-agent/scripts/build-plan-html.mjs <spec-path>`, and deliver the HTML plan. The skill body contains no placeholder-filling or skeleton-copying instructions. Steps 0–8 (issue ingestion, clarify, align, interview, tests, status gates, delivery, next-action menu) are unchanged — they orchestrate content, not authoring mechanics.

**SKELETON.md.** The old `SKELETON.md` used humanized headings (`## Steps`, `### Step 1`) that `parseSpecMarkdown()` does not recognize — copying it would produce an unparseable spec. The new skeleton uses the exact heading and step-marker syntax the parser accepts, making "copy the skeleton and fill in the blanks" a reliable starting point rather than a trap.

**Test updates.** `test-goal-prompt.sh` previously grepped SKILL.md for `{goal-prompt}` — a placeholder the renderer now resolves, not the skill. The test was updated to assert the derived goal-prompt contract instead (that SKILL.md documents how goal-prompt is computed and emitted). `test-resources-section.sh` similarly had its assertion repointed from the old skeleton's Resources section to the guidelines library and new SKELETON.md.

## How to use it

The pipeline change is transparent at invocation — `/plan-agent:implementation-plan` still activates the skill. The difference is visible in what the skill produces: a small Markdown spec alongside the rendered HTML, which can be version-controlled and re-rendered independently.

```
# Author a plan (now produces both .md spec and .html render)
/plan-agent:implementation-plan add a caching layer to the API

# Re-render an existing spec after manual edits
node kit/plugins/plan-agent/scripts/build-plan-html.mjs docs/plans/my-feature.md
```

The guidelines are loaded by the agent from `skills/implementation-plan/guidelines/` and are available for reference when authoring plans manually.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d7598ad` | 2026-08-17 | fix: screenshot output verification and plan Context completeness (#571) |
| `e1e8840` | 2026-08-15 | feat(git-agent): add post-merge-cleanup skill (4.19.0) (#565) |

<!-- generated:end -->

## References

- Plan: [add-plan-guidelines-library.md](plans/add-plan-guidelines-library.md)
