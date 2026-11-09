# Make plan status and checkbox flows Markdown-first

> Status flips and checkbox ticks are now one-line Markdown edits in the spec; the renderer derives all progress representations mechanically, retiring the frozen-string HTML surgery that finalize-plan depended on.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [make-plan-status-flows-md-first.md](plans/make-plan-status-flows-md-first.md)
**Type:** refactor

## What shipped

- Extended `parseSpecMarkdown` in `scripts/lib/plan-spec.mjs` to read `- [x]` criteria bullets, `[x]` step markers, and `## Completion Report` entries into a separate `progress` return key (outside `sections`, so the extract→digest→parse round trip stays byte-stable).
- Updated `plan-shell.mjs` and `build-plan-html.mjs` to render progress state — checked inputs, completed step cards, initial progress bar, derived `cc1`–`cc3`, `all-complete`, and the report list — from the spec.
- Synced all three bundled renderer copies under `kit/plugins/plan-agent/scripts/` to be byte-identical to the repo-root sources.
- Rewrote `finalize-plan/SKILL.md` to edit the Markdown spec and re-render (spec mode) when a sibling spec exists, with a legacy HTML fallback for plans without one — retiring the byte-for-byte find/replace contract.
- Updated `implementation-plan/SKILL.md` Steps 6 and 8 gates to flip checkbox state in the spec and re-render, eliminating HTML attribute-editing instructions.
- Replaced byte-for-byte frozen-string tests with behavioural progress assertions; bumped plan-agent to 2.20.0 with README and CHANGELOG updates.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/lib/plan-spec.mjs` | Spec parser — progress key added | Modified |
| `scripts/lib/plan-shell.mjs` | Renderer — progress-aware markup | Modified |
| `scripts/build-plan-html.mjs` | Build script — wires progress through rendering | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-spec.mjs` | Bundled copy (byte-identical) | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Bundled copy (byte-identical) | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Bundled copy (byte-identical) | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Spec-mode finalization with legacy HTML fallback | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Steps 6 and 8 gates — spec edits only | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Checkbox syntax and Completion Report section docs | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Criteria start as unchecked checkbox bullets | Modified |
| `kit/plugins/plan-agent/README.md` | Md-first finalize-plan and pipeline docs | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 2.20.0 entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 2.19.0 → 2.20.0 | Modified |
| `tests/plugins/test-build-plan-html.mjs` | Progress-state tests replace frozen-string pins | Modified |
| `tests/plugins/test-finalize-all-flag.sh` | Pins md/html argument hint and spec-mode contract | Modified |

## How it works

Before this change, completion state lived only in the rendered HTML: `finalize-plan` did literal find/replace on a `todo` step chip and a report-empty sentence — three frozen strings pinned byte-for-byte. Re-rendering a spec reset all progress, and every status edit was an attribute-surgery exercise. This was Phase 3 of the plan-generation-from-markdown proposal; Phases 1–2 had made the Markdown spec the authored source of truth and shipped the deterministic renderer, but progress state still escaped into the HTML only.

`parseSpecMarkdown` in `plan-spec.mjs` now returns a `progress` key alongside `sections`. It reads `- [x]` and `- [ ]` criteria bullets, `[x]` step markers, and `## Completion Report` entries, without touching the content sections the round-trip comparison uses. The parser keeps `progress` separate from `sections` so extract→digest→parse remains byte-stable across the corpus.

`plan-shell.mjs` and `build-plan-html.mjs` use `progress` to derive every completion representation that `finalize-plan` previously wrote by hand: checked/unchecked checkbox inputs, completed step cards (`class="step-card completed"`), the initial progress bar fill, the `cc1`–`cc3` completion-checklist state, `all-complete`, and the report list. Re-rendering a spec with checkbox state now produces a fully accurate HTML view without any direct HTML editing.

`finalize-plan/SKILL.md` was rewritten around spec mode: it edits frontmatter status, flips checkbox bullets, adds step markers and the Completion Report, then explicitly re-renders to produce the HTML. A legacy HTML fallback remains for plans that predate the markdown-first architecture and have no sibling `.md` spec. `implementation-plan/SKILL.md` Steps 6 and 8 were updated to the same pattern, removing all instructions to edit HTML `checked` attributes or step-card classes.

## How to use it

Finalization is invoked via `/plan-agent:finalize-plan`. When a sibling `.md` spec exists, the skill now:
1. Sets `status: completed` in the frontmatter.
2. Flips unchecked `- [ ]` criteria to `- [x]`.
3. Marks each step with `[x]`.
4. Adds a `## Completion Report` section.
5. Re-renders the HTML via `build-plan-html.mjs`.

The rendered HTML reflects all progress without any direct HTML editing.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `43d18eec` | 2026-10-31 | fix(plan-agent,social-media-tools): remove model pins from skills (9.22.0, 2.25.0) (#668) |
| `02136c1d` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `1c315692` | 2026-10-14 | fix: stop goal loops on blocked checks (plan-agent 9.19.2) (#652) |
| `c16fe83f` | 2026-10-13 | feat(plan-agent): live UI previews inside plan pages (9.20.0) (#651) |
| `19a9ae83` | 2026-09-20 | fix(plan-agent): lead the goal prompt with `/goal` (9.18.1) (#637) |
| `77aa33e8` | 2026-09-12 | fix(plan-agent): lead the goal prompt with "Goal:" (9.17.2) (#631) |
| `f3be0249` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract — lanes in the renderer, authoring, and build (9.14.0–9.17.0) (#628) |
| `b8cfa1fd` | 2026-09-04 | fix(plan-agent): style header links as chips and refocus a leading select after submit (9.13.1) (#623) |
| `d2e9f101` | 2026-09-02 | feat: polish the plan-document HTML output (#617) |
| `3263bbc9` | 2026-08-30 | feat(plan-agent): reconcile a plan against what actually shipped (9.11.0) (#613) |
| `22e22800` | 2026-08-30 | fix(plan-agent): unbreak the build completion gate for artifact-only plans (9.10.1) (#610) |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [make-plan-status-flows-md-first.md](plans/make-plan-status-flows-md-first.md)
