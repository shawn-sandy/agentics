# Ship the guidelines library and markdown-first authoring for implementation-plan

> Replaces the implementation-plan skill's prescriptive HTML rulebook with a four-document guidelines library; the agent now authors a Markdown spec rendered by `build-plan-html.mjs` instead of filling a 2,015-line HTML skeleton by hand.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [add-plan-guidelines-library.md](plans/add-plan-guidelines-library.md)
**Type:** feature

## What shipped

- Created four guideline documents under `skills/implementation-plan/guidelines/`: `planning-principles.md` (falsifiable done, what/why/verify, scope discipline), `section-catalog.md` (section menu with purpose, triggers, and exact spec syntax), `right-sizing.md` (minimal/standard/deep depth profiles), and `writing-style.md` (tone and plain-language rules).
- Rewrote `skills/implementation-plan/SKILL.md` around the markdown-spec pipeline: explore, read guidelines, author spec, render via `build-plan-html.mjs`, deliver. No placeholder-filling or skeleton-copying instructions remain.
- Rewrote `reference/SKELETON.md` as the copyable spec starter in the parser's exact format, replacing the old humanized-headings skeleton whose headings the renderer rejected.
- Updated `tests/plugins/test-goal-prompt.sh` and `tests/plugins/test-resources-section.sh` to drop assertions against retired placeholder prose; bumped plan-agent to 2.19.0.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/planning-principles.md` | Guidelines — scope and verification discipline | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Guidelines — section menu with spec syntax | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/right-sizing.md` | Guidelines — depth profiles | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/writing-style.md` | Guidelines — tone and plain-language rules | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill instructions — markdown-first pipeline | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Copyable spec starter | Modified |
| `tests/plugins/test-goal-prompt.sh` | Smoke test | Modified |
| `tests/plugins/test-resources-section.sh` | Smoke test | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin documentation | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Changelog | Modified |
| `.claude-plugin/marketplace.json` | Marketplace version (plan-agent 2.19.0) | Modified |

## How it works

Before Phase 2, `implementation-plan` instructed the agent to copy a 2,015-line HTML skeleton and fill placeholders by hand — roughly 60k tokens of pure mechanics per plan run. `build-plan-html.mjs` (Phase 1, plan-agent 2.18.0) had already shipped the deterministic renderer; Phase 2 inverts the authoring flow so the guidelines carry the judgment, the spec carries the content, and the renderer carries the presentation.

The four guideline documents are loaded progressively: `planning-principles.md` establishes scope and verification discipline, `section-catalog.md` provides the exact markdown syntax `parseSpecMarkdown()` accepts, `right-sizing.md` calibrates plan depth, and `writing-style.md` governs tone. The agent reads whichever guidelines are relevant for the current plan, rather than loading all 85 KB of the former HTML rulebook.

`SKILL.md` now follows a five-step pipeline: (1) explore the codebase, (2) read the relevant guidelines, (3) author a markdown spec (using `reference/SKELETON.md` as the copyable starter), (4) render with `node scripts/build-plan-html.mjs <spec>.md`, (5) deliver. The Step 8 next-action menu and all workflow contracts from the old SKILL.md are preserved unchanged.

`reference/SKELETON.md` was rewritten to use headings and step markers that match `section-catalog.md` exactly. The old skeleton used humanized headings (`## Implementation Steps`) that `parseSpecMarkdown` rejected, so copying it always produced an unparseable spec.

## How to use it

The skill is activated by description (auto-loaded when a user asks to plan or implement a feature). The command wrapper is `/plan-agent:implementation-plan`.

```
/plan-agent:implementation-plan                     # auto-detects context
/plan-agent:implementation-plan add dark mode       # explicit objective
/plan-agent:implementation-plan #123                # from a GitHub issue
```

The agent loads the guidelines library internally. Users do not interact with the guidelines files directly.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `43d18ee` | 2026-10-31 | fix(plan-agent,social-media-tools): remove model pins from skills (9.22.0, 2.25.0) (#668) |
| `02136c1` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `1c31569` | 2026-10-14 | fix: stop goal loops on blocked checks (plan-agent 9.19.2) (#652) |
| `c16fe83` | 2026-10-13 | feat(plan-agent): live UI previews inside plan pages (9.20.0) (#651) |
| `417a957` | 2026-09-26 | feat(plan-agent): offer prototype and design canvas together in Step 8 (9.19.0) (#640) |
| `19a9ae8` | 2026-09-20 | fix(plan-agent): lead the goal prompt with `/goal` (9.18.1) (#637) |
| `77aa33e` | 2026-09-12 | fix(plan-agent): lead the goal prompt with "Goal:" (9.17.2) (#631) |
| `f3be024` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract — lanes in the renderer, authoring, and build (9.14.0–9.17.0) (#628) |
| `43a7fd9` | 2026-09-01 | feat(plan-agent): take review-plan off the experimental Agent Teams flag (#614) |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [add-plan-guidelines-library.md](plans/add-plan-guidelines-library.md)
- Changelog: `kit/plugins/plan-agent/CHANGELOG.md` — v2.19.0 entry
- Related: `docs/proposals/plan-generation-from-markdown-guidelines.md`
