---
status: todo
type: feature
created: 2026-08-18
effort: high
glance: A design canvas and the plan it belongs to currently have no link between them, and nothing offers either a prototype or a design at the moment a plan is finished. We will know this worked when authoring a UI plan offers a design canvas, the finished plan carries a clickable link to it, and build reads the artboards as the visual spec.
---

# Plan: Give plan-agent a design phase, so a plan can be seen before it is built

## Objective

Add a `plan-agent:design` skill plus the frontmatter, renderer, gallery, and
drift wiring that binds a published design canvas to the plan it came from, and
offer it alongside `prototype` at the end of the planning chain for UI plans.

## Context

Claude Code ships a built-in `design` skill that writes `.dc.html` artboards
into the working tree, seeds them with its own `seed-canvas.mjs`, and publishes
the result as an editable canvas Artifact. It already matches the host codebase's
tokens and components before drawing (its Step 0), and already asks whether the
user wants static mockups or a clickable prototype (its Step 1).

What it does not do is know about plans. Nothing links a canvas back to the plan
that motivated it, nothing offers it at the moment a plan is finished, and
`build` never looks at it.

`plan-agent` already solved this exact problem once, for prototypes:
`skills/prototype/` derives a data model from a plan, writes
`docs/prototypes/<slug>.html`, writes a `prototype:` key back into the spec, and
a `PostToolUse` hook rebuilds the gallery and checks for drift. This plan mirrors
that treatment for designs.

One gap it also closes: **nothing in the plan chain currently offers the
prototype either.** No skill outside `skills/prototype/` mentions it — the user
has to know the command exists. Step 8 gains one question that offers both.

Risks:

- **Renderer copy drift.** `build-plan-html.mjs` ships as two byte-identical
  copies (`scripts/` and `kit/plugins/plan-agent/scripts/`) with no parity test —
  unlike `build-index.sh`, whose three copies are guarded by
  `tests/plugins/test-build-index-parity.mjs`. Editing one and not the other
  half-ships the feature. Mitigation: step 4 edits both, and the objective test
  asserts they hash identically.
- **Upstream contract churn.** The built-in `design` skill owns the `.dc.html`
  format, the `seed-canvas.mjs` helper, the `contract: "0.1.31"` pin, and the
  capability roster. All of that changes without notice. Mitigation: our skill
  delegates to it via `Skill(design)` and reproduces none of it.
- **Hook budget.** `dispatch.py` shares one 55s deadline across every child. Two
  new children join it. Mitigation: `check-design-drift.py` does filename and
  heading comparison only — no network, no parse of the published canvas.

## Decisions

- Scope is a full skill mirroring `prototype`, not a record-only frontmatter key.
- Our skill derives artboards and links them back; the built-in `design` skill
  owns all authoring and publishing. We never reimplement the `.dc.html` format,
  the seeding helper, the contract pin, or the capability roster.
- Activation is a third batched question in the existing `implementation-plan`
  Step 8 menu, not two new options — both existing option lists already sit at
  the 4-option `AskUserQuestion` cap.
- The question fires only on UI plans, reusing the `ui_signals_present` rule
  already defined at `skills/review-plan/SKILL.md:78` rather than inventing a
  second definition of "UI".
- Drift means artboard names versus the plan's user-facing steps. It does not
  compare local artboards against the published canvas: people editing the canvas
  in the GUI is the feature working, and a check that fires on that is noise.
- Artboard derivation is one per **user-facing** step, uncapped. A step with no
  user-facing surface — a version bump, a test file, a README edit — produces no
  artboard. "User-facing" is load-bearing in two places: the derivation rule and
  the drift check must apply the same filter, or every housekeeping step reads as
  permanent drift.
- Pointed at a plan with no UI signals, the skill warns in one line and proceeds.
  It does not refuse: architecture diagrams and flow sketches are legitimate uses.
- End-to-end verification publishes a real canvas, against a throwaway plan, so a
  test canvas never lands in the real plan history.
