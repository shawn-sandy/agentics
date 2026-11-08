# Make plan status and checkbox flows Markdown-first

> Point finalize-plan and implementation-plan status/checkbox gates at the Markdown spec — checkbox flips plus frontmatter edits plus a re-render — retiring the byte-for-byte frozen-string contracts that HTML surgery depended on.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [make-plan-status-flows-md-first.md](plans/make-plan-status-flows-md-first.md)
**Type:** refactor

## What shipped

- Extended `parseSpecMarkdown` in `scripts/lib/plan-spec.mjs` to read `- [x]` criteria bullets, `[x]` step markers, and `## Completion Report` sections into a separate progress return key without disturbing content sections.
- Taught `scripts/lib/plan-shell.mjs` and `scripts/build-plan-html.mjs` to render progress state: checked inputs, completed step cards, initial progress bar, derived `cc1`–`cc3`, `all-complete`, and report list all derived from the spec.
- Synced both modified files to byte-identical copies under `kit/plugins/plan-agent/scripts/`.
- Rewrote `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` around spec-mode: frontmatter status flips, checkbox edits, step markers, Completion Report section, explicit re-render; legacy HTML fallback kept for plans without a spec.
- Updated `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` Steps 6 and 8 to flip state in the spec and re-render; documented syntax in `section-catalog.md` and `SKELETON.md`.
- Replaced frozen-string test assertions with behavioral progress assertions; bumped plan-agent to `2.20.0`.

> See [CHANGELOG v2.20.0](../kit/plugins/plan-agent/CHANGELOG.md) for the authoritative feature list.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/lib/plan-spec.mjs` | Plan spec parser — progress key added | Modified |
| `scripts/lib/plan-shell.mjs` | Renderer — progress-aware blocks, frozen strings demoted | Modified |
| `scripts/build-plan-html.mjs` | Build script — progress wired through rendering | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-spec.mjs` | Byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Spec-mode finalize workflow | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Steps 6/8 spec-mode gates | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Checkbox syntax docs | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Criteria start as unchecked checkbox bullets | Modified |

## How it works

Phases 1–2 of the plan-generation-from-markdown proposal made the Markdown spec the authored source of truth and shipped the deterministic renderer — but progress state still lived in the HTML only. `finalize-plan` did literal find/replace on the `todo` step chip and the report-empty sentence, keeping three frozen strings pinned byte-for-byte. Re-rendering a spec reset all progress, making every status edit an attribute-surgery exercise.

The fix carries completion state in the spec's checkbox syntax (`- [x]`/`- [ ]` criteria bullets, `[x]`/`[ ]` step markers, `## Completion Report` section). `parseSpecMarkdown` returns these as a separate `progress` key so they travel with the spec without changing the content sections the round-trip comparison checks.

`plan-shell.mjs` and `build-plan-html.mjs` were updated to consume the `progress` key and emit every completion representation mechanically: checked/unchecked inputs, done step chips, progress bar percentage, derived `cc1`–`cc3` (completion criteria checkboxes), `all-complete` state, and the report list. Re-rendering a spec is now lossless — the renderer re-derives the same HTML from the same checkbox state.

`finalize-plan/SKILL.md` was rewritten around this new path: when a sibling spec exists, the skill edits the Markdown and calls `node scripts/build-plan-html.mjs` to re-render; for legacy plans without a spec it still falls back to direct HTML edits.

The frozen-string test at `tests/plugins/test-build-plan-html.mjs` was replaced with behavioral progress assertions that verify the actual completion representations rather than pinning exact bytes.

## How to use it

The change is transparent to users. Existing `/plan-agent:finalize-plan` invocations automatically use spec mode when the plan has a `.md` sibling spec.

To mark a criterion complete, edit the spec: change `- [ ]` to `- [x]` on the relevant criterion bullet, then re-render via `node scripts/build-plan-html.mjs <plan.md>`. The rendered HTML updates all derived completion representations automatically.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |
| `22e2280` | 2026-08-30 | fix(plan-agent): unbreak the build completion gate for artifact-only plans (9.10.1) (#610) |
| `3263bbc` | 2026-08-30 | feat(plan-agent): reconcile a plan against what actually shipped (9.11.0) (#613) |
| `d2e9f10` | 2026-09-02 | feat: polish the plan-document HTML output (#617) |
| `b8cfa1f` | 2026-09-04 | fix(plan-agent): style header links as chips and refocus a leading select after submit (9.13.1) (#623) |
| `f3be024` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract — lanes in the renderer, authoring, and build (9.14.0–9.17.0) (#628) |
| `c16fe83` | 2026-10-13 | feat(plan-agent): live UI previews inside plan pages (9.20.0) (#651) |
| `1c31569` | 2026-10-14 | fix: stop goal loops on blocked checks (plan-agent 9.19.2) (#652) |
| `02136c1` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `43d18ee` | 2026-10-31 | fix(plan-agent,social-media-tools): remove model pins from skills (9.22.0, 2.25.0) (#668) |

<!-- generated:end -->

## References

- Plan: [make-plan-status-flows-md-first.md](plans/make-plan-status-flows-md-first.md)
