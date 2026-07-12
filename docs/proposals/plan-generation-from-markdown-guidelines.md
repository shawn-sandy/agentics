# Proposal: Guideline-Driven Plan Generation with Markdown as Source of Truth

**Status:** Proposed
**Created:** 2026-07-12
**Scope:** `plan-agent` plugin (`implementation-plan` skill and its downstream consumers)

## Problem

HTML implementation plans are static because the generation pipeline is template-driven end to end. The `implementation-plan` skill prescribes a fixed document: a mandatory section list in fixed order, exact markup contracts (element ids, class names, frozen strings), and a single 2,015-line `SKELETON.html` the agent copies and fills placeholder-by-placeholder. The agent has almost no latitude to shape a plan around what the user actually needs — a two-line dependency bump and a cross-cutting architecture change get the same document with the same sections. The `--template` flag admits this: `minimal`, `adr`, and `spike` are documented as "planned but not yet implemented" because adding a variant means authoring and maintaining another full HTML skeleton.

The same design is also expensive. Measured on the current repo (70 plans in `docs/plans/`):

| Cost | Measured | ~Tokens |
|------|----------|---------|
| `SKILL.md` loaded on activation | 76 KB (459 lines) | ~19k |
| `SKELETON.html` read into context per plan | 87 KB (2,015 lines) | ~22k |
| Average plan file written per plan | 84 KB (largest: 145 KB) | ~21k output |
| Boilerplate share of a real plan (CSS + JS + inline SVG) | 40–48% (~55 KB) | ~14k re-emitted per plan |

Every plan re-emits the same ~55 KB of CSS, JavaScript, and SVG icon sprite through the model's output channel. Every status flip, checkbox tick, or finalize pass then re-reads and edits that large HTML file. A single full-workflow plan run costs roughly **60k+ tokens of pure mechanics** (skill + skeleton + output) before any actual planning thought.

Finally, correctness is enforced by prose. Roughly half of `SKILL.md` is markup bookkeeping — escaping rules, placeholder wiring, frozen strings that downstream tools match byte-for-byte, meta-tag lists, "delete this block and its sidebar `<li>`" instructions. These are exactly the kinds of rules a model occasionally fumbles and a script never does.

## Insight: the repo already contains the answer, inverted

`scripts/lib/plan-spec.mjs` + `scripts/extract-plan-spec.mjs` already define a **markdown plan spec** (`## Objective`, `## Context`, `## Files`, `## Steps`, `## Tests`, `## Acceptance Criteria`, `## Verification`) and can derive it from any plan's DOM — 49 of 70 plans carry an embedded digest, and the read side handles the rest. A markdown `SKELETON.md` mirroring the structure also already exists. Today this machinery runs **HTML → markdown** (spec extraction for implementers). This proposal runs it the other way: **markdown → HTML**, and makes the markdown the artifact the agent authors.

## Proposal

Invert the pipeline into three cleanly separated layers:

### 1. Planning guidelines (markdown, replaces the prescriptive structure)

Replace the "Required Structure" rulebook with a small library of guideline documents under `kit/plugins/plan-agent/skills/implementation-plan/guidelines/`:

- **`planning-principles.md`** — industry best practices as *principles*, not markup: every plan makes "done" falsifiable; every step states what/why/how-to-verify; verification is end-to-end, not just per-step; risks and open questions are surfaced, not buried; scope is explicit (requested work vs. follow-ups vs. wish list).
- **`section-catalog.md`** — a menu of available sections with each section's *purpose* and *when it earns its place* (e.g. "include a comparison grid when the plan weighs a 2–3-way trade-off; otherwise omit"). The current Visual Components trigger table already has this shape — it moves here and becomes advisory.
- **`right-sizing.md`** — depth calibration: what a minimal chore plan looks like vs. a feature plan vs. an architecture/spike plan; when interview rounds, tests tiers, and visuals are warranted. This is where `minimal`/`adr`/`spike` finally ship — as guidance profiles, not HTML skeletons.
- **`writing-style.md`** — the existing tone/plain-language rules, moved out of the workflow doc.

