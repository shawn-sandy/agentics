# Reference the markdown spec in plan prompts and render Next Steps again

> Derived implement/goal/workflow prompts now point at the 5–10 KB markdown spec instead of the 60–120 KB rendered HTML, and the Next Steps section renders as collapsible cards with copy buttons.

<!-- generated:start -->

**Status:** Shipped 2026-08-03 **Plan:** [reference-md-spec-in-plan-prompts.md](plans/reference-md-spec-in-plan-prompts.md)
**Type:** feature

## What shipped

- Extended `parseSpecMarkdown` in `scripts/lib/plan-spec.mjs` to parse `## Next Steps` into a `nextSteps` key beside `sections`, with bullet items becoming summary/desc/prompt triples and bullet-less content becoming prose — round-trip stays byte-stable.
- Added Next Steps card rendering to `scripts/lib/plan-shell.mjs` and `scripts/build-plan-html.mjs`: collapsible `<details>` items with Copy-prompt buttons, a filtered sidebar nav entry, and the `nextStepsBlock` template — matching the legacy hand-written markup whose CSS, icon, and `copyPrompt()` JS already lived in the shell.
- Introduced `mdPath` render option and `plan-md` meta tag: the CLI now passes the real spec path; all three derived prompts (`plan-implement`, `plan-goal`, `plan-workflow`) emit the `.md` path, not the `.html` path; a Spec drawer row exposes it in the rendered plan.
- Rewrote the copy-button `buildImplementPrompt()` to the markdown-first loop: read the spec, insert `[x]` step markers, flip `- [x]` criteria, set `status: completed`, then re-render the sibling HTML — never hand-edit the HTML.
- Mirrored all shell changes into `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html`; documented the new behaviour in `SKELETON.md`, `section-catalog.md`, and `implementation-plan/SKILL.md`.
- Synced the three bundled copies under `kit/plugins/plan-agent/scripts/` to be byte-identical to the repo-root sources.
- Updated pinned tests in `tests/plugins/test-build-plan-html.mjs` (spec-path prompt pins, `plan-md` meta, Next Steps parse/render coverage) and `tests/plugins/test-extractor-wiring.sh` (new self-contained copy-button JS).
- Bumped plan-agent to 2.21.0 with a CHANGELOG entry; updated `.claude-plugin/marketplace.json` from 2.20.0 → 2.21.0.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/build-plan-html.mjs` | CLI renderer — mdPath option, spec path in prompts | Modified |
| `scripts/lib/plan-spec.mjs` | Plan spec parser — nextSteps key | Modified |
| `scripts/lib/plan-shell.mjs` | HTML shell builder — Next Steps chrome, nextStepsBlock, plan-md meta, markdown-first buildImplementPrompt | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Bundled renderer copy (byte-identical) | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-spec.mjs` | Bundled parser copy (byte-identical) | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Bundled shell copy (byte-identical) | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html` | Plan skeleton HTML template — plan-md meta, Spec row, markdown-first copy-button JS | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Plan skeleton markdown template — Next Steps bullet/fence syntax | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Section authoring guide — Next Steps catalog entry | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill instructions — spec-path prompts, plan-md meta, Next Steps cards | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Version history — 2.21.0 entry | Modified |
| `.claude-plugin/marketplace.json` | Marketplace manifest — plan-agent 2.20.0 → 2.21.0 | Modified |
| `tests/plugins/test-build-plan-html.mjs` | Test coverage — spec-path pins, plan-md meta, Next Steps parse/render | Modified |
| `tests/plugins/test-extractor-wiring.sh` | Test coverage — self-contained copy-button JS pin | Modified |

## How it works

Since the markdown-first rewrite (plan-agent 2.18–2.20) the `.md` spec is the source of truth: all progress state lives as checkbox syntax in the spec and re-renders are lossless. But three derived prompts still pointed at the `.html` file — 10–20× the spec's size, mostly CSS/JS/SVG chrome — and the copy-button prompt told implementing agents to read "a self-contained HTML file" and "mark it done in the plan", inviting the `checked`-attribute edits the architecture forbids. The workflow prompt multiplied the waste by briefing every subagent with the HTML path.

Step 1 extended `parseSpecMarkdown` in `scripts/lib/plan-spec.mjs` to scan for a `## Next Steps` section. Bullet items are parsed into structured triples (summary, description, prompt fenced block); non-bullet content becomes prose. The result is a `nextSteps` key returned alongside `sections`, deliberately outside it so the extract-digest-parse round-trip that compares `sections` byte-for-byte is unaffected. A spec without a `## Next Steps` section returns `null` for the key.