- The drift hook ships in v1 rather than deferring, so the designs and prototypes
  galleries behave the same way from the start.
- The plan points at its design with two keys — `design:` (the artifact URL,
  which renders the header link) and `design-dir:` (the local artboard
  directory, which `build` reads). Two keys survive a plan rename; a
  slug-derived directory would not.

## Files

- `docs/plans/add-design-phase.md` (new) — this spec
- `tests/plugins/test-design-plan-link.mjs` (new) — objective test
- `tests/plugins/test-build-designs-index.sh` (new) — gallery generator test
- `tests/plugins/test-design-drift.sh` (new) — drift hook test
- `tests/fixtures/plan-agent/sample-design/` (new) — artboard fixture pair
- `scripts/build-plan-html.mjs` (modified) — `design:` / `design-dir:` keys
- `kit/plugins/plan-agent/scripts/build-plan-html.mjs` (modified) — identical copy
- `kit/plugins/plan-agent/hooks/build-designs-index.sh` (new) — designs gallery
- `kit/plugins/plan-agent/hooks/check-design-drift.py` (new) — drift check
- `kit/plugins/plan-agent/hooks/dispatch.py` (modified) — `docs/designs/` gate
- `kit/plugins/plan-agent/skills/design/SKILL.md` (new) — the skill
- `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` (modified) — Step 8 question
- `kit/plugins/plan-agent/skills/build/SKILL.md` (modified) — read artboards as visual spec
- `kit/plugins/plan-agent/README.md` (modified) — skill docs
- `README.md` (modified) — regenerated Plugin Reference Table
- `.claude-plugin/marketplace.json` (modified) — plan-agent 9.4.5 to 9.5.0

## Steps

### Phase: RED

1. Write `tests/plugins/test-design-plan-link.mjs`, modelled on
   `tests/plugins/test-prototype-plan-link.mjs`. It asserts four things: a spec
   carrying `design:` and `design-dir:` renders a `plan-design` meta tag plus a
   header anchor whose accessible text is non-empty and whose `href` is the
   artifact URL verbatim; a spec carrying neither renders neither; a spec
   carrying `design: javascript:alert(1)` renders neither tag nor anchor; and
   the two `build-plan-html.mjs` copies hash identically.
   Why: this is the test that proves the plan's objective — a plan and its
   canvas reference each other — and the fourth assertion is what stops the
   two-copy trap from shipping silently.
   Verify: `node tests/plugins/test-design-plan-link.mjs` exits non-zero on the
   missing `plan-design` meta tag, not on a module-resolution error — paste the
   failing assertion.

2. Write `tests/plugins/test-build-designs-index.sh`, modelled on
   `tests/plugins/test-build-prototypes-index.sh`. It asserts the generator
   writes `docs/designs/index.html` with one escaped card per canvas directory,
   skips its own generated index when re-run, and exits 0 on a directory holding
   no artboards.
   Why: the gallery is a hook child, and a hook child that exits non-zero blocks
   the write it was reacting to.
   Verify: `bash tests/plugins/test-build-designs-index.sh` exits non-zero
   reporting `build-designs-index.sh` not found.

3. Write `tests/plugins/test-design-drift.sh` plus the
   `tests/fixtures/plan-agent/sample-design/` fixture — one plan spec with three
   user-facing steps plus one housekeeping step, and a matching three-artboard
   directory, and one diverged pair where the spec gained a fourth user-facing
   step with no artboard. It asserts
   `check-design-drift.py` is silent on the matched pair — including its
   housekeeping step, which must not be reported — and names the uncovered step on
   the diverged one.
   Why: encodes the drift semantics chosen for this plan — artboards against
   plan steps — so a later change to mean something else fails loudly.
   Verify: `bash tests/plugins/test-design-drift.sh` exits non-zero reporting
   `check-design-drift.py` not found.

### Phase: GREEN

