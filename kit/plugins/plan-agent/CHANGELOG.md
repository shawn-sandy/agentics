# Changelog

## 2.22.1 — Per-skill model pinning (2026-07-13)

### Changed

- **Model frontmatter across skills and the background review agent** — reasoning-heavy skills now pin their model for the invocation turn: `implementation-plan` and `build-proposal` run on `claude-fable-5`; `review-plan`, `refine-prompt`, and `prototype` run on `opus`; `finalize-plan` runs on `sonnet`. The `agent-review-plan` background agent moves from `sonnet` to `opus` to match the foreground review path's synthesis step. The seven `plan-reviewer-*` agents stay on `sonnet`, and mechanical skills (`plans-library`, `plans-open`, `setup-sites`) inherit the session model. The override is turn-scoped and falls back to the session model if an org `availableModels` allowlist excludes the pinned model.

## 2.22.0 — Optional tracking-issue creation at the end of every plan (2026-07-13)

### Added

- **Step 8 tracking-issue question** — the end-of-plan `AskUserQuestion` now batches a second question: "Create a tracking issue for this plan on GitHub/GitLab?" Choosing yes invokes `git-agent:create-issue` with the new `plan <spec path>` source, which drafts the issue from the plan's objective, steps, and acceptance criteria behind its own confirmation gate. The created issue URL is recorded as the spec's `issue:` frontmatter key (the same key issue-seeded plans already carry) and the HTML is re-rendered. If the `git-agent` plugin is not installed, the skill notes it in one line and continues — issue creation never blocks the plan flow. The question is skipped entirely when the spec already carries an `issue:` key (issue-seeded plans, or a repeat pass through the menu) to avoid duplicating the backlog item and overwriting the existing link.

## 2.21.0 — Prompts reference the Markdown spec; Next Steps renders again (2026-07-13)

### Changed

- **Implement/goal/workflow prompts reference the `.md` spec, not the rendered HTML** — the derived prompts (`plan-implement`, `plan-goal`, `plan-workflow` meta tags plus their visible rows) now point at the plan's Markdown spec path. An implementing agent reads the ~5–10 KB spec instead of the 60–120 KB rendered page (~90% fewer tokens per read; the workflow prompt briefs *every* subagent with the file, so the saving multiplies), and lands progress where it lives. The renderer CLI passes the real spec path; `renderPlanHtml()` accepts an `mdPath` option and falls back to `planPath` with `.html` swapped for `.md`.
- **Copy-button prompt walks the markdown-first loop** — `buildImplementPrompt()` now instructs: read the spec (the HTML is a rendered view), tick `[x]` step markers and `- [x]` criteria bullets in the spec, set `status: completed` in the frontmatter, then re-render the sibling HTML so it shows every step and criterion complete — never hand-edit the HTML. This replaces the pre-markdown-first instructions that told agents to "mark it done in the plan" against the HTML file.

### Added

- **`## Next Steps` renders into the HTML plan again** — the section legacy hand-written plans carried (and the markdown-first renderer skipped) is back: each top-level `- ` bullet renders as a collapsible `details.next-step-item` card (summary line, optional description, paste-ready prompt in a `<pre>` with a `copyPrompt()` Copy-prompt button — the exact legacy markup, whose CSS/JS never left the shell); bullet-less content renders as paragraphs. Parsed by `parseSpecMarkdown()` into a `nextSteps` key kept beside `sections` (like `progress`) so the extract → digest → parse round trip stays byte-stable. Sidebar nav gains a filtered "Next steps" entry.
- **`plan-md` meta tag + Spec drawer row** — rendered plans expose the spec path as `<meta name="plan-md">` and a third Spec row (`id="plan-md"`) in the More-ways drawer's plan-source block.
- **Docs** — `section-catalog.md` gains a `## Next Steps` catalog entry (syntax + example) and drops it from the markdown-only group; `SKELETON.md` shows the bullet/fence syntax; SKILL.md documents the spec-path prompts, the `plan-md` meta tag, and the Next Steps cards.

## 2.20.0 — Markdown-first status and checkbox flows (Phase 3) (2026-07-12)

### Added

- **Progress state in the plan spec** — `parseSpecMarkdown()` now reads completion state from checkbox syntax and returns it as a separate `progress` key (content `sections` stay byte-stable, so the extract → digest → parse round-trip is untouched): `- [x]` / `- [ ]` bullets under `## Acceptance Criteria` carry per-criterion state (plain `- ` bullets parse as unchecked), an optional `[x]` marker after a step number (`3. [x] <action> Why: … Verify: …`) carries per-step state, and a new optional `## Completion Report` lifecycle section (`- <item> — <reason>` bullets) carries close-out findings.
- **Renderer derives all completion markup** — `build-plan-html.mjs` renders checked criteria inputs, completed step cards with `done` chips, a server-rendered initial progress bar (label, width, `aria-valuenow`), the completion checklist (cc1–cc3 `checked` plus the `all-complete` class, from all-steps-done + all-criteria-done + `status: completed`), and the `dl.report-list` Completion Report — the exact markup `finalize-plan` used to write by hand.

### Changed

