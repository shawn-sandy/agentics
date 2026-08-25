---
status: in-progress
type: feature
created: 2026-08-24
effort: high
workflow: never
issue: https://github.com/shawn-sandy/agentics/issues/600
glance: New plans become shareable claude.ai links the moment they are delivered, with no HTML file landing in the repo unless the author opts in with --file. It worked when the gallery cards an artifact-only plan by its URL, flips to the file when one exists, and bash scripts/verify.sh is green with the new gallery, hook, gate, and merge tests.
---

# Plan: Publish plans as artifacts by default

## Objective

Make `/plan-agent:implementation-plan` deliver every new plan as a published claude.ai artifact by default, demote the local `.html` file to a `--file` opt-in, and teach the plans gallery to card artifact-only plans by linking their artifact URL — a sibling `.html`, when published, always wins the card.

## Context

Today the skill renders `<stem>.html` beside the spec and delivers it over a throwaway local HTTP server — a preview only the author's machine can see, plus a 60–120 KB generated file in every plan commit. Publishing to a claude.ai artifact gives each plan a stable, shareable URL, and the plugin already owns every piece of the mechanism: the `build-feature` skill's Step 9 publishes feature docs and records `artifact-url:` in frontmatter so later rounds republish to the same page, the renderer already http(s)-guards URL-bearing keys (`issue:`, `design:`), and the separate `artifact-tools:plan-artifact` skill reads and writes the same `artifact-url:` key.

One risk shapes the design: the Artifact tool is model-side, so no test or hook can exercise a real publish. Everything around the publish — the gallery rule, the render-hook guard, the republish instruction inside the rendered prompts — is testable, and the skill text carries a fallback to `--file` delivery when a publish fails, so a broken publish path degrades to exactly today's behaviour instead of losing the plan.

## Decisions

- Publishing is inline in plan-agent via the Artifact tool, not delegated to `artifact-tools:plan-artifact` — the default output path must not depend on another plugin being installed; the shared `artifact-url:` frontmatter key keeps the two compatible (user-confirmed).
- The opt-in flag is `--file` and it is additive: the artifact always publishes, `--file` also writes the `.html` beside the spec, and the file wins the gallery card; a failed or unavailable Artifact tool falls back to file delivery with a one-line notice, and that fallback plan staying file-mode forever is accepted — anyone can still publish it later via `artifact-tools:plan-artifact` (interview-confirmed).
- Later spec changes republish on a bounded cadence: `build` republishes at `### Phase:` boundaries and on completion, `finalize-plan` on completion, and the renderer's verification-gate tail carries the completion republish instruction for fresh-session agents (interview-confirmed).
- The skill re-reads the spec frontmatter immediately before every publish and passes `url:` whenever `artifact-url:` is already present — the `plan-artifact` pattern that closes the two-sessions-two-URLs race (interview-confirmed).
- The gallery guards URL schemes itself, mirroring the renderer: a non-http(s) `artifact-url:` gets no card and a stderr warning, because the generator writes raw hrefs into a page people open (interview-confirmed).
- Artifact cards open in a new tab with `rel="noopener"` and carry a visually-hidden "opens on claude.ai" note beside the existing sr-only status text; file cards keep same-tab navigation (interview-confirmed).
- "A file is published" means a sibling `.html` exists — one signal shared by the gallery's link precedence and the render hook's re-render guard, with no new frontmatter mode key.
- The gallery cards artifact-only plans from the `.md` spec directly; no `plan-artifact-url` meta tag is added because no consumer reads one — the spec is the source the gallery already trusts.
- Gallery cards gain a `data-local` stem attribute — identical whether the card came from the file or the spec — and the union merge driver keys on it with an href fallback, because href stops being a stable identity once publishing can flip it (interview follow-up, user-confirmed).
- RED settled the test contracts: the chip is `class="artifact-chip"`, the gallery warning and the renderer warning both read `ignoring non-http(s) artifact-url`, and gate fixtures must not carry "republish" in their titles — the prompts embed the title, which poisoned the first assertion run.
- The renderer has byte-identical root copies (scripts/build-plan-html.mjs, scripts/lib/plan-shell.mjs) that the tests import — the GREEN renderer step syncs them alongside the kit originals.
- Steps follow red-green-verify because the change is mostly runnable shell, Python, and Node code with `scripts/verify.sh` behind it; `workflow: never` because the byte-identical copy sync and the tests-fail-first ordering do not fan out safely.
- GREEN step 5: an `artifact-url:` alone does not make a document a plan. `docs/plans/` also holds `type: session-export` notes that carry the same key, and keying the card rule on the key alone promoted two of them into the gallery (111 → 113 cards on real data). The spec walk now additionally requires the four sections `build-plan-html.mjs` refuses to render without — Objective, Steps, Acceptance Criteria, Verification — so the gallery and the renderer share one definition of "is a plan".
- GREEN step 5: the "no plan files found — skipping" guard moved from the raw file walk to the parsed entry list. A plans directory holding only specs the gallery cannot link now leaves an existing index.html alone instead of blanking it.
- GREEN step 6: the href fallback strips a trailing `.html` rather than keying on the raw href. A bare-href fallback is correct for cards that predate `data-local` but wrong for the first merge after this change — a legacy side keys `add-foo.html` while a regenerated side keys `add-foo`, doubling every card in an already-committed index. Stripping the extension lands both on the same stem.
- GREEN step 7: the Plans-tab parity check the step asks for lives in tests/plugins/test-gallery-artifact-cards.mjs rather than in a new file. That test already builds the fixture the comparison needs, so the three sibling generators run against the same plans directory the gallery just carded and their topbar totals are asserted equal to its card count — the drift is caught on every run instead of once by hand.