4. Add `design:` and `design-dir:` handling to **both** copies of
   `build-plan-html.mjs` (`scripts/` and `kit/plugins/plan-agent/scripts/`),
   modelled on the existing `issue:` block near line 313 — http(s) only, drop
   anything else for both the tag and the link — emitting a `plan-design` meta
   tag and a "View design" header action row link. Do not model it on the
   `prototype:` block: that relativizes a repo path, and a canvas lives at a URL.
   Why: this is the link the whole feature hangs off, and the `issue:` block is
   the one that already solves URL-valued keys safely.
   Verify: `node tests/plugins/test-design-plan-link.mjs` passes all four
   assertions, including the identical-hash check.

5. Write `kit/plugins/plan-agent/hooks/build-designs-index.sh`, forked from
   `build-prototypes-index.sh` and retargeted to `docs/designs/`. Keep the same
   two run modes (hook payload on stdin, or a project root argument) and the same
   `exit 0` guarantee.
   Why: the prototypes generator already handles the path gating, the
   self-write skip, and the never-block contract; forking it keeps the two
   galleries behaving the same way.
   Verify: `bash tests/plugins/test-build-designs-index.sh` passes.

6. Write `kit/plugins/plan-agent/hooks/check-design-drift.py`. It reads the
   plan's `design-dir:`, lists `*.dc.html` artboard names in that directory,
   extracts the plan's **user-facing** step headings — applying the same filter
   step 8's derivation uses, so a version bump or a test-file step is never
   counted — and reports any user-facing step with no artboard covering it. No
   network calls, no read of the published canvas.
   Why: keeps the check inside the shared 55s dispatch budget, and keeps it
   silent when someone edits the canvas in the GUI.
   Verify: `bash tests/plugins/test-design-drift.sh` passes both the matched and
   diverged fixtures.

7. Add the `docs/designs/` gate to `kit/plugins/plan-agent/hooks/dispatch.py` — a
   `_DESIGNS_MARKER` constant, an `is_design` test alongside `is_prototype`, and
   a fan-out to the two new children sharing the existing deadline. Preserve the
   early `sys.exit(0)` for unrelated writes.
   Why: `dispatch.py` is the plugin's only registered hook; a child not wired
   here never runs.
   Verify: `python3 -c` a synthetic payload for a `docs/designs/x/Main.dc.html`
   write through `dispatch.py` and confirm both children ran; repeat with an
   unrelated path and confirm no child process spawned.

8. Write `kit/plugins/plan-agent/skills/design/SKILL.md`, structurally mirroring
   `skills/prototype/SKILL.md`: Step 0 exit plan mode; Step 1 resolve the input
   (plan path, raw idea, image, or Figma URL — the same input contract prototype
   already documents), warning in one line and proceeding when the resolved plan
   carries no UI signals; Step 2 derive one artboard per **user-facing** step,
   uncapped — a step with no user-facing surface produces no artboard; Step 3
   echo the artboard list back for confirmation; Step 4 delegate authoring and
   publishing to the built-in skill via `Skill(design)`, writing working files
   under `docs/designs/<plan-slug>/`; Step 5 write `design:` and `design-dir:`
   into the spec frontmatter and re-render; Step 6 index and report.
   Why: Steps 2 and 5 are the entire reason this skill exists — plan-aware
   artboards and the link-back. Everything else is delegation.
   Verify: `bash tests/plugins/test-build-skill.sh` and
   `bash tests/plugins/test-description-budget.sh` both pass.

9. Add the third batched question to `implementation-plan/SKILL.md` Step 8:
   "Want to see it before building?" with options `Prototype`, `Design canvas`,
   and `No`. Gate it on the `ui_signals_present` rule quoted from
   `skills/review-plan/SKILL.md:78`. It is a third question in the same
   `AskUserQuestion` call, never two more options — both existing option lists
   are already at the 4-option cap.
   Why: this is the moment the user asked for, and it is the first time the
   prototype skill is offered anywhere in the chain.
   Verify: `bash tests/plugins/test-exitplanmode-guard.sh` still passes, and a
   grep of the edited Step 8 shows three questions in one call with no option
   list longer than four.

