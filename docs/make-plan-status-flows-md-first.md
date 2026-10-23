# Make plan status and checkbox flows Markdown-first

> Completion state moved from frozen byte-for-byte HTML strings into the Markdown spec's checkbox syntax, making every status flip a one-line edit and re-renders lossless.

<!-- generated:start -->

**Status:** Shipped 2026-08-03 **Plan:** [make-plan-status-flows-md-first.md](plans/make-plan-status-flows-md-first.md)
**Type:** refactor

## What shipped

- Extended `parseSpecMarkdown` in `scripts/lib/plan-spec.mjs` to read `- [x]` criteria bullets, `[x]` step markers, and a `## Completion Report` section into a separate `progress` return key, leaving content sections byte-stable across round-trips.
- Taught `plan-shell.mjs` and `build-plan-html.mjs` to derive every completion representation from the `progress` key: checked inputs, completed step cards, initial progress bar, `cc1`–`cc3` state, `all-complete` flag, and the report list — so finalize-plan no longer needs to touch the HTML.
- Synced the three bundled copies under `kit/plugins/plan-agent/scripts/` to be byte-identical to the repo-root sources, passing the existing parity test.
- Rewrote `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` around spec-mode editing: frontmatter `status`, `- [x]` criteria flips, `[x]` step markers, `## Completion Report`, and an explicit re-render step; legacy HTML fallback retained for plans without a sibling spec.
- Updated `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` Step 6 and Step 8 gates to flip state in the spec and re-render, removing all HTML attribute-editing instructions.
- Documented checkbox syntax and the `## Completion Report` section in `section-catalog.md` and `SKELETON.md`.
- Replaced frozen-string test assertions in `tests/plugins/test-build-plan-html.mjs` with behavioural progress assertions; pinned the spec-mode contract in `tests/plugins/test-finalize-all-flag.sh`.
- Bumped plan-agent to 2.20.0 with a CHANGELOG entry; updated `README.md` to document the md-first finalize-plan flow.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/lib/plan-spec.mjs` | Plan spec parser — progress key | Modified |
| `scripts/lib/plan-shell.mjs` | HTML shell builder — progress-aware rendering | Modified |
| `scripts/build-plan-html.mjs` | CLI renderer — wires progress through build | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Bundled renderer copy (byte-identical) | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-spec.mjs` | Bundled parser copy (byte-identical) | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Bundled shell copy (byte-identical) | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Skill instructions — spec-mode write flow | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill instructions — Step 6/8 gates | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Section authoring guide — checkbox syntax | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Plan skeleton template — unchecked criteria bullets | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin documentation — md-first pipeline | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Version history — 2.20.0 entry | Modified |
| `.claude-plugin/marketplace.json` | Marketplace manifest — plan-agent 2.19.0 → 2.20.0 | Modified |
| `tests/plugins/test-build-plan-html.mjs` | Progress-state test coverage | Modified |
| `tests/plugins/test-finalize-all-flag.sh` | finalize-plan spec-mode contract pin | Modified |

## How it works

Phases 1 and 2 of the plan-generation-from-markdown project made the `.md` spec the authored source of truth and shipped a deterministic renderer, but completion state still lived in the HTML: `finalize-plan` used literal find-and-replace on three frozen byte-for-byte strings (`todo` step chip, report-empty sentence, and the HTML `checked` attributes). Re-rendering a spec would overwrite all progress. This phase carries state in the spec's checkbox syntax instead, making re-rendering lossless.

The first change was in `scripts/lib/plan-spec.mjs`. The `parseSpecMarkdown` function was extended to scan the spec for `- [x]` and `- [ ]` criteria bullets, `[x]` step markers inside step bodies, and a `## Completion Report` section. These are returned as a `progress` key alongside the existing `sections` key. Critically, the `progress` key sits outside `sections`, so the extract-digest-parse round-trip that compares content sections byte-for-byte is unaffected.

`scripts/lib/plan-shell.mjs` and `scripts/build-plan-html.mjs` were then updated to accept and apply the `progress` key when rendering. The renderer now emits checked or unchecked `<input>` elements for criteria, a "done" chip and coloured border on completed step cards, an initial progress bar percentage, the derived `cc1`–`cc3` completion-checklist state, the `all-complete` flag, and the report list — all mechanically from the spec. No tool needs to write these attributes by hand.

