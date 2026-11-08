# Reference the markdown spec in plan prompts and render Next Steps again

> Point derived prompts at the plan's markdown spec instead of the rendered HTML, cutting ~90% of tokens an implementing agent spends reading the plan, while re-wiring Next Steps rendering.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [reference-md-spec-in-plan-prompts.md](plans/reference-md-spec-in-plan-prompts.md)
**Type:** feature

## What shipped

- Added `## Next Steps` parsing to `parseSpecMarkdown` as a `nextSteps` key (returned beside `sections`), keeping the round-trip byte-stable across extract/digest/parse cycles.
- Rendered Next Steps as collapsible cards with Copy-prompt buttons and a sidebar nav entry matching the legacy markup pattern (CSS and `copyPrompt()` JS were already present in the shell).
- Pointed the implement, goal, and workflow prompts at the markdown spec path via a new `mdPath` render option, emitted as `plan-md` meta tag and a Spec drawer row (spec is 10–20× smaller than rendered HTML, and the workflow prompt briefs every subagent with the file so the saving multiplies).
- Rewrote the copy-button `buildImplementPrompt()` to walk the markdown-first loop: read spec, insert `[x]` step markers, flip criteria to `- [x]`, set `status: completed`, then re-render the sibling HTML — forbidding hand-edits to the HTML.
- Mirrored all shell changes into `reference/SKELETON.html` and documented the new behavior in `SKELETON.md`, `section-catalog.md`, and `SKILL.md`.
- Synced byte-identical bundled copies under `kit/plugins/plan-agent/scripts/` and bumped plan-agent to 2.21.0.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/build-plan-html.mjs` | Canonical renderer — prompts use spec path; Next Steps card; CLI passes real spec path | Modified |
| `scripts/lib/plan-spec.mjs` | Markdown parser — `nextSteps` key added beside `sections` | Modified |
| `scripts/lib/plan-shell.mjs` | HTML shell — next-steps chrome, `plan-md` meta, Spec drawer row, markdown-first `buildImplementPrompt` | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-spec.mjs` | Byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html` | Versioned template — plan-md meta, Spec row, markdown-first copy-button JS | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Authoring template — Next Steps bullet/fence syntax | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Section catalog — Next Steps catalog entry added | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill instructions — spec-path prompts, plan-md meta, Next Steps cards documented | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Plugin changelog — 2.21.0 entry | Modified |
| `.claude-plugin/marketplace.json` | Marketplace — plan-agent 2.20.0 → 2.21.0 | Modified |
| `tests/plugins/test-build-plan-html.mjs` | Test suite — spec-path prompt pins, plan-md meta, Next Steps parse/render coverage | Modified |
| `tests/plugins/test-extractor-wiring.sh` | Shell test — pins new self-contained copy-button JS | Modified |

## How it works

Since the markdown-first rewrite (2.18–2.20), all progress state lives as checkbox syntax in the `.md` spec and hand-editing the rendered HTML is forbidden. However, the three derived prompts still pointed at the `.html` file — 10–20× the spec's size — and the copy-button prompt invited the `checked`-attribute edits the architecture forbids.

The first change was parsing. `scripts/lib/plan-spec.mjs`'s `parseSpecMarkdown` received a new `nextSteps` key returned beside `sections`. Bullets become `{summary, desc, prompt}` items; bullet-less content becomes prose. The key travels outside `sections` (as `progress` does) so the extract→digest→parse round-trip stays byte-stable.

The shell (`scripts/lib/plan-shell.mjs`) gained a `nextStepsBlock` template and sidebar nav filter. When `nextSteps` is non-empty, collapsible `<details>` items render with `<pre>` prompts and Copy-prompt buttons, matching the legacy markup whose CSS and `copyPrompt()` function were already present.

For the prompt change, a new `mdPath` render option threads the markdown spec path through to the three meta tags (`plan-implement`, `plan-goal`, `plan-workflow`). The CLI was updated to pass the real spec path; a `.html`→`.md` fallback covers legacy invocations. The spec path is also emitted as a `plan-md` meta tag and a Spec row in the More-ways drawer, making it discoverable from the rendered page.

`buildImplementPrompt()` was rewritten from scratch. The old instructions predated markdown-first and invited HTML `checked`-attribute edits. The new version instructs the implementing agent to: (1) read the spec, (2) insert `[x]` markers on completed steps, (3) flip acceptance criteria to `- [x]`, (4) set `status: completed`, and (5) re-render the sibling HTML — never touching the HTML directly.

The changes were mirrored into `reference/SKELETON.html` and documented in `SKELETON.md`, `section-catalog.md`, and `SKILL.md`, keeping the versioned template in sync with the renderer. Byte-identical bundled copies under `kit/plugins/plan-agent/scripts/` were re-synced, enforced by the parity assertion in `tests/plugins/test-build-plan-html.mjs`.

## How to use it

The changes are transparent to plan authors. Any plan spec with a `## Next Steps` section now renders collapsible cards with Copy-prompt buttons in the HTML output. The Implement, Goal, and Workflow drawer rows in a rendered plan now reference the `.md` spec path rather than the `.html` path.

Developers working on the renderer invoke it as before:

```bash
node scripts/build-plan-html.mjs docs/plans/my-plan.md -o docs/plans/my-plan.html
```

The `plan-md` meta tag in the resulting HTML names the spec file; the More-ways drawer exposes a clickable Spec row.

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
| `b8cfa1f` | 2026-09-04 | fix(plan-agent): style header links as chips and refocus a leading select after submit (9.13.1) (#623) |
| `d2e9f10` | 2026-09-02 | feat: polish the plan-document HTML output (#617) |
| `43a7fd9` | 2026-09-01 | feat(plan-agent): take review-plan off the experimental Agent Teams flag (#614) |
| `22e2280` | 2026-08-30 | fix(plan-agent): unbreak the build completion gate for artifact-only plans (9.10.1) (#610) |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [reference-md-spec-in-plan-prompts.md](plans/reference-md-spec-in-plan-prompts.md)
- Changelog: `kit/plugins/plan-agent/CHANGELOG.md` — 2.21.0 entry