10. Teach `skills/build/SKILL.md` Step 2 to read the artboards under a spec's
    `design-dir:` as the visual spec before implementing, when the key is
    present.
    Why: a design nobody implements against is decoration; this is the payoff
    step.
    Verify: grep `build/SKILL.md` for `design-dir` and confirm the instruction
    sits inside Step 2, before the implementation loop.

### Phase: VERIFY

11. Run the full suite: `bash tests/run-all.sh`.
    Why: the three new tests are auto-discovered by the runner's glob, so a
    naming mistake shows up here rather than in CI.
    Verify: the run reports zero failures and names all three new test files as
    executed.

12. Bump `plan-agent` to `9.5.0` in `.claude-plugin/marketplace.json`, regenerate
    the root Plugin Reference Table with `node scripts/build-readme-table.mjs`,
    and hand-write the `design` section in
    `kit/plugins/plan-agent/README.md` alongside the existing `prototype` section.
    Why: a touched plugin without a version bump fails the CI guard, and the
    root table is generated output that must never be hand-edited.
    Verify: `git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs`
    exits 0, and `git diff README.md` shows only generator-shaped changes.

13. Run the feature end to end on a **throwaway** UI plan, so no test canvas
    lands in the real plan history: author a scratch plan, take the `Design
    canvas` branch at Step 8, and confirm the canvas publishes, both frontmatter
    keys are written, the re-rendered plan carries the header link, and the
    designs gallery lists the new canvas. Then load the rendered plan in the
    browser and assert the anchor's resolved `href` and its computed text via
    `mcp__claude-in-chrome__javascript_tool`, reporting both measured values.
    Why: every prior step verifies a part; this is the only step that proves the
    whole path works for a person.
    Verify: paste the measured `href` and text content. A screenshot alone is not
    evidence.

## Tests

Tier 1 — This plan changes application code

- Objective: a plan and its design canvas reference each other, and the link
  survives rendering. File: `tests/plugins/test-design-plan-link.mjs`;
  Type: smoke; Asserts: a spec carrying `design:` and `design-dir:` renders the
  `plan-design` meta tag and a header anchor with non-empty text and the artifact
  URL as `href`; a spec without them renders neither; a `javascript:` value
  renders neither; both renderer copies hash identically;
  Run: `node tests/plugins/test-design-plan-link.mjs`
- Unit: the designs gallery generator. File:
  `tests/plugins/test-build-designs-index.sh`; Targets:
  `hooks/build-designs-index.sh`; Key cases: one card per canvas directory with
  escaped titles, self-written index skipped on re-run, exit 0 on a directory
  with no artboards.
- Unit: the drift check. File: `tests/plugins/test-design-drift.sh`; Targets:
  `hooks/check-design-drift.py`; Key cases: silent on a matched artboard/step
  fixture, silent on a housekeeping step that has no artboard by design, names
  the uncovered user-facing step on a diverged one.
- Integration: the whole plugin suite. File: `tests/run-all.sh`; Key cases: the
  three new tests are auto-discovered and pass alongside the existing 77.

## Acceptance Criteria

- [ ] A plan spec carrying `design:` and `design-dir:` renders a `plan-design`
      meta tag and a working "View design" header link
- [ ] A plan spec carrying neither renders neither, and a `javascript:` value
      renders neither
- [ ] Both copies of `build-plan-html.mjs` hash identically after the change
- [ ] `docs/designs/index.html` lists every published canvas, rebuilt
      automatically on a write under `docs/designs/`
- [ ] `check-design-drift.py` reports a plan step with no covering artboard, and
      stays silent when the canvas is edited in the GUI
- [ ] `/plan-agent:design <plan.html>` publishes a canvas and writes both keys
      back into the spec
- [ ] The skill contains no `.dc.html` format rules, no `seed-canvas.mjs`
      invocation, and no `contract:` version string
- [ ] Step 8 offers Prototype and Design canvas on a UI plan, and offers neither
      on a plan with no UI signals