`finalize-plan`'s `SKILL.md` was rewritten around this new path. When a sibling `.md` spec exists, Step 5 now edits only the spec: it sets `status: completed` in the frontmatter, flips unchecked criteria to `- [x]`, adds `[x]` to step markers, appends a `## Completion Report` section, and calls `build-plan-html.mjs` to re-render. The HTML ends up checked and marked complete as a side-effect of the render, with no frozen-string surgery. The legacy HTML-edit path is preserved for plans that pre-date the markdown-first renderer and have no sibling spec.

`implementation-plan`'s Step 6 (mid-plan progress) and Step 8 (completion) gates were updated to the same pattern: flip state in the spec and re-render, never hand-edit the HTML. `section-catalog.md` documents the checkbox bullet syntax and the `## Completion Report` heading, and `SKELETON.md` ships criteria as unchecked `- [ ]` bullets so new plans start in the right format.

The bundled copies under `kit/plugins/plan-agent/scripts/` were synced byte-for-byte to the repo-root sources. The existing parity test (`test-build-plan-html.mjs`) enforces this. The three frozen-string assertions in the test suite were replaced with behavioural checks: mixed `[x]`/`[ ]` criteria, step markers, `## Completion Report` entries, and malformed report bullets. `test-finalize-all-flag.sh` gained a spec-mode section that pins the `md/html` argument hint and the spec-mode write contract.

One intentional deviation was noted in the plan's Completion Report: legacy plans without a sibling spec continue to be finalized via direct HTML edits. A planned Phase 4 backfill would retire that path, but it was explicitly out of scope here.

## How to use it

Finalize-plan is triggered via the plan-agent command:

```
/plan-agent:finalize-plan docs/plans/my-feature.md    # spec-mode: edits .md and re-renders
/plan-agent:finalize-plan docs/plans/legacy.html      # legacy-mode: direct HTML edits
/plan-agent:finalize-plan --all                        # sweep all unmarked plans
/plan-agent:finalize-plan --all --dir docs/plans/     # sweep a specific directory
```

When the plan has a sibling `.md` spec, all edits land in the spec and the HTML is regenerated automatically. When only the HTML exists (pre-2.18 plan), the legacy find-and-replace path is used.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `0fd7b67` | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |
| `620ffa8` | 2026-08-19 | docs: sync READMEs with marketplace; fix the dead version-guard hook (#581) |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |
| `d7598ad` | 2026-08-17 | fix: screenshot output verification and plan Context completeness (#571) |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |
| `2fd715f` | 2026-08-17 | fix: redefine done as artifact + verification in five high-impact skills (#568) |
| `dbf3844` | 2026-08-14 | fix(plan-agent): add plan-mode guard to plan-status (#562) |
| `c4860d1` | 2026-08-14 | feat: add --check mode to plan renderer for verifying HTML consistency (#556) |
| `9871dd9` | 2026-08-14 | Add build-fleet: ship a plan backlog in parallel, one worktree agent per plan (#554) |
| `73cb6df` | 2026-08-12 | Add build-feature skill: feature docs that split into plans (#547) |
| `c071dac` | 2026-08-10 | fix(git-agent): make the commit lint gate trustworthy in every repo (4.14.0) (#544) |
| `218bb28` | 2026-08-09 | feat(plan-agent): retune the plan document design (9.1.0) (#537) |
| `e39e346` | 2026-08-07 | feat(plan-agent)!: explicit argument precedence for build (9.0.0) (#533) |
| `1b4f657` | 2026-08-06 | feat(plan-agent): red-green-verify plans (8.7.0) (#529) |
| `7ded3be` | 2026-08-05 | feat(plan-agent): phase checkpoints and a Decisions ledger for plan specs (8.6.0) (#528) |
| `4a01a79` | 2026-08-03 | fix: replace eight unrunnable ${CLAUDE_PLUGIN_ROOT} Bash commands with bin/ wrappers (#520) |

<!-- generated:end -->

## References

- Plan: [make-plan-status-flows-md-first.md](plans/make-plan-status-flows-md-first.md)
- Related docs: [`kit/plugins/plan-agent/CHANGELOG.md`](../kit/plugins/plan-agent/CHANGELOG.md)
