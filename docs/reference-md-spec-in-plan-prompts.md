# Reference the markdown spec in plan prompts and render Next Steps again

> Derived plan prompts now point at the ~5 KB markdown spec instead of the ~60 KB rendered HTML, the copy-button flow instructs markdown-first edits, and the Next Steps section renders as collapsible cards with paste-ready prompts; shipped as plan-agent 2.21.0.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [reference-md-spec-in-plan-prompts.md](plans/reference-md-spec-in-plan-prompts.md)
**Type:** feature

## What shipped

- Extended `parseSpecMarkdown` in `scripts/lib/plan-spec.mjs` to parse `## Next Steps` into a `nextSteps` key beside `sections` (bullets → summary/desc/prompt items), keeping the extract→digest→parse round trip byte-stable.
- Added `nextStepsBlock()` to `plan-shell.mjs` to render Next Steps as collapsible `<details>` cards with `<pre>` prompts and Copy-prompt buttons, plus a filtered sidebar nav entry.
- Added a `mdPath` render option to `build-plan-html.mjs`; the CLI passes the real spec path; all three derived prompts (`plan-implement`, `plan-goal`, `plan-workflow`) now reference the `.md` spec path instead of `.html`.
- Added a `plan-md` meta tag and a Spec drawer row so the spec path is discoverable in the rendered HTML.
- Rewrote the copy-button `buildImplementPrompt()` to instruct a markdown-first loop: read the spec → insert `[x]` step markers → flip criteria to `- [x]` → set `status: completed` → re-render the sibling HTML — never hand-edit it.
- Mirrored all shell changes into `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html` and documented the new behaviour in `SKELETON.md`, `section-catalog.md`, and `SKILL.md`.
- Synced byte-identical bundled copies under `kit/plugins/plan-agent/scripts/`; updated pinned test assertions; bumped plan-agent to 2.21.0.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/build-plan-html.mjs` | Build script — spec path prompts, plan-md meta, Next Steps card and nav filter, CLI spec path | Modified |
| `scripts/lib/plan-spec.mjs` | Spec parser — Next Steps key beside sections | Modified |
| `scripts/lib/plan-shell.mjs` | Renderer — Next Steps chrome, nav entry, plan-md meta, Spec drawer row, markdown-first copy-button JS | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Bundled copy (byte-identical) | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-spec.mjs` | Bundled copy (byte-identical) | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Bundled copy (byte-identical) | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html` | plan-md meta, Spec row, markdown-first copy-button JS | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Next Steps bullet/fence syntax | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Next Steps catalog entry | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Spec-path prompts, plan-md meta, Next Steps documented | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 2.21.0 entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 2.20.0 → 2.21.0 | Modified |
| `tests/plugins/test-build-plan-html.mjs` | Spec-path prompt pins, plan-md meta, Next Steps parse/render coverage | Modified |
| `tests/plugins/test-extractor-wiring.sh` | Pins the new self-contained copy-button JS | Modified |

## How it works

Since the markdown-first rewrite (plan-agent 2.18–2.20), the `.md` spec is the source of truth for all progress state. But the three derived prompts (`plan-implement`, `plan-goal`, `plan-workflow`) still pointed at the `.html` file — 10–20× the spec's size, mostly CSS/JS/SVG chrome. The `plan-workflow` prompt multiplied this waste by briefing every subagent with the HTML. The copy-button prompt told agents to "mark it done in the plan" and referred to a "self-contained HTML file", actively inviting the `checked`-attribute HTML edits the architecture bans.

`parseSpecMarkdown` now returns `nextSteps` as a parallel key to `sections`. It parses `## Next Steps` bullets into `{summary, desc, prompt}` items (or falls back to prose), without disturbing the content sections object the round-trip comparison uses. A spec without a Next Steps section returns an empty `nextSteps` array; the renderer emits neither the card nor the nav entry in that case.

The rendered plan now exposes the spec path in three ways: as `<meta name="plan-md" content="path/to/plan.md">`, as a "Spec" row in the More-ways drawer beside File and Path rows, and in the `plan-implement`/`plan-goal`/`plan-workflow` meta tag contents (which previously ended in `.html`). The CLI was updated to pass the real spec path to the renderer; a `.html` → `.md` fallback handles cases where only the HTML was provided.

The copy-button `buildImplementPrompt()` was rewritten to instruct a five-step markdown-first loop: (1) read the spec, (2) insert `[x]` step markers, (3) flip `- [ ]` criteria to `- [x]`, (4) set `status: completed` in frontmatter, (5) re-render the sibling HTML. This ensures the HTML plan ends up checked and marked complete — the same outcome as before — without any direct HTML attribute editing.

## How to use it

The changes are active in every rendered plan. When an implementing agent opens the plan page and copies the Implement prompt, they receive the markdown-first instructions pointing at the spec path. The Next Steps section renders automatically when a spec includes it.

The new drawer rows are visible in the plan's "More ways to use this plan" section. The `plan-md` meta is machine-readable for tools that need the spec path.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `02136c1d` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `1c315692` | 2026-10-14 | fix: stop goal loops on blocked checks (plan-agent 9.19.2) (#652) |
| `c16fe83f` | 2026-10-13 | feat(plan-agent): live UI previews inside plan pages (9.20.0) (#651) |
| `19a9ae83` | 2026-09-20 | fix(plan-agent): lead the goal prompt with `/goal` (9.18.1) (#637) |
| `77aa33e8` | 2026-09-12 | fix(plan-agent): lead the goal prompt with "Goal:" (9.17.2) (#631) |
| `f3be0249` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract — lanes in the renderer, authoring, and build (9.14.0–9.17.0) (#628) |
| `b8cfa1fd` | 2026-09-04 | fix(plan-agent): style header links as chips and refocus a leading select after submit (9.13.1) (#623) |
| `d2e9f101` | 2026-09-02 | feat: polish the plan-document HTML output (#617) |
| `22e22800` | 2026-08-30 | fix(plan-agent): unbreak the build completion gate for artifact-only plans (9.10.1) (#610) |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [reference-md-spec-in-plan-prompts.md](plans/reference-md-spec-in-plan-prompts.md)