## Steps

### Phase: RED

1. [x] Author tests/plugins/test-gallery-artifact-cards.mjs: build a temp plans directory holding a spec with `artifact-url:` and no sibling `.html`, a spec with a sibling `.html`, a spec with neither, and a spec whose `artifact-url:` is `javascript:alert(1)`, run hooks/build-index.sh against it, and assert the first gets exactly one card whose href is the claude.ai URL with `target="_blank"`, `rel="noopener"`, an artifact chip in its meta row, and a visually-hidden "opens on claude.ai" span, the second gets exactly one same-tab card linking the relative `.html` path, the third and fourth get no card, and the page's plan count equals the cards emitted. Why: the gallery is the organizing surface the user keeps, so the card-from-spec rule is the objective itself and must fail before any generator change — and the scheme fixture keeps a hand-edited spec from writing a clickable `javascript:` href into a generated page. Verify: `node tests/plugins/test-gallery-artifact-cards.mjs` exits non-zero with the first fixture's missing-card assertion — paste the failure output.
2. [x] Author tests/plugins/test-render-hook-artifact-skip.sh: feed hooks/render-plan-html.py a PostToolUse event for a spec write in a temp project, asserting that with no sibling `.html` none is created while the gallery index is still rebuilt, and that with an existing sibling the sibling is re-rendered as today. Why: the hook currently always creates the sibling, which would resurrect the very file an artifact-mode author chose not to publish. Verify: `bash tests/plugins/test-render-hook-artifact-skip.sh` exits non-zero with the sibling-was-created assertion — paste the failure output.
3. [x] Author tests/plugins/test-artifact-url-gate.mjs: render one spec with `artifact-url: https://claude.ai/public/artifacts/test-123`, one without the key, and one with `artifact-url: javascript:alert(1)`, asserting the plan-implement, plan-goal, and plan-workflow prompts carry a republish instruction naming the URL only in the first case, the gate is unchanged when the key is absent, and the `javascript:` value is dropped with a warning. Why: the verification-gate tail is the only instruction a fresh-session implementing agent receives, so unless republish travels inside it every artifact link goes stale the moment steps start ticking. Verify: `node tests/plugins/test-artifact-url-gate.mjs` exits non-zero because no republish clause exists yet — paste the failure output.
4. [x] Extend tests/plugins/test-merge-gallery-index.sh with a divergent-identity case: merge two gallery index sides holding the same plan — carded by its artifact URL on one side and by its `.html` path on the other — and assert exactly one card survives. Why: the union merge driver keys cards on href, and a href that can flip between a file path and an artifact URL turns every such branch merge into a duplicate card. Verify: `bash tests/plugins/test-merge-gallery-index.sh` exits non-zero on the new case — paste the failure output.

### Phase: GREEN

