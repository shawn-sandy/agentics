# Make plan status and checkbox flows Markdown-first

> Points finalize-plan and implementation-plan status/checkbox gates at the Markdown spec and a deterministic renderer, retiring the byte-for-byte frozen-string HTML surgery contracts.

<!-- generated:start -->

**Status:** Shipped 2026-07-12  **Plan:** [make-plan-status-flows-md-first.md](plans/make-plan-status-flows-md-first.md)
**Type:** refactor

## What shipped

- Extended `scripts/lib/plan-spec.mjs` — parses `- [x]` criteria bullets, `[x]` step markers, and a `## Completion Report` section into a `progress` return key alongside the existing content sections.
- Extended `scripts/lib/plan-shell.mjs` and `scripts/build-plan-html.mjs` — renderer derives checked inputs, completed step cards, initial progress bar, `cc1`–`cc3` completion checklist entries, `all-complete` flag, and the report list from the spec's `progress` key; frozen string constants removed.
- Synced the bundled renderer copies under `kit/plugins/plan-agent/scripts/` byte-identical to the repo-root sources.
- Rewrote `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` — spec-mode path edits the Markdown spec and re-renders; legacy HTML fallback retained for plans without a sibling spec.
- Updated `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` Steps 6 and 8 — checkbox state is flipped in the spec and re-rendered; no HTML attribute-editing instructions remain.
- Updated `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` and `reference/SKELETON.md` — checkbox syntax and Completion Report section documented; criteria start as unchecked checkbox bullets.
- Updated `tests/plugins/test-build-plan-html.mjs` — behavioral progress assertions replace the byte-for-byte frozen-string pin.
- Updated `tests/plugins/test-finalize-all-flag.sh` — pins the md/html argument hint and the spec-mode contract.
- Updated `kit/plugins/plan-agent/README.md` and `CHANGELOG.md`; bumped to `2.20.0` in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `scripts/lib/plan-spec.mjs` | Plan spec parser | Modified |
| `scripts/lib/plan-shell.mjs` | Renderer shell | Modified |
| `scripts/build-plan-html.mjs` | HTML renderer | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Bundled renderer | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-spec.mjs` | Bundled spec parser | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Bundled renderer shell | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Section catalog | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Plan skeleton | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin documentation | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release notes | Modified |
| `.claude-plugin/marketplace.json` | Marketplace version | Modified |
| `tests/plugins/test-build-plan-html.mjs` | Renderer test | Modified |
| `tests/plugins/test-finalize-all-flag.sh` | Finalize test | Modified |

## How it works

Before this change, progress state lived only in the HTML: `finalize-plan` did literal find-and-replace on the `todo` step chip and the report-empty sentence, and re-rendering a spec reset all progress. This kept three frozen strings pinned byte-for-byte and made every status edit an attribute-surgery exercise that could drift silently.

The fix introduces a `progress` key in `parseSpecMarkdown`. The renderer reads checkbox state (`- [x]` criteria bullets, `[x]` step markers) and the `## Completion Report` section from the Markdown spec and derives all downstream representations — checked checkbox inputs, completed step cards, the progress bar, `cc1`–`cc3` checklist entries — mechanically. Re-rendering is now lossless: progress stored in the Markdown survives every renderer invocation.

`finalize-plan` still has a legacy HTML path for plans that predate the Markdown spec format, but spec-mode plans use the Markdown-first flow: flip the checkbox, re-render, done. `implementation-plan` Steps 6 and 8 were updated to the same contract, removing the last instructions to write HTML attributes by hand.

The bundled copies under `kit/plugins/plan-agent/scripts/` are maintained byte-identical to the repo-root sources by a parity test; a single renderer fix now lands in both without a separate sync step.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `67ab9a1` | 2026-08-19 | docs: sync README plugin table with memory-tools 4.3.0 (#588) |

<!-- generated:end -->

## References

- Plan: [make-plan-status-flows-md-first.md](plans/make-plan-status-flows-md-first.md)