Step 2 added rendering for `nextSteps` in `scripts/lib/plan-shell.mjs` and `scripts/build-plan-html.mjs`. Each item becomes a `<details>` element with a collapsible summary, a `<pre>` prompt block, and a Copy-prompt button. The sidebar nav gains a filtered entry for the section. The shell's CSS, icon, and `copyPrompt()` JS were already present — only the parsing and rendering wiring was missing from the markdown-first path. A spec without a `## Next Steps` section renders neither the card nor the nav entry.

Step 3 introduced the `mdPath` render option. The CLI now computes the sibling `.md` spec path and passes it to the renderer. The shell emits `<meta name="plan-md">` with the spec path, updates all three derived prompt meta tags (`plan-implement`, `plan-goal`, `plan-workflow`) to end in `.md` instead of `.html`, and adds a Spec row to the More-ways drawer. The workflow prompt briefs subagents with the file, so cutting 90% of the token count per brief multiplies across every subagent invocation.

Step 4 rewrote `buildImplementPrompt()` — the JS function the HTML plan's Copy button embeds — to the markdown-first loop: (1) read the spec by path, (2) insert `[x]` markers on step items, (3) flip unfinished criteria to `- [x]`, (4) set `status: completed` in the frontmatter, (5) re-render the sibling HTML. This explicitly forbids hand-editing the HTML, which the old instructions permitted. The re-render step is what keeps the HTML plan checked and marked complete, without any frozen-string surgery.

Step 5 mirrored all shell changes into `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html` and updated the documentation: `SKELETON.md` gained Next Steps bullet and fence syntax, `section-catalog.md` gained a Next Steps catalog entry (removed from the markdown-only group), and `implementation-plan/SKILL.md` documents the spec-path prompts, the `plan-md` meta, and the Next Steps cards. Step 6 synced the bundled copies byte-identically and updated the test suite's pinned assertions.

## How to use it

The Next Steps section is authored in the markdown spec using the syntax documented in `section-catalog.md`:

```markdown
## Next Steps

- Summary line for the first follow-up
  One-line description of what it does.
  ```text
  In the agentics repo, do the thing described above.
  ```

- Summary line for the second follow-up
  Another description.
  ```text
  Follow-up prompt text here.
  ```
```

When rendered, each bullet becomes a collapsible card with a Copy-prompt button. The implement/goal/workflow prompts in the rendered HTML now reference the `.md` spec path — visible in the More-ways drawer's Spec row. The copy-button prompt walks the markdown-first loop automatically.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `0fd7b67` | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |
| `218bb28` | 2026-08-09 | feat(plan-agent): retune the plan document design (9.1.0) (#537) |
| `1b4f657` | 2026-08-06 | feat(plan-agent): red-green-verify plans (8.7.0) (#529) |
| `7ded3be` | 2026-08-05 | feat(plan-agent): phase checkpoints and a Decisions ledger for plan specs (8.6.0) (#528) |
| `8641b56` | 2026-08-04 | fix(plan-agent): plans-library delegates to the gallery generator (8.5.1) (#525) |
| `14d66fd` | 2026-08-04 | feat(plan-agent): typed build entry points + fix the proposal-path conversion trap (8.5.0) (#523) |
| `4a01a79` | 2026-08-03 | fix: replace eight unrunnable ${CLAUDE_PLUGIN_ROOT} Bash commands with bin/ wrappers (#520) |

<!-- generated:end -->

## References

- Plan: [reference-md-spec-in-plan-prompts.md](plans/reference-md-spec-in-plan-prompts.md)
- Related docs: [`kit/plugins/plan-agent/CHANGELOG.md`](../kit/plugins/plan-agent/CHANGELOG.md)
- Related plan: [make-plan-status-flows-md-first.md](make-plan-status-flows-md-first.md)
