---
status: completed
modified: 2026-10-13
type: feature
created: 2026-10-13
repo-name: agentics
artifact-url: https://claude.ai/artifact/LVzCLUH38eaFkUC1u4nPby
issue: https://github.com/shawn-sandy/agentics/issues/650
glance: Reviewers click the actual UI change on the plan page instead of picturing it from prose, and build gets a concrete structure target. Done when a plan's preview renders isolated and interactive both locally and on claude.ai, and every preview-less plan renders byte-for-byte as before.
---

# Plan: Put live UI previews inside every plan that changes UI

## Objective

Give the plan spec an optional `## Previews` section of self-contained HTML blocks that the renderer turns into isolated, interactive previews inside the plan page, authored automatically by `implementation-plan` whenever a plan carries UI signals and treated by `build` as the structure target.

## Context

Plans that change UI describe the change only in prose today. The ways to see it before building all live outside the plan: `publish-hub` puts the plan and its prototype side by side as tabs, `prototype` builds one generic whole-flow table-and-form page, and `design` publishes artboards to a separate canvas. None of them puts the component change on the plan page next to the step that makes it.

A scratchpad spike (2026-10-13) rendered `docs/plans/add-design-phase.md` with the real renderer and added a sandboxed `<iframe srcdoc>` preview. Measured in Chromium via Playwright: script inside the preview ran (3 clicks registered), `&` and `"` survived the hub's existing `escSrcdoc`, reading `parent.document` from inside threw, the plan's own scripts still ran, there were zero console errors, and the page grew by 2.1 KB on 144 KB. Two gotchas surfaced. A literal `</script>` inside a preview's own JavaScript ends its script element (the author writes `<\/script>`, the same rule `prototype` enforces). The plan's manual dark-mode toggle does not reach the preview: setting `color-scheme` on the iframe element did not change `prefers-color-scheme` inside it (Chrome 155), while re-setting `srcdoc` with `data-theme` on the preview's `<html>` did.

Risks. Fidelity has a ceiling: previews are hand-written HTML and CSS approximations, not the project's real React or Vue components, which would need a project build step and break the self-contained model; the build rule below makes the project's real tokens win on visual detail. Spec size grows because previews live inline in the spec, by the user's choice; the authoring guideline asks for compact previews. A sandboxed srcdoc has not yet been checked under claude.ai's artifact policy, though `publish-hub` already ships unsandboxed srcdoc panels there; step 13 checks it before the plan is called done.

## Decisions