The agent reads the guidelines and **decides** which sections to include, at what depth, with which visuals — per plan, based on the user's objective and context. A small **required core** stays mandatory because machines depend on it (see Compatibility): objective, steps, acceptance criteria, verification, status frontmatter. Everything else is judgment.

Guidelines load via progressive disclosure: `SKILL.md` keeps a one-paragraph summary of each and reads the full file only when relevant (e.g. `right-sizing.md` during scope classification), so a `--quick` run pays for less than a full-workflow run.

### 2. Markdown authoring (the agent writes ~5–10 KB, not ~85–145 KB)

The agent drafts the plan as structured markdown with YAML frontmatter — the plan-spec format `buildDigest` already emits, extended with frontmatter for the metadata that today lives in `<meta>` tags (`status`, `type`, `effort`, `created`, `repo`, `implement`, `goal`, `priority` — plus `workflow` and `issue`, which stay **conditional exactly as today**: `workflow` only when a workflow prompt was generated by flag or complexity heuristic, `issue` only for issue-seeded plans; the renderer emits their `<meta>` tags only when the keys are present and omits them otherwise). Step/criterion completion state is carried by markdown checkbox syntax (`- [ ]` / `- [x]`), which every consumer can flip with a one-line edit.

This markdown file is the **source of truth**, committed beside the HTML in `docs/plans/`. Today's "conversion mode" (`.md` → `.html`) stops being a special case and becomes the only path.

### 3. Deterministic rendering (a script owns style and layout)

