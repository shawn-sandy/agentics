# Reference the markdown spec in plan prompts and render Next Steps again

> Pointed all derived implement/goal/workflow prompts at the plan's markdown spec instead of the rendered HTML, cutting ~90% of agent-briefing tokens, and restored rendering of `## Next Steps` cards.

<!-- generated:start -->

**Status:** Shipped 2026-08-15 **Plan:** [reference-md-spec-in-plan-prompts.md](plans/reference-md-spec-in-plan-prompts.md)
**Type:** feature

## What shipped

- Parsed `## Next Steps` in `parseSpecMarkdown` into a `nextSteps` key returned alongside `sections`, supporting both bulleted items (summary/description/prompt) and prose fallback — leaving the extract-digest-parse round trip byte-stable.
- Rendered Next Steps as collapsible `<details>` cards with Copy-prompt buttons and a filtered sidebar nav entry, restoring the legacy rendering that the markdown-first rewrite had dropped.
- Pointed the implement, goal, and workflow prompts at the markdown spec path using a new `mdPath` render option; the CLI now passes the real spec path; a `.html` → `.md` fallback handles legacy callers.
- Emitted the spec path as a `plan-md` meta tag and a Spec row in the More-ways drawer.
- Rewrote the copy-button `buildImplementPrompt()` to follow the markdown-first loop: read the spec, insert `[x]` step markers, flip criteria to `- [x]`, set `status: completed`, then re-render — never hand-edit the HTML.
- Mirrored all shell changes into `reference/SKELETON.html` and documented the new behavior in `SKELETON.md`, `section-catalog.md`, and `SKILL.md`.
- Synced byte-identical bundled copies under `kit/plugins/plan-agent/scripts/` and bumped plan-agent to 2.21.0 with a CHANGELOG entry.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/build-plan-html.mjs` | HTML renderer — prompts use spec path, plan-md meta, Next Steps card and nav filter | Modified |
| `scripts/lib/plan-spec.mjs` | Spec parser — parses `## Next Steps` into `nextSteps` key | Modified |
| `scripts/lib/plan-shell.mjs` | Presentation shell — next-steps chrome, nav entry, nextStepsBlock template, plan-md meta, Spec drawer row, markdown-first buildImplementPrompt | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Bundled copy, byte-identical | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-spec.mjs` | Bundled copy, byte-identical | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Bundled copy, byte-identical | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html` | Reference template — plan-md meta, Spec row, markdown-first copy-button JS | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Reference template — Next Steps bullet/fence syntax | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Authoring guide — Next Steps catalog entry, removed from the markdown-only group | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill definition — spec-path prompts, plan-md meta, Next Steps cards documented | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 2.21.0 release entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent version bump 2.20.0 → 2.21.0 | Modified |
| `tests/plugins/test-build-plan-html.mjs` | Test suite — spec-path prompt pins, plan-md meta, Next Steps parse/render coverage | Modified |
| `tests/plugins/test-extractor-wiring.sh` | Shell test — pins the new self-contained copy-button JS | Modified |

## How it works

Step 1 extended `parseSpecMarkdown` in `scripts/lib/plan-spec.mjs` so that a `## Next Steps` section is extracted into a `nextSteps` key returned beside the existing `sections` map. Bulleted items are parsed into `{ summary, desc, prompt }` objects; bullet-less content becomes a prose string. Crucially, `nextSteps` travels outside `sections` — the same pattern `progress` uses — so existing round-trip tests over committed plans required no modification.

Step 2 wired rendering: `build-plan-html.mjs` checks for `spec.nextSteps` and passes the data to a new `nextStepsBlock()` template function in `plan-shell.mjs`. Each item renders as a `<details class="next-step-item">` card with a `<pre>` prompt block and a Copy-prompt button. A filtered sidebar nav entry links to the section. Specs without the section render neither the card nor the nav entry, preserving backwards compatibility.

Step 3 introduced a `mdPath` render option. When the CLI invokes the renderer it now passes the path of the `.md` spec file. The renderer stores this in a `plan-md` meta tag and uses it to populate the three derived prompt meta tags (`plan-implement`, `plan-goal`, `plan-workflow`) so every prompt that an implementing agent reads refers to the five-kilobyte markdown spec rather than the sixty-kilobyte rendered HTML. A `.html` → `.md` path substitution provides a fallback for callers that only know the HTML path.

Step 4 replaced `buildImplementPrompt()` in `plan-shell.mjs` with a markdown-first version. The five-step instruction set it emits tells the implementing agent to (1) open the `.md` spec by the path in `plan-md`, (2) insert `[x]` markers on completed steps, (3) flip acceptance criteria to `- [x]`, (4) set `status: completed` in the frontmatter, then (5) re-render the sibling HTML. The old prompt said "mark it done in the plan" with a reference to the HTML, which invited the `checked`-attribute edits that the markdown-first architecture forbids.

Step 5 reflected every shell change in the reference template files under `kit/plugins/plan-agent/skills/implementation-plan/reference/`. `SKELETON.html` received the `plan-md` meta tag, the Spec drawer row, and the updated copy-button script. `SKELETON.md` shows the Next Steps bullet and fenced-prompt syntax. `section-catalog.md` gained a Next Steps entry and removed Next Steps from the markdown-only group. `SKILL.md` documents the new behavior for plan authors.

Step 6 synced the three bundled copies under `kit/plugins/plan-agent/scripts/` and updated the test suite: `test-build-plan-html.mjs` gained pinned assertions for the spec-path prompts, the `plan-md` meta tag, and Next Steps parse-and-render behavior; `test-extractor-wiring.sh` was updated to pin the new self-contained copy-button JS.

## How to use it

Next Steps items in a plan spec use this syntax in `SKELETON.md`:

```markdown
## Next Steps

- Short summary of the follow-up
  One-sentence description of what it involves.
  ```text
  In the agentics repo, <paste-ready implementing prompt here>.
  ```
```

After rendering, the HTML plan's Next Steps section appears as collapsible cards with Copy-prompt buttons. The implement prompt visible in the More-ways drawer and the `plan-implement` meta tag both name the `.md` spec path, so an implementing agent works from the compact markdown source.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| _(feature commit not isolated in available git log scope)_ | | |

<!-- generated:end -->

## References

- Plan: [reference-md-spec-in-plan-prompts.md](plans/reference-md-spec-in-plan-prompts.md)
