# Reference the markdown spec in plan prompts and render Next Steps again

> Points all derived plan prompts at the markdown spec instead of the rendered HTML (cutting ~90% of briefing tokens), keeps HTML progress state in sync via explicit spec-edit + re-render instructions, and restores the Next Steps section as collapsible cards with paste-ready prompts.

<!-- generated:start -->

**Status:** Shipped 2026-08-18 **Plan:** [reference-md-spec-in-plan-prompts.md](plans/reference-md-spec-in-plan-prompts.md)
**Type:** feature

## What shipped

- Extended `parseSpecMarkdown` in `scripts/lib/plan-spec.mjs` to parse `## Next Steps` into a `nextSteps` key returned beside `sections`, without affecting the extract → digest → parse round-trip.
- Added `nextStepsBlock` template and sidebar nav entry to `scripts/lib/plan-shell.mjs`, rendering each follow-up as a collapsible `<details>` item with a `<pre>` prompt and a Copy-prompt button.
- Added a `mdPath` render option to `scripts/build-plan-html.mjs`; the CLI now passes the real spec path, and the implement, goal, and workflow meta tags (`plan-implement`, `plan-goal`, `plan-workflow`) reference the `.md` file rather than the `.html` file.
- Added a `plan-md` meta tag and a Spec row in the More-ways drawer so agents and scripts can locate the spec from a rendered HTML plan.
- Rewrote `buildImplementPrompt()` in `plan-shell.mjs` to follow the markdown-first loop: read the spec, insert `[x]` step markers, flip criteria to `- [x]`, set `status: completed`, then re-render the sibling HTML — forbidding direct HTML edits.
- Mirrored all changes into `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html` and updated `SKELETON.md`, `section-catalog.md`, and `SKILL.md`.
- Synced byte-identical bundled copies under `kit/plugins/plan-agent/scripts/`, updated pinned test strings, and bumped plan-agent 2.20.0 → 2.21.0.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/build-plan-html.mjs` | mdPath option, spec-path meta tags, CLI path passing | Modified |
| `scripts/lib/plan-spec.mjs` | Next Steps parsing into nextSteps key | Modified |
| `scripts/lib/plan-shell.mjs` | nextStepsBlock template, plan-md meta, Spec drawer row, markdown-first buildImplementPrompt | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-spec.mjs` | Byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html` | plan-md meta, Spec row, markdown-first copy-button JS | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Next Steps bullet/fence syntax | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Next Steps catalog entry | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Spec-path prompts, plan-md meta, Next Steps cards documented | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 2.21.0 entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 2.20.0 → 2.21.0 | Modified |
| `tests/plugins/test-build-plan-html.mjs` | Spec-path prompt pins, plan-md meta, Next Steps parse/render coverage | Modified |
| `tests/plugins/test-extractor-wiring.sh` | Pins new self-contained copy-button JS | Modified |

## How it works

**The token cost problem.** Since the markdown-first rewrite (2.18–2.20), the `.md` spec is the source of truth for all plan progress state. But the three derived prompts (`plan-implement`, `plan-goal`, `plan-workflow`) still referenced the `.html` file — 10–20× the spec's size, mostly CSS, JavaScript, and SVG chrome. The workflow prompt compounded this by briefing every subagent with the HTML file. Switching to the spec cuts ~90% of the tokens an implementing agent spends reading a plan.

**The prompt update is a single render option.** `build-plan-html.mjs` now accepts an `mdPath` option that the CLI passes as the real spec file path. When present, the three meta tags and their visible rows emit the `.md` path; a `.html` → `.md` fallback handles plans rendered before this change. The `plan-md` meta tag is added unconditionally so any script or agent can find the spec from the rendered HTML without knowing the directory layout.

**The copy-button's markdown-first loop.** The old `buildImplementPrompt()` predate the markdown-first architecture and invited `checked`-attribute edits directly in the HTML — exactly what the architecture forbids. The rewritten prompt gives implementing agents five explicit instructions: (1) read the spec by `plan-md` path, (2) mark each completed step with `[x]`, (3) flip acceptance criteria to `- [x]`, (4) set `status: completed` in frontmatter, (5) re-render the sibling HTML with `node scripts/build-plan-html.mjs`. This keeps the HTML checked and marked complete without any direct HTML edits.

**Next Steps rendering re-uses existing CSS.** The `## Next Steps` section was already parsed and handed to the digest, but `build-plan-html.mjs` never wired it to a rendering function. `parseSpecMarkdown` now pulls the section out of `sections` and returns it as a `nextSteps` key (matching how `progress` travels outside `sections`), so the extract → digest → parse round trip remains byte-stable. `nextStepsBlock` in `plan-shell.mjs` renders each follow-up as a `<details>` item whose `<pre>` block holds the paste-ready prompt and whose Copy-prompt button re-uses `copyPrompt()` — CSS, icon, and JS that the shell already shipped.

**Skeleton drift is prevented by the test suite.** `SKELETON.html` is the versioned template the renderer was extracted from; drift between it and the live renderer is a defect. `test-extractor-wiring.sh` pins the copy-button JS as a substring check, and `test-humanized-skeleton.sh` asserts that all `plan-*` meta tags and nav-label/heading pairs are present. Both tests were updated to assert the new markdown-first wording.

## How to use it

Render a spec that contains a `## Next Steps` section:

```bash
node scripts/build-plan-html.mjs docs/plans/my-plan.md -o /tmp/check.html
```

Open the HTML: the Implement row and drawer prompts name the `.md` spec, the drawer shows a Spec row, and the Next Steps card expands to a paste-ready prompt with a working Copy button.

Run the full plugin test suite to confirm the round-trip and bundled-copy identity:

```bash
node tests/plugins/test-build-plan-html.mjs
bash tests/plugins/test-extractor-wiring.sh
bash tests/plugins/test-humanized-skeleton.sh
bash tests/plugins/test-goal-prompt.sh
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |

<!-- generated:end -->

## References

- Plan: [reference-md-spec-in-plan-prompts.md](plans/reference-md-spec-in-plan-prompts.md)