5. [x] Extend the collection in kit/plugins/plan-agent/hooks/build-index.sh: after the `.html` walk, walk the same tree for `.md` specs whose frontmatter carries an http(s) `artifact-url:` (any other scheme skipped with a stderr warning) and whose stem has no `.html` in the collection, parse title from the `# Plan:` heading, status, type, effort, and created from frontmatter, and step totals from numbered items and `[x]` markers under `## Steps`, emit a card whose href is the artifact URL with `target="_blank" rel="noopener"`, an artifact chip in the meta row, and an sr-only "opens on claude.ai" span, stamp every card — file and artifact alike — with a `data-local` attribute holding the plan's plans-dir-relative stem (path without extension, so both sides of a publish flip share one key), fold the rule into the script's own plans-collection count, then copy the file byte-identical over scripts/build-plans-index.sh and docs/plans/build-index.sh. Why: an artifact-only plan has no `.html` for the existing walk to find, so without a spec walk it vanishes from the gallery, and the parity test holds the three copies together. Verify: `node tests/plugins/test-gallery-artifact-cards.mjs` and `node tests/plugins/test-build-index-parity.mjs` both exit 0.
6. [x] Re-key the card map in scripts/merge-plans-index.mjs on the `data-local` stem, falling back to href for cards that predate the attribute. Why: href stops being a stable card identity once publishing can change it, and the fallback keeps already-committed indexes mergeable. Verify: `bash tests/plugins/test-merge-gallery-index.sh` exits 0.
7. [x] Apply the same artifact-only-spec rule to `plans_count()` in kit/plugins/plan-agent/hooks/build-artifacts-index.sh, build-designs-index.sh, and build-prototypes-index.sh. Why: every gallery topbar shows the PLANS tab count, and three stale counters would disagree with the plans gallery the moment the first artifact-only plan exists. Verify: `bash tests/plugins/test-build-designs-index.sh` and `bash tests/plugins/test-build-prototypes-index.sh` exit 0, and on the step-1 temp fixture each updated `plans_count()` returns the same number as the gallery's emitted cards.
8. [x] Guard kit/plugins/plan-agent/hooks/render-plan-html.py: when no `<stem>.html` exists beside the written spec, skip the sibling render but still trigger the gallery-index rebuild; when the sibling exists, re-render it exactly as today. Why: a sibling's existence is the file-published signal, so the hook must keep maintaining published files without resurrecting unpublished ones — and artifact-mode spec edits still change card data the gallery has to pick up. Verify: `bash tests/plugins/test-render-hook-artifact-skip.sh` exits 0.
9. [x] Teach kit/plugins/plan-agent/scripts/build-plan-html.mjs the `artifact-url:` frontmatter key, http(s)-guarded exactly like `design:`, and append to the shared verification-gate tail — only when the key is present — an instruction to republish the plan artifact to that URL via the Artifact tool's `url` parameter after the re-render. Why: copyGoal and copyWorkflow copy the gate tail verbatim, so a republish clause placed anywhere else is silently dropped on two of the three prompt paths. Verify: `node tests/plugins/test-artifact-url-gate.mjs` and `node tests/plugins/test-build-plan-html.mjs` both exit 0.
10. [x] Rewrite the delivery path in kit/plugins/plan-agent/skills/implementation-plan/SKILL.md: add `--file` to the Flags list and argument-hint, add Artifact to allowed-tools, update the description frontmatter, and replace Steps 5d and 7 so every plan renders `<stem>.html` into the session scratchpad and publishes it with the Artifact tool — re-reading the spec frontmatter immediately beforehand and passing `url:` whenever `artifact-url:` is already present, otherwise writing the returned URL back as `artifact-url:` — reports the URL, and sends the `.md` spec via SendUserFile; `--file` additionally writes the `.html` beside the spec and runs today's browser-preview flow, and a failed or unavailable publish falls back to file delivery with a one-line notice. Why: this is the requested behaviour change — the artifact becomes the deliverable, the local file becomes the opt-in extra, and the pre-publish re-read closes the two-sessions-two-URLs race. Verify: `grep -q -- '--file' kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` passes, `grep -q 'artifact-url' kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` passes, and the description frontmatter line stays within the 200-character budget by `wc -c`.
11. [x] Sweep the downstream skill texts for sibling-`.html` assumptions: in kit/plugins/plan-agent/skills/build/SKILL.md add "republish via the Artifact tool with `url:` at each `### Phase:` boundary stop and on completion, when frontmatter carries `artifact-url:` and no sibling `.html` exists"; in skills/finalize-plan/SKILL.md add the same republish rule for the completion re-render; add Artifact to both allowed-tools lines; in skills/plans-library/SKILL.md update the collection description and the no-plans empty-state message to cover artifact-only specs; then audit skills/review-plan, plans-open, plan-status, documenting-plans, and markdown-to-html for paths that expect the `.html` to exist — fixing each (a reviewer or opener renders the spec to the scratchpad when no sibling exists) or recording it as confirmed sibling-free. Why: a build session that ticks steps without republishing leaves every gallery link stale, and a consumer that dies on a missing `.html` makes artifact-only plans second-class inside their own plugin. Verify: `grep -l 'artifact-url' kit/plugins/plan-agent/skills/build/SKILL.md kit/plugins/plan-agent/skills/finalize-plan/SKILL.md kit/plugins/plan-agent/skills/plans-library/SKILL.md` lists all three files, and the step's output names every audited skill as updated or confirmed sibling-free.
12. Bump plan-agent to 9.7.0 in .claude-plugin/marketplace.json, add the kit/plugins/plan-agent/CHANGELOG.md entry, and update the plugin README's flag table and workflow sections for `--file` and artifact-default delivery. Why: the marketplace file is the only place a version lives, and CI fails any plugin-touching PR whose version does not exceed the base branch. Verify: `git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0 and `grep -q '9.7.0' kit/plugins/plan-agent/CHANGELOG.md` passes.