- Preview HTML lives inline in the spec as a fenced `html` block under each `## Previews` bullet — the user's call; render stays a pure function of the spec, so `--check`, the render hook, and the scope constraint need no change.
- Item syntax mirrors `## Next Steps`: bullet line = label with an optional trailing `(step N)` or `(steps N, M)` tag, indented lines = description, the first fenced block = the preview document; the parser lifts the Next Steps splitter into one shared helper rather than copying it.
- A preview may tag several steps; each tagged step gets its own `preview` chip — a component shared by two steps is shown once.
- A preview block with no `<html` tag fails the render with a ParseError naming the item: theme sync works by rewriting that tag, so a fragment would silently ignore the plan's toggle.
- Preview size is a guideline, not code: ui-previews.md asks for under about 4 KB per preview, because every implementing agent reads the whole spec.
- `--quick` skips preview authoring: it skips exploration, and a faithful preview needs the project's tokens, which exploration finds.
- Iframes load eagerly (no `loading="lazy"`), so Save as PDF prints every preview rather than a blank frame for any never scrolled into view.
- The `preview` chip keeps the step-chip look but is padded to at least 24×24px, the WCAG 2.2 (web accessibility guidelines) minimum target size for a standalone link.
- Authoring includes a contrast check: each preview's text colours are measured with a tool against 4.5:1 for body text and 3:1 for large text and UI parts, and failures are fixed before the plan is delivered.
- Previews ride beside `sections` as `previews`, exactly like `nextSteps`, so the committed-plan round-trip contract is untouched.
- `implementation-plan` authors previews automatically when `ui_signals_present` (the rule in `skills/review-plan/SKILL.md` Step 3b, referenced, never copied), one per distinct UI component or surface that changes, each showing its states side by side.
- `build` treats a preview as the structure target: structure, states, and copy come from it; the project's real tokens and components win on visual detail; a preview is never edited to match the build.
- Acceptance criterion 1 originally read: holding an `<iframe sandbox="allow-scripts">` whose decoded `srcdoc` equals the item's html block byte for byte. It was amended on 2026-10-13 with the user's approval, because that frame and the claude.ai criterion cannot both hold in the Claude desktop app (sandboxed frames paint, then go blank after any scroll, undetectably), and the user chose the `data:` URL frames below.
- Each preview renders as a `<figure class="plan-preview">` holding an `<iframe>` whose `src` is the html's `data:` URL, which gives it an opaque origin: it cannot read the plan page, its storage, or the artifact around it. No `sandbox` attribute (changed during step 13): every sandboxed frame ran but never painted inside the claude.ai artifact viewer in the desktop app, while a `data:` frame paints; the cost is the sandbox's extra flags (forms, popups, top navigation on a click), and the artifact viewer's own sandbox still blocks top navigation there.
- Every preview-only byte (inline styles, the step chip, the nav entry, the theme-sync script) is emitted only when previews exist, so preview-less plans render byte-identical — the same constraint the `ponytail:` note on `phaseGroup` records.
- Theme sync reloads each frame's `data:` URL with `data-theme` on the preview's `<html>` when the plan's `data-theme` is set, and restores the markup URL when it is not (a MutationObserver, no edit to the shared SCRIPT); a postMessage listener would have to be injected into author HTML and stripped again on extraction.
- `escSrcdoc` stays in `build-plan-hub.mjs`: previews ride in `data:` URLs, which `encodeURIComponent` already makes attribute-safe, so the renderer never needs it.
- No "View source" block and no auto-height: the spec is the source, and the iframe gets a fixed 320px height with `resize: vertical`.
- In-page links need no help: a `data:` document resolves `href="#x"` against itself. (The step 12 pass found a srcdoc frame resolving it against the plan page and loading the whole plan into the preview.)
- The preview's `<html>` tag is the first one after an optional doctype and comments (`PREVIEW_HTML_TAG` in plan-spec.mjs), shared by the parser check and the runtime rewrite, so an `<html` inside a comment or script string never counts.
- Previews are not design artboards: a `.dc.html` artboard loads `./support.js` and lives on a canvas, while a preview is one self-contained document.
- The renderer lane is red-green-verify (it changes application source and `tests/run-all.sh` runs node tests); the skills lane is docs-only and runs in parallel; `lead` runs the full gate last.

## Files

- scripts/lib/plan-spec.mjs (modified) — parse `## Previews` through a splitter shared with Next Steps; `extractPreviews()`, `previewsMarkdown()`, `buildDigest(sections, nextSteps, previews)`
- scripts/build-plan-html.mjs (modified) — render the Previews section, step chips, nav entry, theme-sync script
- scripts/lib/plan-shell.mjs (modified) — `previews` chrome and nav entry, `previewsBlock()`, preview chip in `stepCard()`
- scripts/extract-plan-spec.mjs (modified) — derive the spec with `specMarkdown(…, extractPreviews(html))`, and skip a legacy embedded digest on a page with previews
- scripts/rerender-plans.mjs (modified) — carry previews through a re-render
- scripts/backfill-plan-digests.mjs (modified) — carry previews into the digest
- kit/plugins/plan-agent/scripts/build-plan-html.mjs (modified) — byte-identical copy
- kit/plugins/plan-agent/scripts/extract-plan-spec.mjs (modified) — byte-identical copy
- kit/plugins/plan-agent/scripts/lib/plan-spec.mjs (modified) — byte-identical copy
- kit/plugins/plan-agent/scripts/lib/plan-shell.mjs (modified) — byte-identical copy
- tests/fixtures/plan-previews/no-previews.md (new) — preview-less spec for the golden render
- tests/fixtures/plan-previews/no-previews.html (new) — golden captured before the renderer changes
- tests/plugins/test-plan-previews.mjs (new) — parse, render, round-trip, and golden cases
- tests/plugins/test-build-plan-hub.mjs (modified) — a preview survives hub bundling
- kit/plugins/plan-agent/skills/implementation-plan/guidelines/ui-previews.md (new) — authoring contract and one worked example
- kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md (modified) — `## Previews` entry
- kit/plugins/plan-agent/skills/implementation-plan/guidelines/writing-style.md (modified) — Previews blocks are the one place HTML belongs in a spec
- kit/plugins/plan-agent/skills/implementation-plan/SKILL.md (modified) — author previews in Step 2 when UI signals are present
- kit/plugins/plan-agent/skills/build/references/ui-previews.md (new) — the structure-target rule
- kit/plugins/plan-agent/skills/build/SKILL.md (modified) — load the reference when the spec has `## Previews`
- .claude-plugin/marketplace.json (modified) — plan-agent 9.19.1 → 9.20.0
- kit/plugins/plan-agent/CHANGELOG.md (modified) — 9.20.0 entry
- kit/plugins/plan-agent/README.md (modified) — Previews in Features
- README.md (generated) — plan-agent row of the Plugin Reference Table, by scripts/build-readme-table.mjs