- [ ] Step 8 still asks at most four options per question
- [ ] A step with no user-facing surface produces no artboard, and the drift
      check does not report it as uncovered
- [ ] `/plan-agent:design` on a plan with no UI signals warns in one line and
      still proceeds
- [ ] `build` reads the artboards under `design-dir:` before implementing
- [ ] `bash tests/run-all.sh` passes with zero failures
- [ ] `check-plugin-versions.mjs` exits 0 against `origin/main`

## Verification

Author a UI plan through `/plan-agent:implementation-plan`. At Step 8, confirm
the third question appears and take the `Design canvas` branch. Confirm the
built-in `design` skill runs, artboards land under `docs/designs/<slug>/`, and a
canvas Artifact URL comes back.

Reopen the re-rendered plan HTML. The header carries a "View design" link
pointing at that URL, and the page's `plan-design` meta tag holds the same value.
Open `docs/designs/index.html` and confirm the canvas appears as a card.

Add a fourth user-facing step to the plan spec and re-render. The drift check
reports that step as uncovered. Open the canvas, move an element, and save. The
drift check stays silent — that edit is the canvas working as intended.

Finally run `bash tests/run-all.sh` and
`git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs`. Both
exit clean.

## Next Steps

- Extend the copy-parity test to cover the renderer
  `tests/plugins/test-build-index-parity.mjs` guards three copies of
  `build-index.sh` but nothing guards the two copies of `build-plan-html.mjs`.
  This plan's objective test asserts it for our own change; a shared guard would
  cover every future change.
  ```text
  In the agentics repo, tests/plugins/test-build-index-parity.mjs asserts that
  three byte-identical copies of build-index.sh hash the same. scripts/build-plan-html.mjs
  and kit/plugins/plan-agent/scripts/build-plan-html.mjs are also byte-identical
  copies with nothing enforcing it. Extend the parity test (or add a sibling)
  to cover the renderer's copies too, naming the copy that drifted. Bump the
  plan-agent version if you touch anything under kit/plugins/plan-agent/.
  ```

- Link the designs gallery from the docs hub
  `setup-sites` scaffolds `docs/index.html` as a landing hub that already links
  the Plans and Prototypes galleries. Designs should join them.
  ```text
  In the agentics repo, kit/plugins/plan-agent/skills/setup-sites/ scaffolds a
  docs/index.html landing hub linking the Plans and Prototypes galleries. Add
  the Designs gallery (docs/designs/index.html) alongside them, matching how the
  Prototypes link is generated. Bump the plan-agent version in
  .claude-plugin/marketplace.json.
  ```

- Wish list: seed a prototype from a design canvas
  The built-in design skill can produce a clickable prototype, and
  `plan-agent:prototype` already accepts an image or a Figma URL as input.
  Accepting a canvas as a fourth input source would let one visual pass feed the
  other.
  ```text
  In the agentics repo, kit/plugins/plan-agent/skills/prototype/SKILL.md Step 1
  resolves four input kinds: plan path, raw idea, image path, and Figma URL.
  Investigate adding a fifth: a design canvas directory (docs/designs/<slug>/)
  whose .dc.html artboards would be read to infer the data model, the same way
  an image mockup is today. Report whether the artboard markup carries enough
  structure to derive an entity and fields, and recommend for or against.
  ```

## Resources

- `kit/plugins/plan-agent/skills/prototype/SKILL.md` — the structural template
  this skill mirrors, including the four-way input contract and the link-back step
- `kit/plugins/plan-agent/skills/review-plan/SKILL.md:78` — the canonical
  `ui_signals_present` definition the Step 8 gate reuses
- `scripts/build-plan-html.mjs:313` — the `prototype:` (path) and `issue:` (URL)
  frontmatter blocks; the `issue:` one is the model for `design:`
- `tests/plugins/test-prototype-plan-link.mjs` — the objective-test template,
  including how it drives the renderer from a temp directory
- `tests/plugins/test-build-index-parity.mjs` — why byte-identical script copies
  need a guard, written up from a real drift incident