### Phase: VERIFY

13. Run the full local gate: `bash scripts/verify.sh`. Why: the merge gate honours only a green local run — CI on this repo is billing-blocked often enough that red or green there proves nothing. Verify: exit 0 with the three new tests reported as passing and no `SKIP (not configured)` line counted as a pass.
14. Walk the user-visible rule end-to-end without the model-side Artifact tool: in a temp project, write a spec carrying `artifact-url:`, simulate the hook event and confirm no sibling appears while the index rebuilds, run plan-agent-plans-index and confirm the card's href is the claude.ai URL, then add a sibling `.html`, re-run, and confirm the same plan's card now links the file. Why: the per-step tests prove pieces in isolation; this walk proves the promise as a user sees it — artifact URL unless a file is published. Verify: paste the two card hrefs extracted from the two generated index.html states, one absolute claude.ai URL and one relative `.html` path for the same stem.

## Acceptance Criteria

- [ ] A plan authored without `--file` leaves no `.html` in the plans directory — only the `.md` spec, carrying an http(s) `artifact-url:` key once published.
- [ ] `/plan-agent:implementation-plan <objective> --file` writes `<stem>.html` beside the spec and the plan still publishes and records `artifact-url:` — the gallery card links the file.
- [ ] `plan-agent-plans-index` cards an artifact-only spec with href equal to its artifact URL and an artifact chip, and the card links the `.html` path instead whenever a sibling file exists.
- [ ] Artifact cards carry `target="_blank" rel="noopener"` and an sr-only "opens on claude.ai" note, and a spec whose `artifact-url:` is not http(s) yields no card and a stderr warning.
- [ ] A spec write event with no sibling `.html` creates no sibling but still rebuilds the gallery index; with a sibling present the hook re-renders it unchanged from today.
- [ ] The rendered implement, goal, and workflow prompts of a spec carrying `artifact-url:` instruct republishing to that URL; a spec without the key renders with the gate tail unchanged.
- [ ] Merging two gallery indexes where the same plan is published on only one side yields exactly one card, keyed by the `data-local` stem.
- [ ] `bash scripts/verify.sh` exits 0 including the three new tests, the extended merge test, and the existing build-index parity test.
- [ ] plan-agent reads 9.7.0 in .claude-plugin/marketplace.json and `BASE_REF=main node scripts/check-plugin-versions.mjs` passes after a fresh `git fetch origin`.

## Files

- kit/plugins/plan-agent/skills/implementation-plan/SKILL.md (modified) — --file flag, Artifact allowed-tool, scratchpad render + publish delivery, fallback
- kit/plugins/plan-agent/templates/plans-gallery.html (modified) — .artifact-chip colour rule
- kit/plugins/plan-agent/hooks/build-index.sh (modified) — card artifact-only specs, artifact chip, count rule
- scripts/build-plans-index.sh (modified) — byte-identical copy of build-index.sh
- docs/plans/build-index.sh (modified) — byte-identical copy of build-index.sh
- kit/plugins/plan-agent/hooks/build-artifacts-index.sh (modified) — plans_count includes artifact-only specs
- kit/plugins/plan-agent/hooks/build-designs-index.sh (modified) — same plans_count rule
- kit/plugins/plan-agent/hooks/build-prototypes-index.sh (modified) — same plans_count rule
- kit/plugins/plan-agent/hooks/render-plan-html.py (modified) — skip sibling render when none exists, still rebuild index
- kit/plugins/plan-agent/scripts/build-plan-html.mjs (modified) — artifact-url key, conditional republish clause in the gate tail
- scripts/build-plan-html.mjs (modified) — byte-identical root copy of the renderer
- kit/plugins/plan-agent/skills/build/SKILL.md (modified) — republish after re-render, Artifact allowed-tool
- kit/plugins/plan-agent/skills/finalize-plan/SKILL.md (modified) — republish after completion re-render, Artifact allowed-tool
- kit/plugins/plan-agent/skills/plans-library/SKILL.md (modified) — collection wording and empty-state cover artifact-only specs
- kit/plugins/plan-agent/skills/review-plan/SKILL.md (modified) — sibling-.html assumption audit, render-to-scratchpad where needed
- kit/plugins/plan-agent/skills/plans-open/SKILL.md (modified) — sibling-.html assumption audit
- kit/plugins/plan-agent/README.md (modified) — flag table and workflow notes
- kit/plugins/plan-agent/CHANGELOG.md (modified) — 9.7.0 entry
- .claude-plugin/marketplace.json (modified) — version 9.6.1 → 9.7.0
- scripts/merge-plans-index.mjs (modified) — key cards on the data-local stem, href fallback
- tests/plugins/test-merge-gallery-index.sh (modified) — divergent-identity merge case
- tests/plugins/test-gallery-artifact-cards.mjs (new) — objective test: gallery card rule
- tests/plugins/test-render-hook-artifact-skip.sh (new) — hook guard test
- tests/plugins/test-artifact-url-gate.mjs (new) — renderer gate republish test