## Steps

### Lane: renderer (owns: scripts/build-plan-html.mjs, scripts/extract-plan-spec.mjs, scripts/rerender-plans.mjs, scripts/backfill-plan-digests.mjs, scripts/lib/**, kit/plugins/plan-agent/scripts/**, tests/fixtures/plan-previews/**, tests/plugins/test-plan-previews.mjs, tests/plugins/test-build-plan-hub.mjs)

### Phase: RED

1. [x] Write tests/fixtures/plan-previews/no-previews.md (a preview-less spec with `repo: fixture` and a fixed `created:`, plus Files, Decisions, and Next Steps) and render it with the unmodified renderer: `node scripts/build-plan-html.mjs tests/fixtures/plan-previews/no-previews.md -o tests/fixtures/plan-previews/no-previews.html`. Why: preview-less plans must stay byte-identical, and the only honest baseline is output captured before the renderer changes; pinning `repo` and `created` keeps the golden stable on any machine. Verify: the command exits 0 and `git status --short tests/fixtures/plan-previews` lists both files as new.
2. [x] Write tests/plugins/test-plan-previews.mjs, importing the renderer and spec modules as namespaces so a missing export fails an assertion instead of the import. Cases: parse (label, `(step N)` and `(steps N, M)` tags, description lines, the html block verbatim, a 4-backtick outer fence around a block containing three backticks); errors naming the item for a missing html block, a block with no `<html` tag, an empty label, and a tagged step beyond the step count; render (one `figure.plan-preview` per item, an iframe with no `sandbox` attribute whose `src` is the html's `data:` URL, no `loading="lazy"`, a `preview` chip on every tagged step linking to `#preview-<i>` with an inline style giving it at least a 24px min-height and min-width, a Previews nav entry, the theme-sync script present); round trip (`extractPreviews(render(spec))` and `buildDigest` → `parseSpecMarkdown` both return the parsed previews for html containing `&amp;`, `"`, and `<\/script>`); golden (rendering no-previews.md equals no-previews.html byte for byte and contains no `plan-preview`). Why: these cases pin every promise in the Decisions before any code exists, including the two gotchas the spike found. Verify: `node tests/plugins/test-plan-previews.mjs` exits non-zero with every case failing on the missing `previews` support except the golden, which passes — paste the output.
3. [x] Add a hub case to tests/plugins/test-build-plan-hub.mjs: bundle a spec carrying one preview, take the Plan panel's `srcdoc`, decode it with `decodeEntities`, and assert `extractPreviews` on the decoded page returns the original preview html. Why: the hub embeds the whole plan in its own srcdoc, so a preview's `data:` URL rides inside a srcdoc, and an escape applied in the wrong order breaks only here. Verify: `node tests/plugins/test-build-plan-hub.mjs` exits non-zero on the new case only — paste the output.

### Phase: GREEN

4. [x] Teach scripts/lib/plan-spec.mjs the `## Previews` section: lift the Next Steps bullet-and-fence splitter into one shared helper used by both sections, return `previews: { items: [{ label, steps, desc, html }] }` beside `nextSteps` (null when absent; `steps` is the tagged step numbers, empty when untagged), reject a block with no `<html` tag, and add `extractPreviews(html)` (figcaption text, `data-steps`, description, decoded `data:` URL) and `previewsMarkdown()`, with `buildDigest` taking `previews` as a third argument and fencing each block longer than any fence inside it. Why: previews must round-trip through every path a spec takes, and sharing the splitter keeps one fence parser instead of two that drift. Verify: the parse and round-trip cases in test-plan-previews.mjs pass, and `node tests/plugins/test-build-plan-html.mjs` still exits 0, proving Next Steps parses exactly as before.
5. [x] Render previews from scripts/build-plan-html.mjs and scripts/lib/plan-shell.mjs: add the `previews` section chrome and nav entry (after Steps), a `previewsBlock()` emitting each figure with inline styles (iframe loading the html's `data:` URL, 320px tall, `resize: vertical`, eager loading, `title="Preview: <label>"`), a `preview` chip in `stepCard()` on every tagged step, padded to a 24×24px target, and a script that reloads each frame with `data-theme` on its `<html>` whenever the plan's `data-theme` changes — all emitted only when previews exist. Why: this is the visible feature, and conditional emission is what keeps the golden byte-identical. Verify: the render and golden cases in test-plan-previews.mjs pass.
6. [x] Route every caller through the new argument and sync the copies: scripts/extract-plan-spec.mjs, scripts/rerender-plans.mjs, and scripts/backfill-plan-digests.mjs pass `extractPreviews(html)`; copy the four shared files into kit/plugins/plan-agent/scripts/. Why: a caller left on the old signature silently drops previews on its path, and the byte-identical-copies test fails when the plugin copies drift. Verify: `node tests/plugins/test-plan-previews.mjs && node tests/plugins/test-build-plan-hub.mjs && node tests/plugins/test-build-plan-html.mjs` exits 0; if tests still fail after 8 iterations, stop and report the exact blocker — the failing assertion, the last diff tried, and what was ruled out. Do not report success.

### Lane: skills (owns: kit/plugins/plan-agent/skills/**)

7. [x] Write kit/plugins/plan-agent/skills/implementation-plan/guidelines/ui-previews.md: when previews are authored (`ui_signals_present` per review-plan Step 3b; one per distinct component or surface that changes), the item syntax, and the authoring contract — a full self-contained document with an `<html>` tag, no external URLs, tokens on `:root` with the dark override under both `:root:not([data-theme="light"])` inside the media query and `:root[data-theme="dark"]`, the project's real token values copied from its stylesheet and cited in the description, every state side by side (default, hover or focus, disabled, error, empty, loading as they apply), semantic markup with labels and visible focus, `prefers-reduced-motion` honoured by any animation, `<\/script>` inside scripts, no real names, emails, or tokens, under about 4 KB per preview, and a contrast check measured with a tool (4.5:1 body text, 3:1 large text and UI parts, in both themes) with failures fixed before delivery — plus one filled worked example. Why: an author who has never seen a preview needs one page that produces a correct one, and the theme guards are what let the plan's toggle reach it. Verify: `grep -c 'data-theme="dark"' kit/plugins/plan-agent/skills/implementation-plan/guidelines/ui-previews.md` prints at least 2 and the file contains a fenced `html` example.
8. [x] Document the section and wire the authoring: add a `## Previews` entry to guidelines/section-catalog.md (syntax, when it earns its place, the beside-sections note), carve the Previews blocks out of the no-HTML rule in guidelines/writing-style.md, and add a sub-step to implementation-plan/SKILL.md Step 2 that authors previews when `ui_signals_present`, reading guidelines/ui-previews.md, and is skipped under `--quick`. Why: the catalog is where authors look up syntax, and without the writing-style carve-out the guidelines contradict each other. Verify: `grep -n '## Previews' kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` and `grep -n 'ui-previews.md' kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` each print a line.
9. [x] Write kit/plugins/plan-agent/skills/build/references/ui-previews.md — loaded only when the spec has `## Previews`; build each tagged step to its preview's structure, states, and copy; the project's real tokens and components win on visual detail; say so in one line when step prose and preview disagree; never edit a preview to match the build; the end-to-end gate checks that every state a preview shows exists in the built UI — and point to it from build/SKILL.md Step 2 beside the Visual spec line. Why: the preview only pays off if the implementing agent is held to it, and modelling the rule on design-spec.md keeps the two visual inputs consistent. Verify: `grep -n 'ui-previews.md' kit/plugins/plan-agent/skills/build/SKILL.md` prints a line and the reference states the structure-target rule.

### Lane: lead (after: renderer, skills)

10. [x] Bump plan-agent to 9.20.0 in .claude-plugin/marketplace.json, add the 9.20.0 entry to kit/plugins/plan-agent/CHANGELOG.md, and list Previews under Features in kit/plugins/plan-agent/README.md. Why: a new capability is a MINOR bump, and the CI guard fails a PR whose version does not exceed main. Verify: `git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0.

### Phase: VERIFY

11. [x] Run the local merge gate: `bash scripts/verify.sh`. Why: the CLAUDE.md merge gate requires it, and it runs `tests/run-all.sh`, which picks up the new test file automatically. Verify: exits 0; record every `SKIP (not configured)` line as a skip, not a pass.
12. [x] Re-render this plan's own spec (its `## Previews` section is the fixture) to the scratchpad, serve it on localhost with the Bash tool's `run_in_background`, and drive it with the Playwright MCP tools: assert the preview runs in an opaque origin (`window.origin` is `"null"`), a click inside changes its state, reading `parent.document` from inside throws, setting the plan's `data-theme` to `dark` sets `data-theme="dark"` on the preview's `<html>`, the step 5 `preview` chip jumps to the figure and measures at least 24×24px, the preview's text contrast measures at least 4.5:1 in both themes (computed colours read inside the frame), and the console shows zero errors. Why: unit tests prove the markup; only a browser proves the sandbox, the script, and the theme sync behave. Verify: report each measured value; any failure stops the plan at `in-progress`.
13. [x] Republish the re-rendered plan to its `artifact-url:` and open it on claude.ai: confirm the preview renders and responds to a click inside the artifact. Why: the sandboxed srcdoc has never been checked under claude.ai's artifact policy, and that page is where plans are read. Verify: the preview is visible and interactive on the artifact page; if it renders blank, report it with the URL and stop.

## Tests

Tier 1 — This plan changes application code
- Objective: a plan spec with a `## Previews` item renders a live, isolated preview inside the plan page. File: tests/plugins/test-plan-previews.mjs; Type: smoke; Asserts: figure with an opaque-origin `data:` URL iframe that decodes to the authored html, previews round-trip, preview-less golden byte-identical; Run: node tests/plugins/test-plan-previews.mjs
- Unit: Previews parsing and extraction. File: tests/plugins/test-plan-previews.mjs; Targets: parseSpecMarkdown, extractPreviews, previewsMarkdown, buildDigest; Key cases: `(step N)` and `(steps N, M)` tags, outrun fence, missing html block, block with no `<html` tag, empty label, step out of range, `&amp;` / `"` / `<\/script>` in html, chip target style, eager loading
- Integration: preview inside a hub bundle. File: tests/plugins/test-build-plan-hub.mjs; Targets: build-plan-hub.mjs; Key cases: the Plan panel srcdoc decodes to a page whose preview extracts to the original html
- Regression: Next Steps after the splitter lift. File: tests/plugins/test-build-plan-html.mjs (existing); Run: node tests/plugins/test-build-plan-html.mjs
- E2E (agent-driven, not committed): step 12's Playwright pass and step 13's artifact check, each reporting measured values

## Acceptance Criteria

- [x] A spec with a `## Previews` item renders a `figure.plan-preview` holding an iframe whose `data:` URL decodes to the item's html block byte for byte, in an opaque origin (no `sandbox`, no `allow-same-origin`).
- [x] In a browser, script inside a rendered preview runs and reading `parent.document` from inside throws.
- [x] Setting the plan's `data-theme` sets the same `data-theme` on each preview's `<html>`.
- [x] Every step a preview tags shows a `preview` chip linking to its figure with a hit area of at least 24×24px; an untagged preview still renders.
- [x] Preview iframes load eagerly, so Save as PDF prints every preview.
- [x] Rendering tests/fixtures/plan-previews/no-previews.md is byte-identical to the golden captured before the change.
- [x] Previews survive parse → render → `extractPreviews` → `buildDigest` → parse, and survive bundling by `plan-agent-hub`.
- [x] A Previews item with no html block, no `<html` tag, an empty label, or an out-of-range step fails the render with a message naming the item.
- [x] implementation-plan Step 2 authors previews when the plan carries UI signals and `--quick` is not set, following guidelines/ui-previews.md including its contrast check, and build's reference makes previews the structure target.
- [x] `bash scripts/verify.sh` exits 0 and plan-agent's version is 9.20.0, above main.
- [x] This plan, re-rendered and republished, shows its preview working on claude.ai.

## Verification

After both lanes merge and `lead` bumps the version, run `bash scripts/verify.sh` from the repo root and expect exit 0. Then re-render this spec with `plan-agent-render docs/plans/add-plan-ui-previews.md -o "$SCRATCHPAD/add-plan-ui-previews.html"` — before this plan lands, the renderer skips the `## Previews` section below; after, it renders. Open the page in a browser and confirm the Previews section shows one figure, the step 5 card shows a `preview` chip that jumps to it, the preview responds inside its frame, and flipping the plan's theme toggle flips the preview with it. Finally republish to the plan's `artifact-url:` and confirm the same preview works on claude.ai.

## Previews

- Step card preview chip and Previews figure (step 5)
  Tokens copied from scripts/lib/plan-shell.mjs (`--panel`, `--sunk`, `--ink`, `--ink-3`, `--rule`, `--accent`, `--accent-soft`, `--accent-line`) and the `.step-chip` rule. Contrast measured 2026-10-13 with a WCAG relative-luminance script over all ten text/background pairs in both themes: lowest 4.83:1 (dark `todo` chip, 4.8377 floored), all at or above 4.5:1.
  ```html
  <!doctype html>
  <html lang="en">
  <head>
  <meta charset="utf-8">
  <style>
    :root { --panel:#ffffff; --sunk:#f4f4f8; --ink:#14141c; --ink-3:#63637a; --rule:#e4e4ee; --accent:#3730c4; --accent-soft:#eeedfb; --accent-line:#c6c2f0; }
    @media (prefers-color-scheme: dark) {
      :root:not([data-theme="light"]) { --panel:#17171f; --sunk:#1d1d27; --ink:#ecebf2; --ink-3:#8a889c; --rule:#2a2a36; --accent:#a8a2f5; --accent-soft:#1f1d33; --accent-line:#454070; }
    }
    :root[data-theme="dark"] { --panel:#17171f; --sunk:#1d1d27; --ink:#ecebf2; --ink-3:#8a889c; --rule:#2a2a36; --accent:#a8a2f5; --accent-soft:#1f1d33; --accent-line:#454070; }
    body { margin:0; padding:16px; background:var(--panel); color:var(--ink); font:14px/1.45 system-ui, sans-serif; }
    .card { border:1px solid var(--rule); border-radius:4px; padding:12px 14px; display:flex; gap:8px; align-items:center; flex-wrap:wrap; }
    .chip { font:600 .62rem ui-monospace, Menlo, monospace; text-transform:uppercase; letter-spacing:.12em; padding:.12em .5em; border-radius:3px; border:1px solid var(--rule); background:var(--sunk); color:var(--ink-3); text-decoration:none; }
    a.chip { background:var(--accent-soft); color:var(--accent); border-color:var(--accent-line); display:inline-flex; align-items:center; justify-content:center; min-height:24px; min-width:24px; box-sizing:border-box; }
    a.chip:focus-visible { outline:2px solid var(--accent); outline-offset:2px; }
    figure { margin:16px 0 0; }
    figcaption { font-weight:600; margin-bottom:6px; }
    .frame { border:1px solid var(--rule); border-radius:4px; min-height:72px; display:grid; place-items:center; color:var(--ink-3); }
    .frame[data-on] { border-color:var(--accent); color:var(--accent); }
  </style>
  </head>
  <body>
  <div class="card">
    <span class="chip">todo</span>
    <a class="chip" href="#preview-1" id="chip">preview</a>
    <span>Add the save button to the settings form</span>
  </div>
  <figure id="preview-1">
    <figcaption>Save button states</figcaption>
    <div class="frame" id="frame">The component renders here, sandboxed</div>
  </figure>
  <script>
    document.getElementById('chip').addEventListener('click', function () {
      document.getElementById('frame').setAttribute('data-on', '');
    });
  </script>
  </body>
  </html>
  ```

## Next Steps

- Feed previews to review-plan's UX, accessibility, and frontend reviewers
  They could audit the real markup of each preview instead of inferring the UI from prose.
  ```text
  In the agentics repo (kit/plugins/plan-agent), make review-plan's plan-reviewer-ux, plan-reviewer-accessibility, and plan-reviewer-frontend agents read the spec's `## Previews` html blocks when present and cite issues by preview label. Add a test that a spec with a preview reaches the reviewers' brief. Bump the plan-agent minor version in .claude-plugin/marketplace.json and add a CHANGELOG entry. Verify with `bash tests/run-all.sh` exiting 0.
  ```
- Add a drift check pairing previews to steps
  A hook like check-design-drift.py that warns when a user-facing step has no preview, or a `(step N)` tag points at a step whose action changed.
- Wish list: a "View source" disclosure and auto-height for previews