A new `scripts/build-plan-html.mjs` (bundled with the plugin, shared with the repo's `scripts/lib/`) parses the markdown spec and emits the self-contained HTML plan. The template's job shrinks to exactly what the user asked for — **style and layout only**: the CSS, the JS behaviors (progress bar, copy buttons, `savePDF()`), the SVG sprite, the frozen strings, the meta tags, HTML escaping, the sidebar nav filtered to sections actually present.

- The ~55 KB of boilerplate is emitted by the script — **zero model output tokens**.
- Frozen strings (`step-chip`, `report-empty` sentence, `Pursue as goal`), escaping, and meta-tag completeness become mechanical guarantees instead of 200 lines of skill prose.
- Section handling is data-driven: known H2s map to their styled blocks; sections the agent chose to omit simply don't render (no "delete the block and its nav `<li>`" choreography); an unrecognized section renders as a generic styled card, so guideline-driven creativity can't break the renderer.
- `--template` becomes real: template variants are alternate CSS/layout shells consumed by the renderer, cheap to add because they contain no content logic.
- The renderer computes what's derivable: file-tree from step file references, effort level from step/file counts, implement and goal prompts from objective + path, progress counts. The workflow prompt is computed only when the spec asks for one (the `--workflow` flag or the complexity heuristic), preserving the conditional `plan-workflow` contract. More prose leaves `SKILL.md`.

The round-trip gives a free correctness oracle: `extractSections(render(spec))` must equal the parsed spec. That property test anchors the whole migration.

### Regeneration hook

A `PostToolUse` hook (same pattern as the existing `rebuild-plans-index.py`) re-renders `<plan>.html` whenever `<plan>.md` in a plans directory is written, keeping the pair fresh for the Pages gallery. The hook is **best-effort**, not a guarantee: PostToolUse hooks are non-blocking, so a renderer failure could leave the HTML stale while the Markdown write succeeds. Two mitigations are therefore part of the design: on renderer failure the hook exits non-zero with the error on stderr so the failure surfaces in the session instead of passing silently, and a **parity check** (`render(md) == committed html`) runs in the plugin test suite and the publish pipeline, failing on any stale pair. Manual tampering with the HTML is caught by the same check.

## Token impact

| Flow | Today | Proposed | Reduction |
|------|-------|----------|-----------|
| Plan creation output | ~21k tokens (85–145 KB HTML) | ~2–3k tokens (5–10 KB md) + one Bash render call | **~85–90%** |
| Skeleton read | ~22k tokens | 0 (renderer owns it); guidelines ~2–4k, loaded selectively | **~85%** |
| `SKILL.md` on activation | ~19k tokens | Markup/bookkeeping prose moves into the renderer and guidelines; realistic target ≤6k | **~65%** |
| Status/checkbox edits, finalize | Read + edit 84 KB HTML | Flip `- [ ]`/frontmatter in small md, re-render via script | large, proportional |
| Implementer reading a plan | 84 KB HTML or `extract-plan-spec.mjs` | read the md directly | tooling optional |

Rough end-to-end: a full plan run drops from ~60k+ mechanical tokens to ~10–15k.

## Compatibility and migration

Downstream consumers pin the current HTML contract: `finalize-plan` (literal find/replace on `step-chip` markup and the `report-empty` sentence), the plans-gallery index hooks (meta tags, title), `plan-spec.mjs` (`#objective`, `.step-card`, `#criteria-list`, `#verification` DOM), and the smoke tests in `tests/plugins/`. The renderer therefore **emits the exact same DOM contract** — same ids, classes, meta tags, frozen strings — so phase 1 breaks nothing.

**Phase 1 — Renderer.** Build `build-plan-html.mjs` + round-trip property tests against a sample of the 70 existing plans (render(extract(html)) must re-extract identically). Ship the regeneration hook.

**Phase 2 — Guidelines + skill rewrite.** Author the guidelines library; rewrite `implementation-plan` `SKILL.md` around: explore → read guidelines → decide structure → author md → render → deliver. Workflow steps 0–8 (issue ingestion, clarify, align, interview, tests, status gates, delivery, next-action menu) survive intact — they orchestrate *content*, which is unchanged; only the authoring/output medium changes.

**Phase 3 — Consumers go md-first.** Point `finalize-plan` and the status/checkbox gates at the markdown (checkbox flips + frontmatter edits + re-render) instead of HTML attribute surgery. The byte-for-byte frozen-string contracts retire once nothing reads them; the gallery keeps reading meta tags from rendered HTML unchanged.

**Phase 4 (optional) — Backfill.** `extract-plan-spec.mjs` already derives the spec from any legacy plan, so existing plans can be backfilled with md sources in bulk — the same guarded-batch pattern as `backfill-plan-digests.mjs`. Until then, read-side tools keep their existing dual-path (embedded digest / DOM-derive) behavior; legacy plans need no changes.

## Risks

- **Dual-file drift** — md edited without re-render, or the best-effort hook fails silently. Mitigated by the hook surfacing renderer errors (non-zero exit, stderr) plus the render-parity check in the test suite and publish pipeline that fails on stale pairs; worst case the HTML is one render behind, and the md is authoritative.
- **Renderer becomes a second skeleton to maintain** — true, but it's *one* place, testable, and versioned; today the same knowledge is smeared across a 2,015-line skeleton, 459 lines of skill prose, and every generated plan.
- **Agent-decided structure under-includes** — a guideline-driven agent might omit a section a reader wanted. The required core + the interview/review flows (unchanged) are the backstop; `review-plan`'s completeness reviewer already audits for this.
- **Interactive checkbox round-trip** — a user ticking a criterion in the browser still doesn't write to disk today (attributes are edited by tools, not the page); that flow is unchanged, but tools must now edit the md, not the HTML. Phase 3 covers every in-repo writer; external scripts that patched plan HTML directly would need updating.

## Out of scope

- Changing the gallery/index, GitHub Pages deploy, or `plans-open`/`plans-library` — they consume rendered HTML and keep working.
- The `prototype`, `review-plan`, and `build-proposal` skills — they reference plans by path and are unaffected; `review-plan` could later read the md for its own token savings.
- Retiring the HTML output. HTML remains the *presentation* deliverable (gallery, PDF export, interactive progress); it just stops being the thing the model types out.