- **`finalize-plan` goes md-first** — when the plan has a sibling `<stem>.md` spec, all completion writes are Markdown edits (frontmatter `status`, criteria checkbox flips per the user's choice, step `[x]` markers, a `## Completion Report` section for unverified criteria / evidence gaps / objective-test failures) followed by an explicit re-render via `build-plan-html.mjs`; it also reconciles transition-window drift (criteria checked in the HTML before this release are flipped into the spec). Accepts `.md` plan arguments alongside `.html`. Legacy plans without a spec keep the direct HTML attribute edits.
- **`implementation-plan` status gates edit the spec** — Step 6 and the Step 8 implement-now gates flip step/criterion state in the spec markdown and re-render instead of editing `checked` attributes, `.step-card` classes, and status attributes in the HTML; re-rendering is now lossless (progress re-renders from the spec), so the "re-rendering resets HTML progress state" caveat is gone. The completion-checklist gate verifies spec state and lets the renderer derive cc1–cc3/`all-complete`; gaps are recorded as `## Completion Report` bullets.
- **Frozen-string contracts retired** — nothing matches the `todo` step chip, the "No items to report — all requirements met." sentence, or the "Pursue as goal" label byte-for-byte anymore, so the exported `STEP_CHIP`/`STEP_CHIP_DONE`/`NO_ITEMS_REPORT`/`GOAL_LABEL` constants in `plan-shell.mjs` are demoted to internal presentation strings and the byte-for-byte test pin is replaced by behavioral progress-state assertions. The gallery keeps reading `plan-*` meta tags from rendered HTML unchanged.
- **`section-catalog.md` documents the state syntax** — checkbox bullets for Acceptance Criteria, the step `[x]` marker, and the `## Completion Report` lifecycle section; `SKELETON.md` starts criteria as `- [ ]` bullets.

## 2.19.0 — Guideline-driven plan authoring (Phase 2) (2026-07-12)

### Added

- **`skills/implementation-plan/guidelines/` library** — four guideline documents replacing the prescriptive markup rulebook, loaded via progressive disclosure (SKILL.md keeps a one-paragraph summary of each; the full file is read only when the step calls for it): `planning-principles.md` (falsifiable "done", what/why/verify per step, end-to-end verification, surfaced risks, explicit scope), `section-catalog.md` (each spec section's purpose, when it earns its place, and the exact syntax `build-plan-html.mjs` parses, plus the frontmatter key table), `right-sizing.md` (minimal / standard / deep depth profiles with a calibration table — where the `minimal`/`adr`/`spike` intent ships as guidance instead of extra HTML skeletons), and `writing-style.md` (tone, plain language, objective-vs-glance — moved out of the workflow doc).

### Changed

- **`SKILL.md` rewritten around the markdown-spec pipeline** — the agent now authors a ~5–10 KB Markdown plan spec (the source of truth, committed beside the HTML) and renders it with the bundled `scripts/build-plan-html.mjs`; the agent decides which optional sections a plan includes, at what depth, per the guidelines. Workflow Steps 0–8 (issue ingestion, explore, clarify, align, interview, tests, status gates, delivery, next-action menu) survive intact; a new Step 5d runs the renderer, and Step 8's "Edit the plan" edits the spec and re-renders instead of patching HTML. The Required Structure, HTML Output Requirements, Visual Components, Frozen Strings, File-Tree Auto-Generation, and skeleton-copying prose is gone — the renderer owns all of it mechanically. SKILL.md drops from 76 KB to ~26 KB.
- **`reference/SKELETON.md` is now the spec starter** — rewritten to the exact format `parseSpecMarkdown()` accepts (frontmatter keys, `# Plan:` title, `Why:`/`Verify:` step markers, `- path (badge) — note` file entries, tier line + test bullets), replacing the old humanized-headings fallback. `reference/SKELETON.html` remains for reference and its smoke tests but is no longer copied by the skill.
- **`--priority` and issue URLs land in the spec, not meta tags** — `priority:` and `issue:` are written as spec frontmatter keys (preserved in the markdown, not yet rendered as `plan-priority`/`plan-issue` meta tags); the seeding issue is also cited in the Context section. `planAgent.extraFrontmatter` pairs likewise go to spec frontmatter instead of extra `<meta>` tags.
- **Tests updated for the pipeline** — `test-goal-prompt.sh` asserts SKILL.md documents the derived goal-prompt contract (format + `plan-goal` meta + `copyGoal(this)`) rather than a `{goal-prompt}` placeholder; `test-resources-section.sh` asserts the Resources guidance lives in `guidelines/section-catalog.md` and the spec skeleton.

## 2.18.0 — Markdown-spec-to-HTML plan renderer (2026-07-12)

### Added

- **`scripts/build-plan-html.mjs` renderer CLI** (repo-level) — `node scripts/build-plan-html.mjs <spec.md> [-o <plan.html>]` renders a small Markdown plan spec into the full styled HTML plan, reproducing today's DOM contract (all `plan-*` meta tags, `#objective`, the implement row and more-ways drawer, `#steps` step cards, `#tests`, `#criteria-list`, `#verification`, the completion checklist) with all spec text HTML-escaped. Derived fields are computed, never authored: the implement/goal/workflow prompts, the effort level (same Low/Medium/High thresholds the skill uses), the file-tree markup, the criteria count, and a sidebar nav filtered to the sections present.
- **`parseSpecMarkdown()` in `scripts/lib/plan-spec.mjs`** — the inverse of `buildDigest()`: parses a spec (optional YAML frontmatter for metadata, then title/Objective/Context/Files/Steps with Why:/Verify:/Tests/Acceptance Criteria/Verification) into the same sections object `extractSections()` returns, so the extractor and renderer cannot drift apart.
- **`scripts/lib/plan-shell.mjs` presentation shell** — the SKELETON.html CSS, icon sprite, JavaScript behaviours, and frozen strings (`todo` step chip, "No items to report — all requirements met.", "Pursue as goal — optimize for the outcome") extracted into exported template functions holding style and layout only, never plan content.
- **`hooks/render-plan-html.py` regeneration hook** — PostToolUse on Write|Edit|MultiEdit: when a `# Plan:` Markdown spec inside the resolved plans directory is written, the sibling `.html` is re-rendered via `build-plan-html.mjs` — preferring the copy bundled with the plugin (`$CLAUDE_PLUGIN_ROOT/scripts/`), falling back to the consumer project's `scripts/build-plan-html.mjs`, and silently skipping when neither exists. Resolves `plansDirectory` with the skill's full settings precedence (project `.claude/settings.local.json`, then project `.claude/settings.json`, then global `~/.claude/settings.json`, falling back to `docs/plans/`), and exits non-zero with the error on stderr when the renderer fails. After a successful render it rebuilds the plans gallery index best-effort, since the index hook skipped the `.md` write and a subprocess-written `.html` is not a tool event.
- **Bundled renderer** — `scripts/build-plan-html.mjs` plus `scripts/lib/plan-spec.mjs` and `scripts/lib/plan-shell.mjs` ship inside the plugin (byte-identical copies of the repo-root sources, pinned by a parity test) so normal marketplace installs get a working hook without vendoring the development repo.
- **`tests/plugins/test-build-plan-html.mjs`** — unit cases for `parseSpecMarkdown()`, CLI and hook integration cases, and the round-trip property: every committed plan in `docs/plans/` whose sections extract cleanly must survive extract → digest → parse → render → re-extract with a deep-equal sections object (59 plans at introduction; ≥10 required), plus frozen-string and zero-unfilled-placeholder assertions.

### Changed

- **Reduced-motion coverage in `reference/SKELETON.html` (and the extracted shell)** — `prefers-reduced-motion: reduce` now also disables smooth scrolling and the in-progress status-badge pulse, matching the reduced-motion handling the other animated elements already had.

## 2.17.0 — Humanized implementation-plan output (2026-07-09)

### Added

- **"At a glance" plain-language summary block** — generated plans now open with a short, jargon-free summary of what the plan does and why, rendered from a new `{at-a-glance}` placeholder as a `.plan-glance` block placed as a sibling immediately after `div#objective` (never nested inside it, so `extract-plan-spec.mjs` output stays pure). Written for a reader who was not in the planning session; the technical Objective remains unchanged.
- **"More ways to run this plan" drawer** — the secondary prompt rows are regrouped into a collapsed `details.plan-more-ways` drawer so **Implement** is the single visible action in the prompts area; the goal and workflow prompts and the plan-source File/Path rows live inside the drawer and expand on demand. All existing prompt ids, classes, and copy buttons are unchanged — this is purely a regrouping.
- **SKILL.md authoring rules + frozen-strings contract** — new writing guidance (sentence-case human headings, a one-line plain-language intro under each section heading, audience-first phrasing) plus an explicit contract listing the byte-for-byte strings and machine-readable hooks (ids, classes, `plan-*` meta tags, "Pursue as goal", `todo`/`done` step chips, the "No items to report — all requirements met." sentence) that generators must never alter.
- **`tests/plugins/test-humanized-skeleton.sh`** — smoke test pinning the humanized skeleton: presence of the at-a-glance block, the collapsed more-ways drawer, sentence-case headings, and all frozen strings/contract selectors.

### Changed

- **Section headings and intros humanized** — `reference/SKELETON.html` headings moved to sentence case with a one-line intro under each, and the markdown fallback `reference/SKELETON.md` was mirrored to the same humanized headings ("At a glance", "Definition of done", "Final check") — the markdown skeleton remains the lighter fallback and does not gain the HTML-only sections (Tests, Completion checklist, drawer).
- Minor bump rationale: the output format changed, but nothing was removed or renamed — all machine contracts (ids, classes, `plan-*` meta tags) consumed by the gallery, hooks, finalize-plan, and extract-plan-spec remain unchanged.

## 2.16.0 — Resources section in implementation plans (2026-07-09)

### Added

- **New opt-in Resources section in `implementation-plan` plans** — HTML plans can now embed the images, screenshots, and reference links used to create the plan, so readers can *illustrate* what the work is about and *verify* the implementation against the same material. Rendered as `section.card-resources#resources` (new `#ic-photo` icon) between Context and Files, with a `.resource-grid` of `.resource-figure` image cards (mandatory `alt` text + source-crediting `<figcaption>`) and a `.resource-links` list (each link paired with a `.resource-note`). Ships behind a removal comment like the other opt-in visuals — kept and filled only when the plan was informed by screenshots, mockups, diagrams, external docs, or a seeding issue; otherwise the section and its sidebar nav link are deleted.
- **`reference/SKELETON.html`** — added the `#ic-photo` symbol, `.resource-grid` / `.resource-figure` / `.resource-links` styles, the opt-in `#resources` section markup with fill templates, and the `#resources` sidebar nav link (auto-handled by the existing scroll-spy).
- **`SKILL.md`** — documented the section under Required Structure, HTML Output Requirements, and the Visual Components table, added a **Resources Capture** guide (when to capture, image portability/no-CDN rules, accessibility, HTML-escaping), and wired capture reminders into Step 0b Explore and Step 1 Clarify. The markdown fallback `reference/SKELETON.md` gained an optional `## Resources` section.

## 2.15.0 — Standalone Artifacts gallery (2026-07-08)

### Added

- **New `hooks/build-artifacts-index.sh` publisher** — copies every HTML file from the local inbox `.claude/artifacts/` into the deployed `docs/artifacts/` tree and builds `docs/artifacts/index.html`, a standalone Artifacts gallery reusing the shared `plans-gallery.html` template. Artifacts now have their own first-class section on the docs hub, separate from implementation plans.
- **`{{GALLERY_TITLE}}` placeholder in `templates/plans-gallery.html`** — the title and `<h1>` are now parametrized so the same template renders both the "Plans" and "Artifacts" galleries. `build-index.sh` substitutes `Plans`; `build-artifacts-index.sh` substitutes `Artifacts`.

### Changed

- **`build-index.sh` no longer renders artifacts.** The plans gallery is plans-only again: the `_is_artifact` / `_artifact_created` special-casing was removed and the `os.walk` prune now also skips an `artifacts/` subdirectory, so a stray `docs/plans/artifacts/` can never leak back into the plans list.
- **Template discovery prefers a project-local template.** `find_templates_dir` in both generators now prefers a `kit/plugins/plan-agent/templates` under the project root over the installed plugin cache, so a repo that vendors plan-agent renders its galleries from its own (authoritative) template.
- **Vendored plan builders kept in sync.** `scripts/build-plans-index.sh` (used by the `regen-plans.yml` CI workflow) and `docs/plans/build-index.sh` (the rebuild-hook fallback) are byte-for-byte copies of the hook; both were updated in lockstep so an automatic regeneration substitutes `{{GALLERY_TITLE}}` and never commits a gallery with the literal token.

### Fixed

- **`build-artifacts-index.sh` builds the gallery from the published tree, not just the inbox.** The inbox (`.claude/artifacts/`) is gitignored, so on a clean checkout it is empty; the publisher now renders cards from every artifact under `docs/artifacts/` (the committed set) after copying in any new inbox files, so saving a new artifact no longer unlinks already-published ones.

## 2.14.2 — Fix plans-gallery CSS regression (2026-07-07)

### Fixed

- **Restored the `prefers-reduced-motion: reduce` override in `templates/plans-gallery.html`** — the 2.14.1 template had reverted to an older variant that dropped the block, so every `plans-library` / `save-artifact` / index-hook rebuild silently removed it from `docs/plans/index.html`. Users requesting reduced motion no longer get smooth scrolling and transitions forced on them.
- **Fixed a sub-pixel `letter-spacing` typo on `.filter-chip`** — the reverted template emitted `letter-spacing: .04px` (effectively zero) instead of `0.04em`. Restored the `em` unit so filter chips render with their intended tracking.
- Both regressions came from `plans-gallery.html` drifting to a pre-Prettier 4-space variant that no longer matched the committed `docs/plans/index.html`; the template is now realigned so regenerating the gallery reproduces the committed output instead of downgrading it.

## 2.14.1 — Default plan-implementation model set to Fable (2026-07-07)

### Changed

- **`implementation-plan` now runs on Fable by default** — the skill's `model:` frontmatter changed from `opus` to `fable`. Both the `/plan-agent:implementation-plan` command and ambient model-invocation now generate plans with Fable unless overridden.

## 2.14.0 — Show saved artifacts in the plans gallery (2026-07-03)

### Added

- **Plans gallery now lists saved artifacts** — both gallery generators surface `.html` files in the plans directory's `artifacts/` subfolder (where `save-artifact` writes) as cards under a new **Artifact** type filter:
  - `plans-library` skill (manual `/plan-agent:plans-library`) scans `artifacts/` and renders artifact cards.
  - `build-index.sh` hook (auto-rebuild on every plan Write/Edit) classifies files under `artifacts/` as `type=artifact` instead of default `todo`/`untyped` plan cards, so the auto-generated gallery matches the new filter and does not misfile artifacts.
  - Artifacts carry no plan metadata, so cards show only a title, an `artifact` type chip, and the date parsed from the `<base>-YYYY-MM-DD.html` filename — no status/effort chips. Artifact links are prefixed with `artifacts/` (the subdirectory), and artifacts sort after plans, newest-first. Reuses the existing type-filter/search/count machinery (one CSS rule + one chip in `plans-gallery.html`).
- **Gallery count/copy reworded "plans" → "items"** in `plans-gallery.html` (header, footer, no-results, live count) since the gallery now mixes plans and artifacts.
- **`plans-library` no longer reports an empty library for artifact-only projects** — the Step 1 empty-state check now also considers `artifacts/`, so a project with saved artifacts but no top-level plans still builds a gallery.

## 2.13.1 — Trim finalize-plan skill description to budget (2026-07-02)

### Fixed

- **finalize-plan `description` frontmatter back under the 200-char budget** — the 2.13.0 description ran 207 chars, exceeding the three-part skill-description budget in `.claude/rules/plugin-patterns.md` (CodeRabbit nit on PR #366). Tightened the capability sentence ("ticks acceptance criteria; --all sweeps done-but-unmarked plans") to 188 chars while keeping all three parts: short label, capability including the `--all` sweep, and the `/plan-agent:finalize-plan` trigger. No behavior change.

## 2.13.0 — `--all` sweep flag on finalize-plan (2026-07-02)

### Added

- **Sweep mode for finalize-plan** — `/plan-agent:finalize-plan --all` finds plans that are implemented but never marked completed. Discovery selects files carrying a `<meta name="plan-status">` tag valued `todo` or `in-progress` across the plans directory (excluding `index.html` and `archive/`; non-plan HTML without the tag is never a candidate), then a cheap, non-interactive token-evidence pass scores each candidate (token-less plans score 0% instead of prompting); plans at 80%+ evidence are flagged as "done but not marked". A single two-question `AskUserQuestion` (multi-select plan picker + one criteria mode for the whole batch) replaces the per-plan confirmation, and the expensive per-criterion verification and objective-verification test run only on the selected plans before the status writes. All updated files are delivered in one `SendUserFile` call with a per-plan summary. `tests/plugins/test-finalize-all-flag.sh` pins the flag to the SKILL.md contract, README docs, and marketplace version.

## 2.12.2 — Fix invalid file-tree nesting in generated plans (2026-07-01)

### Fixed

- **Nested directory list is now a child of its directory `<li>`** — the implementation-plan File-Tree Auto-Generation instructions told the generator to emit a `<li class="file-dir">` heading *followed by* a sibling `<ul class="file-list">`, making the inner `ul` a direct child of the outer `ul` (invalid HTML — a `ul` may only contain `li` children; flagged by Copilot on PR #364). `SKILL.md`'s Grouping prose and Rendering pattern, plus the skeleton's row-template comment, now place the nested `ul` inside the directory `li`, and the skeleton CSS gains `.file-list li.file-dir > ul { flex-basis: 100%; }` so the nested list renders on its own row inside the flex `li`. Matches the hand-fixed markup in `docs/plans/add-dynamic-depth-and-mode-to-refine-prompt.html` (commit 371f812).

## 2.12.1 — Fix double-escaped titles in the plans gallery index (2026-07-01)

### Fixed

- **Idempotent title escaping in the gallery generator** — `hooks/build-index.sh` (and its vendored copy `scripts/build-plans-index.sh`) extracted card titles from each plan's `<title>` tag as already-encoded HTML and escaped them again on render, so titles containing entities (e.g. `&amp;`) came out as `&amp;amp;` on every regeneration (regressed in PR #362, previously hand-fixed in PR #241). `get_title` now unescapes on extraction so the pipeline holds plain text and `e()` escapes exactly once — regeneration is idempotent.

## 2.12.0 — Effort badge and filter in the plans gallery (2026-06-30)

### Added

- **Effort badge on plan cards** — the `plans-library` gallery now reads each plan's `<meta name="plan-effort">` tag and renders a colour-coded **Low / Medium / High** chip (green / amber / red) in the card badge row, alongside the existing status and type chips.
- **Effort filter** — a new **Effort** chip row (All / Low / Medium / High) joins the status and type filters in the toolbar. Plans with no `plan-effort` tag render with no badge and pass every effort filter, so older plans are never hidden. `plans-gallery.html` carries the new chip styles, filter row, and `data-effort` filter logic; `SKILL.md` Step 4 parses `plan-effort` and emits `data-effort` plus the conditional badge.

## 2.11.0 — Auto-derived effort level on plan HTML (2026-06-30)

### Added

- **Effort level on every plan** — the `implementation-plan` skeleton now renders an auto-derived **Low / Medium / High** effort level as a colour-coded header badge (green / amber / red), a chip in the meta row, and a `<meta name="plan-effort">` tag. The level is derived deterministically in Step 2 from the plan's step count, distinct files touched, and the Step 5b interview complexity tier — no flag, no author input. Colour is driven by a `data-effort` attribute on `<html>` (mirroring `data-status`), so it ships with zero new JavaScript. `SKILL.md` Step 2/3 and the HTML Output Requirements document the new field; `tests/test-effort-level.sh` asserts the skeleton carries the meta tag, the `.effort-badge` CSS variants, and the `data-effort` attribute.

## 2.10.1 — Portable checkbox state via HTML attributes (2026-06-30)

### Changed

- **Checkbox state now travels with the file** — the `implementation-plan` skeleton no longer persists acceptance-criteria ticks to `localStorage`. The `checked` attribute on each criterion `<input>` (and the `.completed` class on each `.step-card`) is the single portable source of truth, written into the file by the agent. A plan renders its true completion state on first paint on any machine, in any browser, and in git — no per-browser storage layer to diverge from. `SKILL.md` Step 6 and the Step 8 gates now instruct the agent to mark by adding the `checked` attribute and unmark by removing it, and the HTML Output Requirements forbid `localStorage` for checkbox state.

### Added

- **Portability smoke test** — `tests/test-checkbox-portability.sh` plus `tests/fixtures/checkbox-portability/fixture.html` assert the skeleton carries no browser-storage APIs and that the fixture's `checked` attributes and `.completed` class live in the file on disk.

## 2.10.0 — Prototype from images and Figma designs (2026-06-29)

### Added

- **Image & Figma inputs for `prototype`** — `/plan-agent:prototype` now accepts an image path (`.png`/`.jpg`/`.jpeg`/`.gif`/`.webp`/`.svg`) or a Figma URL in addition to a plan path or raw idea. For an image, the skill `Read`s the mockup/screenshot and infers the entity, fields (with types), action, and success signal from what the UI shows — no interview unless the image is ambiguous. For Figma, it loads the Figma MCP tools via `ToolSearch` (`get_screenshot` + `get_design_context`/`get_metadata`) and infers the model the same way; if no Figma MCP server is connected it asks the user to connect it or paste a screenshot rather than guessing from the URL. Steps 3–8 (derive model → write → index → preview) are unchanged.
- **Broader secret/PII scrub** — Step 7 now scrubs seed values from any external source (plan, image, or Figma), since mockups and screenshots frequently show real names, emails, and tokens.

## 2.9.0 — Static-HTML prototype generator (2026-06-29)

### Added

- **`prototype` skill** — `/plan-agent:prototype <plan.html | one-line idea>` (also model-invocable) turns a completed HTML plan or a raw idea into a runnable, framework-free static-HTML prototype under `docs/prototypes/`. The skill resolves the input (`.html` token → plan path; otherwise a raw idea that triggers a 3-question interview), derives a deterministic data model, echoes it back for confirmation, then fills a reusable skeleton. One self-contained file — inline CSS + vanilla JS, an inline JSON seed, and a per-prototype localStorage store — opens by double-click on `file://` and publishes to GitHub Pages.
- **Security & a11y baked into the skeleton** — `reference/PROTOTYPE-SKELETON.html` renders records via `textContent` (never `innerHTML`), HTML-escapes interpolated values at fill time, uses script-breakout-safe seed encoding, isolates storage per prototype via `{{STORE_KEY}}`, and ships labeled inputs, a semantic table, real buttons, visible focus, form validation, a confirm-guarded reset, an empty state, and an `aria-live` status region.
- **Prototypes gallery** — `hooks/build-prototypes-index.sh` (forked from `build-index.sh`) scans `docs/prototypes/*.html`, parses `proto-*` meta, and emits an escaped, newest-first `docs/prototypes/index.html` from `templates/prototypes-gallery.html`. A new `PostToolUse` hook entry auto-rebuilds it on prototype writes (scoped to `docs/prototypes/`, leaving the plans gallery untouched), and `docs/index.html` gains a Prototypes hub card.
- **Tests** — `tests/plugins/test-prototype-portability.sh` (objective smoke), `test-build-prototypes-index.sh` (gallery builder unit), and `test-prototype-persistence.mjs` (plain-Node store test with a localStorage shim, no jsdom), wired into `publish-dist.yml` by explicit path.

## 2.8.3 — Order plans gallery newest-first by created date, not mtime (2026-06-27)

### Fixed

- **Gallery ordering** — the plans gallery now sorts cards newest-first by each plan's `plan-created` metadata instead of filesystem modification time. A `git clone`/`checkout` resets every file's mtime to the same checkout time, so the previous `os.path.getmtime` sort in `docs/plans/build-index.sh` (and the `ls -t` step in the `plans-library` skill) produced an effectively random order. Both now sort by the embedded date descending (blank dates last, title ascending as a stable tiebreak).

## 2.8.2 — Persist plan checkbox state in HTML attributes, not localStorage (2026-06-23)

### Changed

- **HTML-attribute persistence** — the generated plan's acceptance-criteria checkboxes now persist their state in the document itself (the `checked` attribute on each `<input>`) instead of `localStorage`. The browser renders `checked` inputs natively on load, so the restore step is gone; toggling a box syncs the attribute, keeping the live DOM and any saved/committed copy of the file the single source of truth. This makes plan progress version-controllable and viewable identically across browsers, rather than living in per-browser `localStorage` invisible to git. Step completion (`.step-card.completed`) and the derived completion checklist were already DOM-backed and are unchanged.

## 2.8.1 — Standardize plans-directory resolution across all skills (2026-06-20)

### Fixed

- **Writer/reader directory mismatch** — `implementation-plan` resolved its output directory with vague prose ("the configured `plansDirectory` if set") that never named the read source or precedence and carried an extra "default Claude user plans folder" rung the reader skills lack. When a project set `plansDirectory` (e.g. `docs/planning`), it could write HTML to a different directory than `plans-library`/`plans-open` scan — so generated plans never appeared in the gallery.
- **`finalize-plan` latent bug** — `$PLANS_DIR` was used by the "most recent plan" search but never defined; it now resolves via the canonical snippet.

### Changed

- **One canonical resolution everywhere** — every plan-agent skill that resolves the plans (or proposals) directory now follows Claude Code's settings precedence: project-local `.claude/settings.local.json` → project `.claude/settings.json` → global `~/.claude/settings.json`, falling back to `${PWD}/docs/plans` (or `${PWD}/docs/proposals`). The vague-prose, project-only, and two-tier variants are gone, so the writer and every reader resolve the same directory. Touched: `implementation-plan`, `plans-library`, `plans-open`, `finalize-plan`, `build-proposal`, `setup-sites`, and the README artifact-dir description.
- **`setup-sites`** — updated the prose/comments describing the removed "Claude user plans folder (outside the repo)" fallback; the first plan now always lands in `${PWD}/docs/plans`.

## 2.8.0 — Compute-on-read plan spec extractor replaces the embedded digest (2026-06-20)

### Changed

- **Compute-on-read spec** — retired the embedded `#plan-digest` cache in favor of `scripts/extract-plan-spec.mjs`, which derives the spec from the visible plan DOM on demand. The visible DOM is now the single source of truth: no denormalized cache, no manual "refresh the digest" obligation, and no closing-script escaping contract on the write path. New plans embed nothing. Because each plan is a self-contained HTML file, the implement, goal, and workflow prompts it ships reference the plan **by path** (Claude reads the HTML directly) — no dependency on a repo-local script in the target repo, so generated plans work for any plugin user. The review team (`review-plan` SKILL, all seven reviewer briefs, and all seven `plan-reviewer-*` agent defs) reads via the extractor with a full-HTML fallback, and the `review-plan` "Pass 1b — Refresh the digest" pass is removed.
- **Backward compatible** — the extractor is embedded-first: legacy plans that still carry a `<script type="text/markdown" id="plan-digest">` block are read from it verbatim (un-guarded to clean markdown), so existing `docs/plans/*.html` are untouched. `scripts/backfill-plan-digests.mjs` is retained to re-seed legacy embedded plans.
- **Shared library** — the parse/build helpers (`hasDigest`, `decodeEntities`, `extractSections`, `buildDigest`, `guardScriptClose`, the new `unguardScriptClose`, and `readEmbeddedDigest`) moved to `scripts/lib/plan-spec.mjs`, shared by the write-side backfill and the read-side extractor.

### Added

- **`scripts/extract-plan-spec.mjs`** — CLI spec extractor: embedded-first, DOM-derive fallback; exits non-zero on missing/unparseable input.
- **`tests/plugins/test-extract-plan-spec.mjs`** — objective round-trip (embedded → un-guarded spec; digest-free → DOM-derived) plus unit coverage for resolution precedence, un-guarding without stopping early, the shared-lib import, and CLI exit codes.

### Caveat

- New plans embed no digest, so the old `awk '…id="plan-digest"…'` one-liner returns **empty** on them — use `node scripts/extract-plan-spec.mjs <plan>` instead.

### Notes

- `tests/plugins/test-plan-digest.sh` renamed to `tests/plugins/test-extractor-wiring.sh` and rewritten to assert extractor wiring; `tests/plugins/test-backfill-digest.mjs`'s real-corpus assertion scoped so committed digest-free plans don't fail the retained injector.

---

## 2.7.0 — setup-sites skill: scaffold GitHub Pages publishing into any repo (2026-06-18)

### Added

- **`setup-sites` skill** — `/plan-agent:setup-sites` (command **or** model-invocable) scaffolds the GitHub Pages deploy pipeline into the current repo so anything generated under `docs/` (plan galleries, social cards, any static HTML) reaches a public URL. It drops four idempotent artifacts — `.github/workflows/deploy-pages.yml` (SHA-pinned, path-filtered to `docs/**`), `docs/.nojekyll`, a parameterized landing hub `docs/index.html`, and `scripts/serve-docs.sh` for local preview — never clobbering files that already exist. The skill computes the live `https://<owner>.github.io/<repo>/` URL from the `origin` remote (handling user/org root sites), warns when `plansDirectory` points outside `docs/` (where Pages can't see it) and seeds `docs/plans/` (with a committed `.gitkeep`) when it's unset so the first generated plan lands inside `docs/` and deploys instead of falling back to the Claude user plans folder, prunes hub cards for galleries the repo doesn't use, and guides the one-time **Settings → Pages → Source → GitHub Actions** step (optionally via `gh` after confirmation). Closes the gap where the deploy pipeline existed only as hand-wired infrastructure in the agentics repo and could not be reused elsewhere.
- **Scaffold templates** — `templates/pages/{deploy-pages.yml,hub.html,serve-docs.sh}` ship the three file templates the skill copies; the hub carries `{{SITE_TITLE}}`/`{{SITE_TAGLINE}}`/`{{SITE_FOOTER}}` placeholders and `<!-- CARD:plans -->` / `<!-- CARD:social -->` prune markers.
- **Tests** — `tests/plugins/test-setup-sites.sh` guards the frontmatter contract, the three-part ≤200-char description, `allowed-tools`, body line count < 500, the seven-step workflow, all three templates (SHA-pinning + `.nojekyll` assertion + `docs/` upload in the workflow; card markers + placeholders + no absolute-root links in the hub), and a **dynamic** marketplace version check (plan-agent > `origin/main`).

---

## 2.6.0 — Outcome-driven goal prompt on every HTML plan (2026-06-18)

### Added

- **Goal prompt** — every generated plan now carries a third copy-paste prompt alongside the implement and workflow prompts: an *outcome-driven* prompt that frames the work as a goal to achieve (`Achieve this goal: … — use the plan as reference, but optimize for the outcome`) rather than steps to execute, giving the implementer latitude to deviate when a better path to the same outcome exists. Rendered as a collapsible `.plan-goal` `<details>` (purple accent) immediately below the implement row, mirrored in an always-present `<meta name="plan-goal">` tag, and computed in Step 2 from the same condensed objective + plan path + digest-extraction one-liner as the implement prompt. Unlike the workflow prompt it is **always present** — no flag, no complexity heuristic. Carries the same digest-extraction clause so the pursuing agent reads the spec digest, not the full ~21k styled HTML.

### Changed

- **`reference/SKELETON.html`** — adds the `.plan-goal` markup block, its CSS (reusing the existing `--purple` design tokens), the `copyGoal()` clipboard helper, and the `<meta name="plan-goal">` head tag. Hidden when `data-status="completed"` and suppressed in print, exactly like the implement and workflow rows.
- **`implementation-plan` SKILL.md** — Step 2 computes `{goal-prompt}`; Step 3 always emits the `plan-goal` meta tag; HTML Output Requirements list `plan-goal` among the always-present meta tags and document the always-present `.plan-goal` element.
- **Tests** — `tests/plugins/test-goal-prompt.sh` pins the goal prompt to the skeleton (meta tag, markup, `copyGoal()`, CSS, completed/print hiding) and the SKILL.md contract so the feature cannot silently regress.

---

## 2.5.1 — Backfill version + changelog for the #328 description optimization (2026-06-18)

### Changed

- **Skill descriptions optimized to the three-part ≤200-char format** — backfills the version bump and changelog entry that should have accompanied PR #328, which rewrote the `implementation-plan` and `refine-prompt` skill frontmatter `description:` fields to the canonical `[short ≤80 chars] [capability] Use when…` shape. No behavior change; metadata/discovery only.

---

## 2.5.0 — build-proposal skill: turn a vague idea into a decision-complete proposal (2026-06-18)

### Added

- **`build-proposal` skill** — `/plan-agent:build-proposal <idea>` (command **or** model-invocable) turns a half-formed idea into a decision-complete proposal. It codifies an 8-step research→decide→author loop (Frame → Fan out research → Synthesize core finding → Separate facts from decisions → Resolve decisions → Author artifact → Deepen → Converge & hand off), a **Tier 0/1/2 right-sizing gate** so small ideas never get a 10-section doc, and the canonical proposal-artifact shape. It writes a living `docs/proposals/<slug>.md` and stops at the planning handoff — the seam is "should-we + what" (build-proposal) vs. "how" (`implementation-plan`).
- **Artifact-dir resolver** — resolves the proposals directory `--dir` → `planAgent.proposalsDirectory` → `docs/proposals/` → default Claude user folder (mirroring how `implementation-plan` resolves `plansDirectory`) and `mkdir -p`s it at runtime. A committed `docs/proposals/.gitkeep` seeds the default root.
- **Ambient-activation discipline** — the three-part ≤200-char description triggers on idea / "should-we" / compare-and-align intent and shares **no trigger phrase** with `implementation-plan` (which owns "plan document / write a plan file"), so the two never collide on the model-invocation path.
- **References (progressive disclosure)** — `references/artifact-shape.md` (canonical section order + skeleton) and `references/operating-principles.md` (the ten operating principles + the relationship-to-existing-capabilities map, with `deep-research` wired as an **optional** delegate behind a WebSearch/WebFetch + Explore fallback — never a hard dependency).
- **Worked-example corpus** — two trimmed, real proposals ship flat under `references/` (`example-design-md-spec-alignment.md` — Tier 2; `example-proposal-builder-skill.md` — the recursive case), each stamped with its source URL + commit SHA/date as a built-in regression corpus.
- **Tests** — `tests/plugins/test-build-proposal.sh` guards the frontmatter contract, the three-part ≤200-char description, the no-trigger-overlap-with-implementation-plan rule, body line count < 500, reference + exemplar resolution, and a **dynamic** marketplace version check (plan-agent > `origin/main`, not a hardcoded 2.4.1).

---

## 2.4.1 — Responsive CSS retrofit for every HTML plan (2026-06-12)

### Added

- **`retrofit-responsive-plans.mjs`** — new idempotent injector (third in the `backfill-*.mjs` family alongside `backfill-plan-digests.mjs` and `backfill-save-pdf.mjs`) that wraps an 8-line responsive block as `<style id="plan-responsive-fix" data-version="1">` and inserts it immediately before `</head>` in existing `docs/plans/*.html`. Re-running is a no-op: plans already carrying the marked block are detected by id and skipped, so the script is safe to run repeatedly across the corpus. Supports `--dry-run` and `--dir` like its siblings.
- **`reference/SKELETON.html`** — the same responsive block is now embedded in the skeleton, so freshly generated plans are born responsive and never need a retrofit pass.
- **Tests** — `tests/plugins/test-responsive-retrofit.sh` stands guard over both halves: the injector's marked-block insertion and idempotency, and the skeleton shipping the block by default.

---

## 2.4.0 — Save as PDF button in every generated HTML plan (2026-06-12)

### Added

- **Save as PDF button** — `reference/SKELETON.html` now ships a `.save-pdf-btn` in the plan header between the title and the status badge. Clicking calls `savePDF()` → `window.print()`, opening the browser's native print dialog whose destination list includes "Save as PDF" on Chrome, Edge, Firefox, and Safari — no external dependencies. The button is hidden in `@media print` so it never appears in the exported PDF, honours `prefers-reduced-motion`, and carries an `aria-label` plus a visible focus ring.
- **Output contract** — the `implementation-plan` SKILL.md *HTML Output Requirements* now list the button as a required header element for both freshly drafted plans and markdown conversions, closing the gap where the feature shipped only in `plan-interview:markdown-to-html` (PR #272) while plans generated by this plugin's skeleton never received it.
- **Tests** — `tests/plugins/test-save-pdf.sh` pins the port: button placement between `.plan-title` and `.status-badge`, `type`/`onclick`/`aria-label` wiring, `savePDF()` calling `window.print()`, the `@media print` hide, the CSS class definition, and the SKILL.md contract.

---

## 2.3.0 — Machine-readable digest embedded in every HTML plan (2026-06-12)

### Added

- **`#plan-digest` block** — every generated plan now embeds a `<script type="text/markdown" id="plan-digest">` block as the first element child of `<body>`, holding a spec-only markdown rendition of the plan (objective, context, files, steps with why/verify, tests, acceptance criteria, verification). `type="text/markdown"` never renders or runs, so plans stay single self-contained files. Consumers read ~1–4k tokens of spec instead of ~21k tokens of styled HTML.
- **Digest contract** — new *Machine-Readable Digest* section in the `implementation-plan` SKILL.md: spec-only field list, explicit exclusions (status, checkbox, and progress state never enter the digest), an escaping contract (plain markdown, entities decoded, literal closing-script sequences guarded as `<\/script`), and the canonical flag-and-exit awk extractor. The extractor's opening rule is first-match-only (`!f`) so digest bodies that quote the opening tag are extracted intact — the failure mode was discovered by extracting this feature's own plan, whose objective quotes the tag.
- **Digest-first prompts** — the generated implement and workflow prompts now carry the extraction one-liner (`Start from the embedded digest: …` / `Brief subagents with the embedded digest: …`), and the skeleton's `buildImplementPrompt()` instruction list opens with the digest read plus a full-HTML fallback.
- **Digest-only reviewers** — all 7 `review-plan` reviewer briefs (`references/role-prompts.md`) and agent definitions now read the digest instead of the full HTML, with an explicit full-HTML fallback for plans that have no digest yet. The lead still reads the full HTML for Step 3b UI-signal scanning and Step 7 selector edits, and Step 7 gains a *Pass 1b — Refresh the digest* that regenerates the block after inline edits (update-in-place mode only).
- **Backfill script** — `scripts/backfill-plan-digests.mjs` injects digests into existing `docs/plans/*.html` (idempotent, insertion-only, `--dry-run`, `--dir`). Plans that cannot be fully parsed are skipped and reported — no partial digests. Backfilled 41 of 53 plans (including the markdown-conversion plan that landed via the 2.2.0 merge); the 11 reported skips are 8 `*-review.html` artifacts and 3 pre-skeleton-era plans, plus 1 plan that already carried a digest. A real-corpus test asserts the checked-in tree never ships a parseable plan without a digest.
- **Tests** — `tests/plugins/test-plan-digest.sh` (skeleton first-element-child assert, extraction edge cases including self-quoting digests, prompt clauses, reviewer briefs/defs, Step 7 refresh) and `tests/plugins/test-backfill-digest.mjs` (unit coverage for `hasDigest`/`guardScriptClose`/`extractSections`/`buildDigest` plus synthetic- and real-corpus integration with byte-preservation and idempotency asserts).

---

## 2.2.0 — Markdown plan conversion for implementation-plan (2026-06-12)

### Added

- **`$MD_SOURCE` detection** — `/plan-agent:implementation-plan <plan.md>` now recognizes a `.md` first token as a markdown plan source and enters conversion mode: the markdown file is the authoritative content for a new HTML implementation plan. Resolution tries the path as given, then the plan roots by basename, then the default branch (`git fetch` + fast-forward or `git show`) before falling back to an `AskUserQuestion` — the skill never invents content and presents it as a conversion.
- **Conversion mode defaults** — conversion implies `--no-clarify --no-align --no-interview` (a committed markdown plan is pre-validated content); sections map 1:1 to the HTML plan structure, frontmatter carries over (`created` preserved; `planned`/`todo` → `todo`, `in-progress` → `in-progress`, `completed`/`done` → `completed`), the output filename swaps the source extension to `.html` (still subject to the verb-target check), and Step 8 batches a keep-or-remove question for the source `.md`.
- **Docs** — README documents the `<plan.md>` argument and conversion semantics; the skill `description` and `argument-hint` advertise the conversion trigger so "convert docs/plans/foo.md into an HTML implementation plan" activates on the model path.

---

## 2.1.0 — Findings walkthrough and --skip-analysis flag for review-plan (2026-06-10)

### Added

- **Step 6b — Walkthrough & Analysis** — new `review-plan` workflow step inserted between synthesis (Step 6) and integration (Step 7). Instead of silently auto-applying every synthesized edit, the skill now offers an interactive walkthrough of the findings before anything is written into the plan.
- **Ask-first gate** — Step 6b opens with an `AskUserQuestion` gate offering `Walk through findings` (the default), `Apply all`, and `Review only`. Declining via `Review only` applies nothing but still appends the Team Review to the plan.
- **Per-finding triage** — during the walkthrough each finding is triaged `Accept` / `Modify` / `Reject`, batched at most 4 findings per prompt. `Modify` selections are deferred and collected into a single post-walkthrough edit pass instead of interrupting the walkthrough one finding at a time.
- **`--skip-analysis` flag** — bypasses the gate and the walkthrough entirely, preserving the previous auto-apply behavior in one shot.
- **`--triage-top <N>` flag** — individually triages only the `N` highest-risk findings and batch-accepts the rest, keeping the walkthrough short on large reviews.
- **Background mode implies `--skip-analysis`** — unattended `--background` runs never block on the gate or triage prompts.
- **Source / Rationale column and Triage Outcome subsection** — the synthesis template's (`references/output-template.md`) **Inline Edits to Apply** table gains a Source / Rationale column (originating reviewer plus why), with a Triage Outcome subsection placeholder beneath it for Step 7 Pass 2 to fill.
- **README documentation** — the plan-agent README now documents the `--skip-analysis` flag and the findings walkthrough.

### Changed

- **Step 7 Pass 1** — consumes `accepted_edits` when the walkthrough ran; the full-table fallback fires only for `--skip-analysis`, background mode, or the `Apply all` gate choice.
- **Step 7 Pass 2** — the appended Team Review now records triage outcomes (accepted / modified with revised content / rejected), and the Team Review is always appended even in review-only mode.

---

## 2.0.0 — Rename craft-prompt skill to refine-prompt (2026-06-10)

### Breaking

- **`craft-prompt` → `refine-prompt`** — the prompt-crafting skill is renamed to match its originating plan (`docs/plans/create-prompt-refiner-skill.html`). Invocation changes from `/plan-agent:craft-prompt` to `/plan-agent:refine-prompt`; the skill directory moves from `skills/craft-prompt/` to `skills/refine-prompt/`. Phases, interview flow, technique matrix, and templates are unchanged.

---

## 1.11.1 — Complete craft-prompt README documentation (2026-06-10)

### Fixed

- **README `craft-prompt` section** — the overview now hyperlinks [Anthropic's official Claude Prompting Best Practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices) guide (previously mentioned with no URL); the usage block gains a Before/After example showing a vague request ("write me a prompt to summarize stuff") transformed into the structured XML-layered prompt the skill produces; and a technique-matrix table (mirroring `skills/craft-prompt/SKILL.md`) now maps each prompt type (`system`, `task`, `creative`, `analytical`) to the best-practices techniques it applies.

---

## 1.11.0 — Review option in the plan exit step (2026-06-09)

### Added

- **`Review the plan` option in Step 8 exit menu** — every freshly-generated plan now offers a one-click path to the `review-plan` Agent Team. Selecting it presents a foreground-or-background sub-choice: foreground runs `Skill(skill: "plan-agent:review-plan", args: "<path>")` in-session and loops back to the menu after the review completes; background dispatches `Skill(skill: "plan-agent:review-plan", args: "<path> --background")` and returns to the menu immediately. Agent-Teams-unavailable hard-stop is handled gracefully — guidance is relayed and the menu is restored without crashing the flow. Plan status stays `todo` throughout reviewing.
- **`--background` flag for `review-plan` skill** — when present, the skill requires an explicit plan path, skips all `AskUserQuestion` prompts, defaults to update-in-place mode, and is safe for unattended execution.
- **`/plan-agent:review-plan-bg <path>` command** — thin background dispatcher that validates the plan path argument, spawns `agent-review-plan` with `run_in_background: true`, and returns an ack immediately.
- **`agent-review-plan` background agent** — fire-and-forget agent that confirms the plan file exists, invokes the `review-plan` skill with `--background`, and reports the updated path on completion. Runs on Sonnet with a 30-turn cap.

### Changed

- **Adaptive menu swap in Step 8** — the `AskUserQuestion` tool is capped at 4 options. When a workflow prompt is present, `Edit the plan` yields its slot to `Review the plan`: `Implement now` / `Run as workflow` / `Review the plan` / `Exit`. Without a workflow prompt all four options are present: `Implement now` / `Review the plan` / `Edit the plan` / `Exit`.

---

## 1.10.1 — Stable plan-created sort in auto-rebuild hook (2026-06-08)

### Fixed
- `hooks/build-index.sh`: replaced `os.path.getmtime` sort with `plan-created` meta sort so the auto-rebuild hook produces the same date-descending order as the `plans-library` skill. Editing a plan no longer promotes it to the top of the gallery.

## 1.10.0 — End-to-end self-verification gate (2026-06-08)

### Added

- **End-to-end verification gate in the implement-now flow** (`implementation-plan` Step 8) — after the acceptance-criteria gate and before the completion-checklist gate, Claude now runs the plan's objective-verification test plus the Verification section's end-to-end steps as a holistic check. On failure it diagnoses, fixes the source, and re-verifies in a bounded loop (up to 3 attempts), then asks the user how to proceed if still failing.
- **Objective-verification test run in `finalize-plan`** (Step 3c) — finalize-plan now executes the `.objective-test-card` **Run** command as an end-to-end pass/fail signal, surfaces the result in the findings summary, warns before completing on failure, and records failures in the Completion Report.

### Changed

- Consolidated unreleased changelog entries.

---

## Unreleased — Remove review artifact emission from review-plan

### Removed

- **Step 8 (Artifact)** — the skill no longer emits a standalone `*-review.html` file. All review findings are now placed directly into the source plan via the collapsible `<details class="team-review">` block appended in Step 7.
- **`SendUserFile`** removed from `allowed-tools` — no separate file is delivered.

### Changed

- **Step numbering** — cleanup is now Step 8 (was Step 9); total workflow steps reduced from 9 to 8.

---

## v1.9.0 — 2026-06-06 — Agent Team–based plan review skill

### Added

- **`/plan-agent:review-plan` skill** — new skill that spawns a seven-reviewer Agent Team (5 core + 2 UI-conditional) to review implementation plans, synthesize findings, apply improvements in place, and emit shareable HTML review artifacts. Detects UI signals (React, Vue, Svelte, buttons, modals, forms, etc.) and conditionally runs UX and accessibility reviewers when present.
- **Seven reviewer agent definitions** under `agents/`:
  - **Core reviewers** (always spawned): `plan-reviewer-architecture`, `-completeness`, `-testability`, `-risk`, `-conventions`
  - **UI-conditional reviewers** (spawned when UI signals detected): `plan-reviewer-ux`, `-accessibility`
- **Reference files** under `skills/review-plan/references/`:
  - **`role-prompts.md`** — seven lens-specific spawn prompts for Agent Team briefing, with template placeholders for plan path substitution.
  - **`output-template.md`** — synthesis report structure with Executive Summary, Role-by-Role findings, Agreements/Conflicts, Highest-Risk Issues, and the critical **Inline Edits to Apply** table that maps each improvement to a concrete HTML target element and action.
- **Agent Teams support** — hard-gates on `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` and Claude Code ≥ 2.1.32; requires feature flag and version check before spawning.

### Changed

- **Plugin description** — updated marketplace.json and plugin.json descriptions to include the new `review-plan` skill alongside `implementation-plan`, `finalize-plan`, and `craft-prompt` skills.
- **Version bump** — from 1.8.0 to 1.9.0 (MINOR bump per marketplace.md — new skill added).

---

## v1.8.0 — 2026-06-06 — Mandatory Tests section in implementation plans

### Added

- **Tests section** — every generated plan now includes a Tests section between Steps and Acceptance Criteria with a two-tier depth model: Tier 1 (code-touching plans) includes unit, integration, E2E, and objective-verification tests; Tier 2 (non-code plans) includes only the objective-verification test.
- **Objective-verification test** — mandatory for both tiers, renders as a green hero card (`.objective-test-card`) before the test list. Asserts the plan's stated objective is accomplished.
- **Test badge CSS** — `.test-badge-unit` (blue), `.test-badge-integration` (amber), `.test-badge-e2e` (purple), `.test-badge-objective` (green) with design-token-based colors.
- **`#ic-beaker` SVG icon** — added to the icon sprite sheet for the Tests nav link and section heading.
- **Purple design tokens** — `--purple`, `--purple-bg`, `--purple-border` added to `:root` for E2E badge styling.
- **Step 5c** — new test-generation workflow step that classifies the tier from step content, generates the objective-verification test from the plan objective, and produces unit/integration/E2E test entries for Tier 1 plans.

### Changed

- **`implementation-plan` SKILL.md** — Required Structure now includes `tests`; HTML Output Requirements document the Tests section rendering; Step 5c added to the workflow between Interview and Status.
- **`SKELETON.html`** — nav sidebar includes Tests link; Tests section HTML with tier label, objective-test card, and test-list placeholders.

---

## v1.7.0 — 2026-06-06 — Copyable plan file name and relative path in HTML output

### Added

- **Plan source block** — every generated plan now renders a `.plan-source` block below the implement/workflow rows with two copyable rows: the plan **File** name (basename) and its relative **Path**, each with a Copy button. Gives users the plan's name and relative URL to paste into docs and prompts. Stays visible when the plan is `completed`; hidden in print.
- **`plan-file` and `plan-path` meta tags** — added `<meta name="plan-file">` and `<meta name="plan-path">` to the plan `<head>` for machine readability.
- **`copyPath()`** helper in `SKELETON.html` to copy either field to the clipboard (with `execCommand` fallback).

### Changed

- **`implementation-plan` SKILL.md** — Step 2 now computes `{plan-filename}` and `{plan-path}` placeholders; Step 3 frontmatter and the HTML Output Requirements document the new meta tags and the plan source block.

---

## v1.6.0 — 2026-06-06 — Auto-generate Files file-tree from plan steps

### Added

- **File-Tree Auto-Generation** — new subsection in `implementation-plan` SKILL.md that automatically extracts file references from drafted steps, classifies each as `new`/`modified`/`deleted`/`generated` based on action verbs, groups by directory, and populates `{file-tree-rows}` — eliminating manual file-tree construction.

### Changed

- **`implementation-plan` SKILL.md** — the Files section (`section.card-files#files`) is now auto-generated instead of opt-in. Updated the Visual Sections heading, HTML Output Requirements, Visual Components table/rules, and Skeleton instructions to reflect the new behavior. File-tree is always included when ≥1 file is referenced; only deleted for purely conceptual plans.

---

## v1.5.1 — 2026-06-05 — Use portable plugin-dir path in README

### Fixed

- `README.md`: local-development example now uses the repo-relative `./kit/plugins/plan-agent` path instead of an author-specific home directory.

---

## v1.5.0 — 2026-06-05 — Add visual components (file-tree, diagrams, charts, tables) to plan template

### Added

- **`reference/SKELETON.html`** — four opt-in, pure-CSS visual components, each shipped as a `<body>` block behind a removal comment (kept and filled when relevant, deleted with its sidebar nav link otherwise):
  - **File-tree** (`.file-tree`) — a `Files to Modify` section (`section.card-files#files`, between Context and Steps) listing files with `file-badge-new` / `file-badge-modified` / `file-badge-deleted` / `file-badge-generated` badges.
  - **Flow / pipeline diagram** (`.pipeline`) and **comparison grid** (`.compare-grid`, with `compare-col-add` / `compare-col-neutral` / `compare-col-remove` variants) — a `Diagram` section (`section.card-diagram#diagram`). Ported and generalized from the hand-authored components in `docs/plans/build-clean-plugin-dist.html`.
  - **Bar chart** (`.bar-chart`) — horizontal bars sized by an inline `style="--val:NN%"` custom property; script-free, with a visible `.bar-value` and a descriptive container `aria-label`.
  - **Data table** (`.plan-table`) — accessible table styling requiring `<caption>` and `<th scope="col">` headers.
- New `:root` tokens (`--green-border`, `--amber-bg`, `--amber-border`, `--red`, `--red-bg`, `--red-border`) so all visuals theme consistently; new `#ic-folder` icon symbol; conditional `Files` and `Diagram` sidebar nav links.

### Changed

- **`implementation-plan` SKILL.md** — documented the visual components: added an *Optional visual sections* subsection to **Required Structure**, an opt-in/accessibility bullet to **HTML Output Requirements**, a new **Visual Components** reference section (per-component triggers + rules), and a note in **Skeleton** that unused visual blocks are removed like `.plan-workflow`. All visuals stay pure CSS / inline SVG (no CDN); the gallery scanner is unaffected (it reads only meta tags + `<title>`).

---

## v1.4.1 — 2026-06-04 — craft-prompt: save prompt output to file

### Changed

- **`craft-prompt` SKILL.md** — added **Phase 7 — Save**: after delivering the prompt in Phase 6, the skill saves it as a markdown file with a `{type}-{intent-slug}-{YYYY-MM-DD}.md` filename and YAML frontmatter (`type`, `intent`, `techniques`, `created`). Output directory resolution (first match wins): (1) `promptsDirectory` from `.claude/settings.json` (project then global); (2) `{git-root}/docs/prompts/` anchored via `git rev-parse --show-toplevel`; (3) `docs/prompts/` relative to `$PWD` if not in a git repo. Includes a uniqueness guard: appends `-2`, `-3`, etc. if the target file already exists.
- `allowed-tools` extended with `Write`, `Bash(git *)`, and `Bash(mkdir *)` for repo-root detection, directory creation, and file save.

---

## v1.4.0 — 2026-06-04 — Add craft-prompt skill

### Added

- **`/plan-agent:craft-prompt [intent]`** — new skill (`disable-model-invocation: true`) that interviews users about their prompting need and generates a copy-pasteable AI prompt grounded in Anthropic's official Claude Prompting Best Practices.
  - **Phase 1 — Classify**: identifies the prompt type (system, task, creative, analytical) and applies a technique matrix mapping each type to its applicable best-practice layers.
  - **Phase 2 — Interview**: uses `AskUserQuestion` with type-specific questions derived from the technique matrix; always asks the user's *why* (per "Add context to improve performance"); offers progressive depth on user opt-in.
  - **Phase 3 — Structure**: maps interview answers to XML layers — `<role>`, `<instructions>`, `<constraints>`, `<context>`, `<example>`, `<thinking>`, `<document>` — applying only the techniques selected for the classified type.
  - **Phase 4 — Draft**: reads the appropriate template from `references/` (`system-prompt-template.md`, `task-prompt-template.md`, `creative-prompt-template.md`, `analytical-prompt-template.md`) and substitutes structured content into placeholders.
  - **Phase 5 — Recommend**: uses `ToolSearch` to surface 1–3 installed skills/agents that may achieve the goal directly, with invocation syntax and rationale.
  - **Phase 6 — Deliver**: presents the assembled prompt in a fenced block with technique header and tool recommendations.
- **`references/best-practices-reference.md`** — distilled summary of all eight core techniques from Anthropic's Claude Prompting Best Practices guide, organized by technique name with actionable implementation notes and applied-in phase references.
- **`references/system-prompt-template.md`** — parameterized template with `<role>`, `<instructions>`, `<constraints>` XML structure plus placeholder guide and assembled example.
- **`references/task-prompt-template.md`** — parameterized template with `<context>`, `<example>`, `<thinking>` scaffolding, CoT steps, and output format section; includes realistic refactoring example.
- **`references/creative-prompt-template.md`** — parameterized template with role assignment, voice description, context block, and style requirements; positive framing throughout.
- **`references/analytical-prompt-template.md`** — parameterized template with `<document>` grounding, `<thinking>` CoT, quote-extraction instruction, self-check, and output format.

---

## v1.3.2 — 2026-06-04 — Revert sort-by-created-date to mtime

### Fixed

- **build-index.sh**: reverts gallery sort back to filesystem mtime (newest-modified first); removes the `plan-created` metadata sort introduced in v1.3.1.
- **plans-library SKILL.md**: Step 3 reverts to `xargs ls -t` mtime sort; removes the collect-then-sort-by-created-date instruction from Step 4.

---

## v1.3.0 — 2026-06-04 — Rich implementation prompt with plan context

### Changed

- **SKELETON.html**: `copyCmd()` now calls `buildImplementPrompt()` which builds a concise action-oriented prompt from the plan's live DOM state — includes the short implement prompt, a status summary with step/criteria progress counts, and numbered instructions directing the implementer to read the plan, implement todo steps, verify criteria, and complete the checklist directly in the plan file.
- **SKELETON.html**: workflow prompt row converted from a static `<div>` to an expandable `<details>` element — collapsed by default with summary "Run as workflow — launch parallel subagents", reducing visual clutter while keeping the workflow option accessible.
- **SKILL.md Step 2**: documented the new "Full implementation prompt (Copy behavior)" paragraph explaining the DOM-driven rich prompt.
- **SKILL.md flags**: added `--workflow` flag to force workflow prompt generation, bypassing the complexity heuristic.

---

## v1.2.0 — 2026-06-04 — Make implementation-plan model-invocable

### Changed

- **`implementation-plan` skill**: removed `disable-model-invocation: true` — the skill is now both command-invocable (`/plan-agent:implementation-plan <objective>`) and model-invocable (auto-activates on plan-document intent).
- **`implementation-plan` description**: rewritten to a narrow, artifact-scoped three-part trigger ("generate an HTML implementation-plan document … Use when the user asks to create a plan document, generate an HTML plan, or write a plan file") that avoids colliding with built-in Plan Mode.
- **`implementation-plan` Invocation & Arguments**: documents both activation paths — command (with `$ARGUMENTS` and flags) and model (derives objective from conversation context, runs full workflow by default).
- **README.md**: updated all `implementation-plan` sections to reflect dual-mode activation; `finalize-plan` manual-only status unchanged.

---

## v1.1.0 — 2026-06-03 — Add mandatory completion checklist and report to plans

### Added

- **SKELETON.html**: new "Completion Checklist" section between Verification and Next Steps with three `disabled` checkboxes — (1) all step TODOs marked as done, (2) all acceptance criteria verified and checked, (3) plan status updated to `completed`. Checkboxes auto-update via JavaScript based on DOM state. Amber border transitions to green when all conditions are met.
- **SKELETON.html**: new "Completion Report" sub-section inside the checklist. Initially shows "No items to report"; populated with a `<dl>` detailing each incomplete item and the reason it could not be completed when the plan is finalized with unresolved items.
- **SKELETON.html**: new `ic-clipboard-check` SVG icon symbol and sidebar nav entry for the Completion section.
- **SKILL.md**: `completion-checklist` added to the Required Structure list as a mandatory (never-optional) section.
- **SKILL.md Step 8**: new "Completion checklist gate" runs after the acceptance criteria gate — verifies all three completion requirements, checks them off, and populates the Completion Report with specific details for any items that could not be completed.
- **finalize-plan SKILL.md**: new Steps 5d (completion checklist checkboxes) and 5e (completion report population) handle the checklist during plan finalization, with defensive skip when the section doesn't exist in older plans.

---

## v1.0.1 — 2026-06-03 — Pin implementation-plan skill to Opus model

### Changed

- **`implementation-plan` skill**: added `model: opus` to frontmatter so the skill always runs on the latest Opus model regardless of the session's default model.

---

## v1.0.0 — 2026-06-02 — Rename `complete-plan` skill to `finalize-plan`

### Breaking Changes

- **`complete-plan` → `finalize-plan`**: the skill directory and invocation path have changed. Update any existing invocations from `/plan-agent:complete-plan` to `/plan-agent:finalize-plan`. Functionality is identical.

---

## v0.23.2 — 2026-06-02 — Fix plans-open trigger ambiguity

### Fixed

- **`plans-open` description**: restored "without a rebuild" qualifier to the trigger phrase so it no longer overlaps with `plans-library`'s "browse plans" trigger, preventing mis-routing of first-time or rebuild-needed gallery requests.

---

## v0.23.1 — 2026-06-02 — Optimize skill descriptions to three-part format

### Changed

- Rewrote `description` fields in `complete-plan`, `implementation-plan`, `plans-library`, and `plans-open` to the three-part format (short label ≤80 chars + capability sentence + trigger phrase, total ≤200 chars) for improved skill discoverability.

---

## v0.23.0 — 2026-06-01 — Rename `planning` skill to `implementation-plan`

### Changed

- **Renamed the `planning` skill to `implementation-plan`.** Invocation is now `/plan-agent:implementation-plan <objective>` (previously `/plan-agent:planning`). The skill directory moved from `skills/planning/` to `skills/implementation-plan/`; all behavior, arguments, and workflow steps are unchanged. Update any saved commands or aliases that referenced the old name.

---

## v0.22.0 — 2026-06-01 — Add acceptance criteria verification gate

### Changed

- **`planning` Step 8 "Implement now"** — added mandatory acceptance criteria gate after all steps are implemented. Each criterion is individually verified against the codebase before being checked off. Unverifiable criteria are flagged to the user; the plan stays `in-progress` unless all criteria are checked.
- **`complete-plan` Step 3** — new sub-step 3b maps implementation evidence to individual acceptance criteria, classifying each as `verified` or `unverified`.
- **`complete-plan` Step 4** — summary now shows per-criterion verification status and offers three completion options: check all, only auto-check verified, or cancel.
- **`complete-plan` Step 5b** — respects the user's Step 4 choice: checks only verified criteria when the user opts to auto-check verified only, and downgrades status to `in-progress` accordingly.
- **`complete-plan` Step 6** — delivery message reflects whether all criteria were verified or some remain open.

---

## v0.21.0 — 2026-06-01 — Add /workflows support for complex plans

### Added

- **Workflow prompt row** — complex plans now include a `<div class="plan-workflow">` element below the implement prompt with a "Run a workflow to implement the plan at …" prompt and copy button. Triggers Claude Code's `/workflows` runtime when pasted, launching parallel subagent orchestration for large-scale implementations.
- **`<meta name="plan-workflow">` tag** — machine-readable workflow prompt in the plan `<head>` for gallery extraction.
- **`copyWorkflow()` JS function** — dedicated clipboard handler for the `<code id="workflow-cmd">` element.
- **Step 8 "Run as workflow" option** — when a workflow prompt was generated, the post-planning prompt offers a fourth choice to launch a dynamic workflow instead of sequential implementation.

### Changed

- **SKILL.md Step 2 (Create)** — now assesses plan complexity to decide whether to generate a `{workflow-prompt}` alongside `{implement-prompt}`. Workflow prompts are generated when plans touch 5+ files across 3+ directories, involve repetitive per-file changes, include parallelizable steps, or require cross-checking.
- **SKILL.md Step 3 (Frontmatter)** — includes `<meta name="plan-workflow">` when a workflow prompt was generated.
- **SKILL.md next-steps** — next-step prompts can now use "Run a workflow to …" prefix for items that benefit from workflow orchestration.
- **SKELETON.html** — added `.plan-workflow` CSS (blue accent), HTML row with `{workflow-prompt}` placeholder, and `copyWorkflow()` JS function. Row is conditionally removed when no workflow prompt is generated.
- **CLAUDE.md** — fixed branch naming example from `add-reinvoke-prompt` to `add-implement-prompt`.

## v0.20.0 — 2026-06-01 — Add complete-plan skill

### Added

- **`/plan-agent:complete-plan [plan-filename.html]`** — new skill (`disable-model-invocation: true`) that reviews an HTML plan for codebase implementation evidence, presents a confirmation summary, then marks all acceptance-criteria checkboxes as checked, adds the `completed` class to every step card, and updates all three status representations (`<html data-status>`, `<meta name="plan-status">`, visible badge) to `completed`.

---

## v0.19.0 — 2026-06-01 — Replace reinvoke prompt with implement prompt

### Changed

- **Plan output** — the copy/paste prompt below the objective now generates an implementation prompt (e.g. `Read and implement all steps in the plan at docs/plans/add-dark-mode-toggle.html`) instead of a re-invoke command that re-runs the planning skill
- **SKELETON.html** — `.plan-reinvoke` CSS/HTML/JS renamed to `.plan-implement` with green accent styling; label changed from "Re-invoke" to "Implement"
- **Meta tag** — `<meta name="plan-reinvoke">` replaced with `<meta name="plan-implement">`
- **SKILL.md** — Steps 2, 3, and HTML Output Requirements updated; `{reinvoke-cmd}` placeholder replaced with `{implement-prompt}`; scope constraint reordered to prioritize `plansDirectory` setting over hardcoded `docs/plans`

## v0.18.2 — 2026-06-01 — Add ExitPlanMode error handling; planning workflow improvements

### Fixed

- fix: add ExitPlanMode error handling — treat 'not in plan mode' error as success
- Remove auto-commit step from planning skill (step 6 removed)
- Add 'Edit the plan' option to post-planning prompt (step 8)

## v0.18.1 — 2026-06-01 — Fix reinvoke command: strip .html token before objective extraction

### Fixed

- **Argument parser — `.html` plan file detection**: A leading `.html` token (e.g. `add-dark-mode-toggle.html`) is now stripped from `$ARGUMENTS` before the objective is extracted, preventing the filename from polluting the objective when the re-invoke command is pasted verbatim. The stripped value is stored as `$PLAN_FILE`; when no remaining objective text exists, the plan's existing `<title>` tag is used as the objective fallback.

---

## v0.18.0 — 2026-06-01 — Add re-invoke prompt to every generated plan

### Added

- **Re-invoke prompt row** — every generated plan HTML now includes a `<div class="plan-reinvoke">` element immediately below the objective card. Shows the `/plan-agent:planning <filename> <short-objective>` command with a copy button so developers can resume or reference the plan without reconstructing the command.
- **`copyCmd()` JS function** — dedicated clipboard handler for the `<code id="reinvoke-cmd">` element, separate from the existing `copyPrompt()` which targets `<pre>` blocks.
- **`<meta name="plan-reinvoke">` tag** — machine-readable reinvoke command in the plan `<head>` for plans-library gallery extraction.

### Changed

- **`SKILL.md` Step 2 (Create)** — now instructs the model to compute `{reinvoke-cmd}` = `/plan-agent:planning <filename> <short-objective≤60chars>` and fill the skeleton placeholder.
- **`SKILL.md` Step 3 (Frontmatter)** — now requires `<meta name="plan-reinvoke" content="…">` alongside the other required meta tags.
- **`SKILL.md` HTML Output Requirements** — new bullet documents the reinvoke row as a required element.

### UX

- Reinvoke command text soft-wraps (`word-break: break-all`) for long objectives.
- Copy button is hidden via CSS when `data-status="completed"` — no copy affordance for plans that are done.
- Row is suppressed in `@media print`.

---

## v0.17.1 — 2026-06-01 — Minor wording corrections

### Fixed

- `planning` and `plans-library` skills: minor description wording corrections.

---

## v0.17.0 — 2026-05-31 — Add plans-open skill (open gallery without rebuild)

### Added

- **`plans-open` skill** — opens the existing `index.html` gallery directly without scanning plan files, parsing metadata, or writing any files. Resolves `plansDirectory` from settings (same as `plans-library`). If `index.html` does not exist, tells the user to run `/plan-agent:plans-library` first.

---

## v0.16.0 — 2026-05-31 — Fix Step 9 status sync and commit instructions

### Fixed

- **Step 9 `Implement now` — status sync**: Now updates all three status representations together (`<html data-status>`, `<meta name="plan-status">`, and visible badge text), mirroring Step 7's sync rules. Previously only `<meta name="plan-status">` was mentioned.
- **Step 9 `Implement now` — commit instruction**: Now explicitly commits source file changes together with the updated plan file. Previously only the plan file was mentioned, leaving source changes potentially uncommitted.
- **Step 9 `Exit` — state model clarity**: Clarifies that `todo` is the correct terminal state for an unimplemented plan and that no status update is needed on exit, resolving ambiguity with Step 7's `todo → in-progress → completed` progression.

---

## v0.15.0 — 2026-05-31 — Add issue ingestion to /plan-agent:planning

### Added

- **Issue reference detection** — `$ARGUMENTS` is now scanned for a GitHub/GitLab issue URL or bare `#n`/integer before flag parsing. When detected, the reference is stripped from the argument string and stored as `$ISSUE_REF`.
- **Step 0.5 — Issue Ingestion** — New workflow step that fires when `$ISSUE_REF` is set. Runs `gh issue view` (GitHub) or `glab issue view` (GitLab), maps `title` → objective, `body` → context block, `labels` → type hint, `url` → plan frontmatter. Falls back gracefully to plain-objective mode on any CLI error.
- **`<meta name="plan-issue">` tag** — Plans seeded from an issue reference now include the source issue URL in the HTML `<head>` for machine readability by the gallery index and downstream tooling.
- **`argument-hint` updated** — Now reads `<issue-url|#n> | <objective> [flags…]` to expose the new entry point at autocomplete time.

### Example

```
/plan-agent:planning https://github.com/shawn-sandy/agentics/issues/205
/plan-agent:planning #205
/plan-agent:planning #205 focus on the auth layer --quick
```

---

## v0.14.1 — 2026-05-31 — Fix MultiEdit path extraction and bundle build-index.sh

### Fixed

- **P2 — MultiEdit `file_path`**: `file_path` is a top-level key on `tool_input` for all tool types including `MultiEdit`; the previous code incorrectly read it from inside `edits[0]`, causing MultiEdit events to always produce an empty path and exit without rebuilding.
- **P1 — Bundle `build-index.sh` with plugin**: `docs/plans/build-index.sh` is not shipped inside the `plan-agent` plugin directory, so consumer projects that install via the marketplace had no rebuild script and the hook silently exited. Added `hooks/build-index.sh` (identical logic, accepts `PROJECT_ROOT` as `$1`) and updated the hook to prefer the bundled copy via `$CLAUDE_PLUGIN_ROOT`, falling back to a local `build-index.sh` in the plans directory for projects that have it.

---

## v0.14.0 — 2026-05-30 — Add PostToolUse hook to auto-rebuild plans index

### Added

- **`hooks/rebuild-plans-index.py`** — PostToolUse hook that fires on every `Write|Edit` to a non-`index.html` `.html` file inside the configured plans directory. Calls `docs/plans/build-index.sh` to regenerate the gallery index automatically. Always exits 0 so index-rebuild failures never block plan writes.
- **`docs/plans/build-index.sh`** — self-contained shell entry point that regenerates `docs/plans/index.html` without Claude. Finds the `plans-gallery.html` template via the same plugin-discovery strategy as `plans-library`; falls back to a minimal embedded styled gallery if the template is unavailable.
- Registered `rebuild-plans-index.py` as a second `PostToolUse` entry in `hooks.json` with `Write|Edit` matcher and a 30-second timeout.

## v0.13.0 — 2026-05-31 — Add plans-library skill and gallery template

### Added

- **`plans-library` skill** — scans the configured `plansDirectory`, parses each plan's metadata, and writes a filterable HTML gallery (`index.html`) with status/type chips, title search, and grid/list views. Opened in the browser on completion.
- **`plans-gallery.html` template** — standalone gallery template with versioned cache path, JSON-safe title parsing, and an explicit `GENERATED_AT` timestamp.

### Fixed

- **`plans-library` xargs** — replaced `xargs ls -t` with `xargs -0 ls -t` (null-delimited) to handle plan paths that contain spaces.
- **`plans-library` template discovery** — versioned cached templates are now sorted by version descending (`sort -rV`) before `head -1`, making the selection deterministic when multiple cached versions exist.
- **`planning` Step 0 bootstrap wording** — clarified that the `ToolSearch(select:ExitPlanMode)` preflight runs as part of Step 0 (not before it); removed the contradictory "before any other action" phrase.
- **`planning` preflight echo** — moved the resolved-objective echo to after the Step 0 bootstrap so no user output precedes `ExitPlanMode`.

---

## v0.12.1 — 2026-05-30 — Fix section sign rendering

### Fixed

- Replaced `§` (section sign) characters with plain text ("Step N", "Steps N–M") across SKILL.md, README.md, and CHANGELOG.md to fix rendering issues in terminals and markdown viewers.

---

## v0.12.0 — 2026-05-30 — Codebase exploration, Grep, and browser fallback

### Added

- **Step 0b Explore** — new codebase research step after the self-bootstrap and before Clarify. Uses `Glob`, `Grep`, and `Read` to build context on entry points, existing patterns, tests, and configuration before drafting steps. Exploration depth scales with plan scope. Skipped by `--quick`.
- **`Grep`** added to `allowed-tools` — enables first-class codebase symbol and pattern search without permission prompts during exploration and plan drafting.
- **Step 8 browser fallback** — when the browser MCP server is unavailable (headless/web environments), falls back to `SendUserFile` with the file path, ensuring plan delivery always works.

### Changed

- **Description tightened** — first sentence shortened to fit within the ≤80-char guideline.

---

## v0.11.2 — 2026-05-30 — Add scope constraint: plans only, no implementation

### Added

- **Scope Constraint section** — explicit rule block inserted before the Workflow prohibiting the skill from editing source files or applying any change described in the plan's steps. The plan is the deliverable; implementation is a separate, user-initiated step. Addresses a case where the skill implemented a fix rather than writing a plan for it.

---

## v0.11.1 — 2026-05-30 — Fix: self-bootstrap out of harness plan mode

### Fixed

- **Step 0 self-bootstrap** — Added unconditional `ExitPlanMode` call as the first step of the workflow. When the harness enters plan mode on "planning"-keyword commands it forces `.md` output to a random-slug path, overriding the skill's `.html` guarantee. Calling `ExitPlanMode` immediately exits harness plan mode so the skill writes directly to disk as designed. Root cause: v0.8.0 removed `ExitPlanMode` from `allowed-tools` but left no escape hatch for harness-triggered plan mode.
- **`allowed-tools`**: added `ExitPlanMode`, `WebFetch`, `WebSearch`, `SendUserFile`.

---

## v0.11.0 — 2026-05-30 — Add plans-library skill and web research tools

### Added

- **`plans-library` skill** — scans every HTML plan in the plans directory, parses `<meta>` tags (`plan-status`, `plan-type`, `plan-created`) and `<title>`, populates a gallery template, writes `docs/plans/index.html`, and opens it in the browser. Filterable by status (todo / in-progress / completed) and type (feature / fix / refactor / docs / chore) with a title search box. Excludes `index.html` and `archive/` subdirectory.
- **`templates/plans-gallery.html`** — self-contained gallery template (no external CSS/JS/CDN) with light theme; grid and list views; client-side filtering.
- **`WebFetch`, `WebSearch`, `SendUserFile`** added to `allowed-tools` — enables research during Clarify (verifying APIs, checking library versions) and delivers the finished plan file to the user in Step 8 Open.

---

## v0.10.0 — 2026-05-30 — Add built-in structured interview step

### Added

- **Step 5b Interview** — new standard workflow step between Align and Commit. Analyzes plan content to classify complexity (short/medium/complex), detects UI signals, then runs 1–3 interview rounds via `AskUserQuestion` with dynamically generated questions. Round 1 (Technical & Trade-offs) always runs; Round 2a (UI/UX) and 2b (Accessibility) run for medium+ plans or when UI signals are detected; Round 3 (Edge Cases) runs for complex plans only. Post-interview summary offers to update the plan HTML before committing.
- **`--no-interview` flag** — skips Step 5b Interview for pre-validated or time-critical plans.

### Changed

- **`--quick` expanded** — now shorthand for `--no-clarify --no-align --no-interview` (previously only `--no-clarify --no-align`).

### Removed

- **`--interview` flag** — the external delegation to `plan-interview:plan-interview` after Step 8 is replaced by the built-in Step 5b step. The `plan-interview` plugin remains available as a standalone deep-interview tool.

---

## v0.9.0 — 2026-05-30 — Add mandatory Step 8 Open step with browser verification

### Added

- **Step 8 Open** — new mandatory final workflow step that opens the committed plan in a browser to confirm it renders correctly. Steps: find a free port via `python3 -c "import socket…"`, start `python3 -m http.server <port>` in the background from the plan's parent directory, load browser tools via `ToolSearch`, navigate to `http://localhost:<port>/<plan-filename>`, take and send a screenshot, report the URL to the user, and leave the server running. Cannot be skipped.
- **`allowed-tools` expanded** — added `ToolSearch`, `mcp__claude-in-chrome__tabs_context_mcp`, `mcp__claude-in-chrome__tabs_create_mcp`, `mcp__claude-in-chrome__navigate`, and `mcp__claude-in-chrome__computer` so browser automation tools are pre-approved and never prompt mid-run.

---

## v0.8.0 — 2026-05-30 — Remove plan-mode handshake; tighten skill consistency

### Changed

- **Remove `EnterPlanMode`/`ExitPlanMode` handshake** — the skill now writes its HTML plan file directly instead of entering harness plan mode, restoring its two output guarantees: `verb-target` kebab-case filename and self-contained `.html` output. Root cause: `EnterPlanMode` handed control to the harness, which forced markdown to a random-slug path, contradicting the skill's own "no plan mode for write operations" rule.
- **`--template` flag**: trimmed to `default` only in `argument-hint`; `minimal`, `adr`, and `spike` are documented as planned but not yet implemented.
- **Skeleton variants deleted**: `reference/SKELETON-minimal.md`, `reference/SKELETON-adr.md`, `reference/SKELETON-spike.md` removed — they were markdown files and violated the "always write HTML" rule. `reference/SKELETON.html` remains the sole supported skeleton.
- **`allowed-tools`** pruned: `EnterPlanMode`, `ExitPlanMode`, `ToolSearch`, `TodoWrite`, and `Grep` removed (dead weight after plan-mode removal or unreferenced in body).
- **Heading hierarchy**: body H1 (`# Plan Agent — Planning`) lowered to H2.
- **Freedom level**: `## Workflow` opens with "Follow these steps exactly." to prevent guardrail-skipping on a process-critical sequential skill.
- **Frontmatter description**: rewritten with capability statement, user-intent trigger, and scope-exclusion sentence (≤1024 chars, third person).
- **`$ARGUMENTS` clarifying note**: added to `Invocation & Arguments` explaining why this command-only construct is valid here.

---

## v0.7.1 — README: correct --template flag docs; fix planAgent.extraFrontmatter key

- Updated README.md to accurately reflect current plugin capabilities, component inventory, and usage patterns.

## 0.7.0 — 2026-05-29

### Added

- **Copy prompt buttons**: each `<pre>` prompt block in the Next Steps (including Wish List items) and Unresolved Questions sections now has a "Copy prompt" button. Clicking copies the prompt text to the clipboard; the button shows "Copied ✓" for 2 seconds then reverts. Uses the Clipboard API with a textarea fallback for `file://` protocol. Hidden in print.
- `copyPrompt` global JS function added to `SKELETON.html` (outside the IIFE so inline `onclick` handlers can resolve it).
- `.copy-prompt-btn` CSS class: blue-accent pill matching the document design tokens; green `.copied` state mirrors existing completion colours.
- SKILL.md updated to mandate copy buttons on every prompt `<pre>` in generated plans and to warn against removing them when filling placeholders.

---

## 0.6.0 — 2026-05-29

### Added

- **Sticky sidebar navigation**: two-column layout (200px sidebar + content) with "On this page" section links; collapses to single-column on narrow viewports.
- **Scroll rail**: animated 3px progress indicator on the left edge of the sidebar tracks page scroll position in real time.
- **Scroll spy**: `IntersectionObserver`-powered active link highlighting (left-border indicator) in the sidebar as sections enter the viewport.
- **CSS step timeline**: vertical connector line with circle nodes on each step card; nodes turn green when all criteria are checked (via CSS `.step-card.completed`).
- **Step chips**: `<span class="step-chip">todo</span>` decorates each step action with a pill badge; turns green when the step card is marked complete.
- **localStorage persistence**: acceptance-criteria checkbox state saved to `localStorage` keyed by page title — survives page refresh.
- **Print styles**: sidebar, scroll rail, and step chips hidden in print; single-column layout.
- **Inline SVG icons**: Heroicons `<symbol>`/`<use>` pattern replaces emoji; zero external dependencies.
- **Pulsing in-progress dot**: status badge dot pulses when `data-status="in-progress"`; respects `prefers-reduced-motion`.
- **Accessibility baseline**: skip link, `aria-labelledby` on every section, `role="progressbar"` attributes, `aria-live="polite"` region for criteria announcements, `min-height: 44px` touch targets on nav links.
- **Tone guidance in SKILL.md**: writing-style addendum encouraging rallying-statement objectives and imperative-verb step actions.

### Changed

- `SKELETON.html`: professional document aesthetic — white page, white header with a single 3px blue accent stripe, "Implementation Plan" doc-type label above the plan title.
- Sections rendered as flat ruled document sections separated by `border-top` lines (no card shadows or rounded corners).
- `<div class="section-card">` elements converted to `<section>` with `id` and `aria-labelledby` for improved semantics.
- Step number badges simplified to a plain grey circle (no gradient).
- Criteria items styled as individual bordered rows.
- Progress bar thinned to 6px with a solid blue fill.
- `--radius: 4px` throughout for a sharper document feel.

---

## 0.5.0 — 2026-05-28

### Added

- **HTML output** (default): the `planning` skill now writes every plan as a self-contained `.html` file — no markdown, no external dependencies.
  - Rich layout: status badge, objective highlight card, numbered step cards with expandable *Verify* disclosures, interactive acceptance-criteria checkboxes with live progress bar, collapsible Next Steps and Unresolved Questions sections.
  - **Wish List subsection**: blue-sky / visionary ideas in `next-steps` are automatically labelled `🔭 Wish List` and rendered with a distinct dashed-border, muted-colour treatment so they read as non-committal aspirations.
  - Plan metadata stored in `<meta>` tags (`plan-status`, `plan-type`, `plan-created`, `plan-repo`) for machine readability.
  - Minimal inline JavaScript (progress bar on checkbox change); fully functional without JS.
- `reference/SKELETON.html`: new bundled HTML plan template replacing `SKELETON.md` — all required sections pre-wired with placeholders in `{curly braces}`.

### Changed

- **Step 2 Create**: plan filename extension changed from `.md` to `.html`.
- **Step 3 Frontmatter**: metadata now stored in HTML `<meta>` tags instead of YAML frontmatter.
- **Step 7 Status**: status updates now edit `<html data-status="…">` and the badge element instead of YAML.
- `validate-plan-filename.py` hook updated to accept both `.html` (primary) and `.md` (legacy) plan files; `_is_completed` now reads `<meta name="plan-status" content="completed">` for HTML files.

### Fixed (in this release)

- Status `<html data-status="…">` attribute is on the `<html>` element (not `<body>`); SKILL.md Step 7 and CHANGELOG wording corrected to match the skeleton.
- SKILL.md Step 7 now instructs updating **both** `<html data-status>` and `<meta name="plan-status">` so CSS badge colour and the hook's completion check stay in sync.
- SKILL.md Step 3 no longer mentions a redundant `<script type="application/json" id="plan-meta">` block; `<meta>` tags are the sole metadata channel.
- SKELETON.html `<ul class="next-steps-list">` changed to `<div>` — `<details>` and `<div>` are not valid `<ul>` children per HTML spec.
- SKILL.md HTML Output Requirements now mandates HTML-escaping all user-supplied placeholder values (`&`, `<`, `>`, `"`, `'`).
- SKILL.md frontmatter description updated from "plan-mode frontmatter" to "HTML metadata".
- SKILL.md Step 7 cross-plugin note clarifies that `plan-interview:plan-status` operates on `.md`/YAML only and should not be used for HTML plans until updated.
- README.md updated to reflect HTML output, `SKELETON.html`, `.html` hook firing, and HTML metadata (replacing YAML frontmatter references).

---

## 0.3.0 — 2026-05-28

### Added

- **Hook extensibility** — `validate-plan-filename.py` now reads `planAgent.additionalVerbs`, `planAgent.additionalStopWords`, and `planAgent.additionalPlaceholders` from `.claude/settings.json` (project first, then global). Domain-specific verbs and custom extensions can be merged with the hardcoded sets without editing the Python source.
- **Plan templates** (`--template default|minimal|adr|spike`) — three new skeleton variants: `SKELETON-minimal.md` (Context + Steps + Criteria only), `SKELETON-adr.md` (Architecture Decision Record), `SKELETON-spike.md` (time-boxed investigation). Template selected at Step 2 Create.
- **`--no-clarify` flag** — skips Step 1 Clarify independently of Step 5 Align.
- **`--no-align` flag** — skips Step 5 Align independently of Step 1 Clarify.
- **`--priority` flag** (`low|medium|high|critical`) — writes `priority:` to plan frontmatter without requiring settings config.
- **`planAgent.extraFrontmatter` config** — project or global `.claude/settings.json` can inject arbitrary key-value pairs (e.g. `team`, `milestone`) into every plan's YAML frontmatter after the standard fields.

### Changed (non-breaking)

- `--quick` is now purely opt-in. The previous heuristic that auto-applied `--quick` for objectives ≥ 8 words with concrete names has been removed. `--quick` is documented as shorthand for `--no-clarify --no-align`.
- `argument-hint` updated to include all new flags.
- `classify_filename()` signature now accepts optional `verbs`, `stop_words`, and `placeholders` parameters (all default to module-level constants — backwards-compatible).

## 0.2.0 — 2026-05-27

### Changed (BREAKING)

- **Plugin renamed** `plan-mode` → `plan-agent`. Install id is now `plan-agent@agentics-kit`.
- **Skill renamed** `authoring-plans` → `author`. Explicit invocation is now `/plan-agent:author <objective>`.
- **Activation model changed**: `author` skill is now manual-invoke only (`disable-model-invocation: true`). It no longer auto-activates on planning intent — use `/plan-agent:author` explicitly.

### Added

- `$ARGUMENTS` parsing: reads a free-text objective plus flags (`--quick`, `--type`, `--dir`, `--interview`) from the invocation line.
- Smart `--type` inference from the leading verb of the objective when the flag is absent.
- Smart `--quick` inference for detailed, specific objectives.
- `EnterPlanMode` entry — the skill flips the session into real plan mode on invocation.
- `EnterPlanMode` added to `allowed-tools`.
- `--interview` flag: after the plan is written, optionally runs `plan-interview:plan-interview` before `ExitPlanMode`.

### Unchanged

- `validate-plan-filename` hook — logic, exit codes, and `hooks.json` registration are identical. Only the stderr citation was updated to reference `plan-agent` `/plan-agent:author`.
- Full Steps 0–7 workflow body, Required Structure, Writing Style, and Skeleton sections.

## 0.1.0 — 2026-05-27

### Added

- `authoring-plans` skill: auto-activating Plan Mode conventions covering the full Steps 0–7 workflow, required plan structure, and writing style
- `reference/SKELETON.md`: bundled plan skeleton with all required sections and per-step *Why*/*Verify* structure
- `validate-plan-filename.py` hook: `PostToolUse` enforcement of `verb-target` kebab-case plan filenames — rejects non-conforming names at write time (exit 2), skips `status: completed` plans
- `hooks.json`: registers the filename hook on `Write|Edit` events with a 5-second timeout
- Resolves `plansDirectory` from project `.claude/settings.json` first, global `~/.claude/settings.json` second, `docs/plans` as final fallback