## Tests

Tier 1 — This plan changes runnable shell, Python, and Node source
- Objective: an artifact-only plan is carded by its artifact URL and a sibling `.html` wins the card. File: tests/plugins/test-gallery-artifact-cards.mjs; Type: integration; Asserts: spec with `artifact-url:` and no sibling gets one new-tab noopener card with the claude.ai href, artifact chip, and sr-only destination note, sibling-`.html` spec gets one same-tab card with the file href, keyless and `javascript:`-scheme specs get none, count matches cards, and the artifacts/designs/prototypes topbars print the same Plans total as the gallery emits cards; Run: node tests/plugins/test-gallery-artifact-cards.mjs
- Integration: render hook honours the file-published signal. File: tests/plugins/test-render-hook-artifact-skip.sh; Targets: hooks/render-plan-html.py; Key cases: no sibling → no render + index rebuilt, sibling present → re-rendered; Run: bash tests/plugins/test-render-hook-artifact-skip.sh
- Integration: a publish flip never duplicates a gallery card on merge. File: tests/plugins/test-merge-gallery-index.sh; Targets: scripts/merge-plans-index.mjs; Key cases: same plan carded by artifact URL on one side and file path on the other merges to one card, legacy cards without data-local still key on href; Run: bash tests/plugins/test-merge-gallery-index.sh
- Unit: gate tail republish clause. File: tests/plugins/test-artifact-url-gate.mjs; Targets: build-plan-html.mjs prompt/gate builders; Key cases: `artifact-url:` present → all three prompts name the URL, absent → gate unchanged, `javascript:` scheme dropped with warning; Run: node tests/plugins/test-artifact-url-gate.mjs

## Verification

Run `bash scripts/verify.sh` from the repo root and require exit 0, with tests/plugins/test-gallery-artifact-cards.mjs, test-render-hook-artifact-skip.sh, test-artifact-url-gate.mjs, the extended test-merge-gallery-index.sh, and the pre-existing test-build-index-parity.mjs all reported green — a `SKIP (not configured)` line is a skip, not a pass. Then run the step-14 walk: one temp spec, hook event, gallery build, sibling added, gallery rebuilt — the same plan's card href must read as the claude.ai artifact URL in the first index.html and as the relative `.html` path in the second. Finally, `git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs` must exit 0 with plan-agent at 9.7.0.

The one piece no test can exercise is a real Artifact publish, because the Artifact tool is model-side. That path is verified on the feature's first live use; until then the skill text's fallback guarantees a failed publish degrades to exactly today's `--file` delivery rather than losing the plan.

## Next Steps

- Extend artifact-default delivery to the other HTML-producing skills
  markdown-to-html, prototype, and design gallery pages still deliver as local files only.
  ```text
  In ~/devbox/agentics, extend the artifact-default delivery pattern from
  kit/plugins/plan-agent/skills/implementation-plan/SKILL.md (introduced in 9.7.0:
  scratchpad render, Artifact publish, artifact-url: frontmatter, --file opt-in)
  to the markdown-to-html and prototype skills in the same plugin. Bump the
  plan-agent minor version in .claude-plugin/marketplace.json, add a CHANGELOG
  entry, and verify with bash scripts/verify.sh exiting 0 before reporting done.
  ```

## Resources

- kit/plugins/plan-agent/skills/build-feature/SKILL.md — Step 9's publish/republish flow, the `artifact-url:` precedent this plan reuses
- kit/plugins/artifact-tools/skills/plan-artifact/SKILL.md — the standalone republish skill that shares the `artifact-url:` key
- tests/plugins/test-build-index-parity.mjs — the three byte-identical build-index.sh copies and why step 4 syncs them
