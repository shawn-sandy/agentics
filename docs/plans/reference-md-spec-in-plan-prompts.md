---
status: completed
type: feature
created: 2026-07-13
repo: agentics
glance: Implementing agents were being briefed with the 60–120 KB rendered HTML when the 5–10 KB markdown spec carries strictly more information — and the old copy-button prompt invited the HTML hand-edits the markdown-first architecture forbids. After this change every derived prompt points at the spec, agents tick progress in the spec and re-render, and the Next Steps follow-up cards render in the HTML again.
---
# Plan: Reference the markdown spec in plan prompts and render Next Steps again

## Objective
Point the derived implement/goal/workflow prompts at the plan's markdown spec instead of the rendered HTML (cutting ~90% of the tokens an implementing agent spends reading the plan), keep the HTML plan fully updated — steps checked and marked complete — via explicit spec-edit + re-render instructions, and render the `## Next Steps` section into the HTML plan as legacy plans had it.

## Context
Since the markdown-first rewrite (2.18–2.20) the `.md` spec is the source of truth: all progress state is checkbox syntax in the spec, and hand-editing the rendered HTML is forbidden. But the three derived prompts still pointed at the `.html` file (10–20× the spec's size, mostly CSS/JS/SVG chrome), and the copy-button prompt told agents to read "a self-contained HTML file" and "mark it done in the plan" — inviting exactly the `checked`-attribute edits the architecture bans. The workflow prompt multiplied the waste by briefing every subagent with the HTML.

Separately, the markdown-first renderer skipped `## Next Steps`, a section legacy hand-written plans rendered as collapsible cards with paste-ready prompts — the CSS, icon, and `copyPrompt()` JS never left the shell, only the parsing and rendering wiring was missing.

## Files
- scripts/build-plan-html.mjs (modified) — prompts use the spec path; plan-md meta; Next Steps card + nav filter; CLI passes the real spec path
- scripts/lib/plan-spec.mjs (modified) — parse ## Next Steps into a nextSteps key beside sections (round-trip stays byte-stable)
- scripts/lib/plan-shell.mjs (modified) — next-steps chrome + nav entry, nextStepsBlock template, plan-md meta tag, Spec drawer row, markdown-first buildImplementPrompt
- kit/plugins/plan-agent/scripts/build-plan-html.mjs (modified) — byte-identical bundled copy
- kit/plugins/plan-agent/scripts/lib/plan-spec.mjs (modified) — byte-identical bundled copy
- kit/plugins/plan-agent/scripts/lib/plan-shell.mjs (modified) — byte-identical bundled copy
- kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html (modified) — plan-md meta, Spec row, markdown-first copy-button JS
- kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md (modified) — Next Steps bullet/fence syntax
- kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md (modified) — Next Steps catalog entry; removed from the markdown-only group
- kit/plugins/plan-agent/skills/implementation-plan/SKILL.md (modified) — spec-path prompts, plan-md meta, Next Steps cards documented
- kit/plugins/plan-agent/CHANGELOG.md (modified) — 2.21.0 entry
- .claude-plugin/marketplace.json (modified) — plan-agent 2.20.0 → 2.21.0
- tests/plugins/test-build-plan-html.mjs (modified) — spec-path prompt pins, plan-md meta, Next Steps parse/render coverage
- tests/plugins/test-extractor-wiring.sh (modified) — pins the new self-contained copy-button JS

## Steps
1. [x] Parse `## Next Steps` in parseSpecMarkdown into a `nextSteps` key returned beside `sections` (bullets → summary/desc/prompt items, bullet-less content → prose). Why: the extract → digest → parse round trip over committed plans must stay byte-stable, so the section travels like `progress` does — outside `sections`. Verify: node tests/plugins/test-build-plan-html.mjs — the round-trip check still passes and the new Next Steps parse test passes.
2. [x] Render the Next Steps section card (collapsible details items with Copy-prompt buttons, matching the legacy markup) plus a filtered sidebar nav entry. Why: legacy hand-written plans carried this section and the shell still ships its CSS, icon, and copyPrompt() JS — only wiring was missing. Verify: render a spec with a `## Next Steps` section and confirm the card, `<pre>` prompt, and nav entry appear; a spec without the section renders neither.
3. [x] Point the implement, goal, and workflow prompts at the markdown spec path — new `mdPath` render option, CLI passes the real spec path, `.html` → `.md` fallback — and emit it as the `plan-md` meta tag plus a Spec drawer row. Why: the spec is 10–20× smaller than the rendered HTML and is where progress updates land; the workflow prompt briefs every subagent with the file, so the saving multiplies. Verify: rendered head carries `plan-implement`/`plan-goal`/`plan-workflow` contents ending in `.md` and a `plan-md` meta tag.
4. [x] Rewrite the copy-button buildImplementPrompt() to walk the markdown-first loop: read the spec, insert `[x]` step markers, flip criteria to `- [x]`, set `status: completed`, then re-render the sibling HTML — never hand-edit it. Why: the old instructions predate markdown-first and invited HTML `checked`-attribute edits; the re-render step is what keeps the HTML plan checked and marked complete exactly as before. Verify: the rendered plan's JS contains the five-step instructions referencing the spec path, and tests/plugins/test-extractor-wiring.sh check 2 passes.
5. [x] Mirror the shell changes into reference/SKELETON.html and document the new behavior in SKELETON.md, section-catalog.md, and SKILL.md. Why: the skeleton is the versioned template the shell was extracted from and the docs are what authors follow — drift between them and the renderer is a defect. Verify: bash tests/plugins/test-humanized-skeleton.sh and bash tests/plugins/test-goal-prompt.sh pass; section-catalog.md documents the Next Steps syntax.
6. [x] Sync the byte-identical bundled copies under kit/plugins/plan-agent/scripts/, update the pinned tests, and bump plan-agent to 2.21.0 with a CHANGELOG entry. Why: a test enforces bundled-copy identity, the old prompt strings were pinned by tests, and marketplace versioning is manual per the repo rules. Verify: node tests/plugins/test-build-plan-html.mjs reports the byte-identity check passing and marketplace.json says 2.21.0.

## Tests
Tier 1 — This plan changes application code
- Objective: derived prompts reference the markdown spec and Next Steps renders. File: tests/plugins/test-build-plan-html.mjs; Type: unit + integration; Asserts: plan-implement/plan-goal/plan-workflow metas carry the `.md` spec path, plan-md meta and Spec row render, `## Next Steps` parses beside sections and renders as collapsible cards with copy buttons, and committed plans still round-trip; Run: node tests/plugins/test-build-plan-html.mjs
- Integration: skeleton copy-button JS is markdown-first and self-contained. File: tests/plugins/test-extractor-wiring.sh; Targets: reference/SKELETON.html buildImplementPrompt(); Key cases: reads the spec by path, no repo-local script references
- Smoke: skeleton machine contract intact. File: tests/plugins/test-humanized-skeleton.sh; Targets: meta tags, ids, nav-label/heading parity; Key cases: all plan-* metas present, nav labels match section headings

## Acceptance Criteria
- [x] The plan-implement, plan-goal, and plan-workflow meta tags (and their visible rows) reference the plan's markdown spec path, not the `.html` path.
- [x] Rendered plans expose the spec path as a `plan-md` meta tag and a Spec row in the More-ways drawer.
- [x] The copy-button implement prompt instructs spec edits (`[x]` markers, `- [x]` criteria, `status: completed`) followed by a re-render, so the HTML plan ends up checked and marked complete — and forbids hand-editing the HTML.
- [x] A spec's `## Next Steps` section renders into the HTML as collapsible cards with paste-ready prompts and Copy-prompt buttons, with a sidebar nav entry; specs without the section render neither.
- [x] The extract → digest → parse → render → re-extract round trip over committed plans still passes.
- [x] The bundled kit/plugins/plan-agent/scripts/ copies are byte-identical to scripts/.
- [x] plan-agent is 2.21.0 in marketplace.json with a matching CHANGELOG entry.

## Verification
Render a spec containing a `## Next Steps` section with the bundled renderer and open the HTML: the Implement row and drawer prompts name the `.md` spec, the drawer shows File/Path/Spec rows, and the Next Steps card expands to a paste-ready prompt with a working Copy button. Run the full plugin test suite — node tests/plugins/test-build-plan-html.mjs plus the goal-prompt, extractor-wiring, and humanized-skeleton shell tests — and confirm every check passes, including the ≥10-plan round-trip and the bundled-copy identity check. Flip a criterion in a spec, re-render, and confirm the HTML checkbox state follows the spec.

## Next Steps

- Extract Next Steps from legacy HTML plans so conversion keeps them
  extractSections() ignores the legacy `#next-steps` markup today, so re-deriving a spec from a pre-2.18 HTML plan drops its follow-ups.
  ```text
  In the agentics repo, teach extractSections() in scripts/lib/plan-spec.mjs
  to read the legacy #next-steps section (details.next-step-item summary +
  pre prompt) into the nextSteps shape parseSpecMarkdown returns, and emit it
  from extract-plan-spec.mjs output so legacy-plan conversion preserves
  follow-ups. Keep sections round-trip byte-stable. Sync the bundled copies,
  bump the plan-agent minor version in .claude-plugin/marketplace.json, and
  add a CHANGELOG entry.
  ```
- Render Unresolved Questions and Resources too
  The renderer still skips the two remaining markdown-only sections; the skeleton already carries an Unresolved Questions shell.
  ```text
  In the agentics repo, extend parseSpecMarkdown and build-plan-html.mjs so
  ## Unresolved Questions and ## Resources render into HTML plans (following
  the nextSteps-beside-sections pattern from 2.21.0), update
  section-catalog.md, sync the bundled plan-agent script copies, bump the
  plan-agent minor version, and add a CHANGELOG entry.
  ```
