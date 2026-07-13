---
status: completed
type: feature
created: 2026-05-17
---

# Plan: Emit self-contained HTML artifact from plan-review-agents

## Context

The `product-plans:plan-review-agents` skill currently produces two
outputs: a 15-section markdown panel report (echoed in chat) and
an in-place mutation of the source plan file (Pass 1 inline edits +
Pass 2 appended `## Panel Review` section). Sharing reviews outside a
Claude Code session requires the reader to either render the plan
file themselves or read the chat transcript.

The user wants a third, **shareable, browser-openable artifact**: a
media-rich, self-contained HTML document combining the revised plan
(section 15b) as the primary surface with the full 15-section panel
review available as an appendix. The artifact must open in any
browser with no external dependencies (no CDN CSS, no external
fonts, no remote scripts) so it can be uploaded to any static file
host or attached to a ticket.

Design decisions confirmed with the user:

- **Content scope:** revised plan as primary, full review as appendix
  in the same file.
- **Output mode:** additive — the existing in-place plan update
  continues to happen in all modes; the HTML sibling is always
  emitted (no new Step 2 prompt).
- **Render approach:** a dedicated HTML layout spec bundled inside
  this skill (purpose-built for review-report shape — decision badge,
  six reviewer cards, conflicts table, reviewer-unavailable pills).
  No cross-plugin dependency on `plan-interview:plan-to-html`,
  though we mirror its self-contained-single-file pattern.

Sibling-file emission was explicitly removed from this skill in a
prior cleanup (CHANGELOG 3.x). The HTML sibling re-introduces a
sibling file deliberately, with a distinct extension (`.html`) so it
cannot collide with markdown plan files in the same directory.

## Objective

Add a self-contained HTML output mode to the
`product-plans:plan-review-agents` skill that always emits
`<plan-stem>-review.html` next to the source plan, containing the
revised plan as the primary document and the full panel review as a
collapsible/secondary appendix, rendered per a new bundled layout
spec.

## Files to modify

- `kit/plugins/product-plans/skills/plan-review-agents/SKILL.md` —
  add new step, update table of contents, update opening summary,
  update final announcement.
- `kit/plugins/product-plans/skills/plan-review-agents/references/html-spec.md` —
  **new file**. The full HTML layout contract: head, themes,
  two-column layout, decision badge, reviewer cards, conflicts table,
  inline-edits table, reviewer-unavailable pills, print styles,
  inlined CSS/JS.
- `kit/plugins/product-plans/commands/product-plans-bg.md` — update
  the final-summary prompt in Step 2 to surface the HTML artifact
  path alongside the in-place update path.
- `kit/plugins/product-plans/README.md` — document the new HTML output.
- `kit/plugins/product-plans/CHANGELOG.md` — new MINOR entry (3.3.0).
- `.claude-plugin/marketplace.json` — bump `product-plans` version
  `3.2.1` → `3.3.0`.

## Reuse notes

- The HTML synthesis must draw from the **same in-memory synthesized
  report** produced in Step 6, not re-synthesize from reviewer
  outputs — keeps the chat report, the appended `## Panel Review`
  section, and the new HTML file consistent.
- Mirror the cache pattern from
  `kit/plugins/plan-interview/skills/plan-to-html/reference/html-spec.md`
  (long-form layout contract in a `reference/`/`references/` file,
  short SKILL.md step that walks parse → synthesize → write). Do
  **not** read or import that file — we build a tailored spec.
- The skill already declares `Write` in `allowed-tools`, so no
  manifest changes are required for file emission.
- The synthesized report from Step 6 must be retained as a named
  string `synthesized_report` available to Steps 7 and 8 without
  regeneration. Neither step re-synthesizes from reviewer outputs.
  Step 8 reads this retained string directly — do not regenerate.

## Steps

1. **Create `references/html-spec.md`** with the full HTML layout
   contract organized into nine required sections: (a) **themes** —
   inlined `<style>` block defining four themes (`default`,
   `developer`, `document`, `minimal`) via `body.theme-*` CSS
   variables; WCAG AA contrast (4.5:1 normal text, 3:1 large text
   and UI components) required for all four themes; (b) **layout** —
   two-column sticky sidebar `<nav aria-label="Table of contents">`
   + `<main>` content layout collapsing to single-column at ≤768px;
   (c) **decision badge** — styled from section 14's
   `Approve / Approve with revisions / Reject` line; must render
   the full text label as visible content (not color-only, per
   WCAG 1.4.1); (d) **reviewer cards** — one per role, one
   reviewer-unavailable variant; reviewer-unavailable pill must
   include accessible text label (WCAG 1.1.1); (e) **tables** —
   conflicts table (section 13) with `<th scope="col">` headers;
   inline-edits table (section 15a) with `<ul><li>` for list-like
   multi-line cell content (`<p>` for prose, `<br>` reserved for
   inline line-breaks only); conflicts-table empty state renders a
   "No conflicts identified" single row; (f) **appendix toggle** —
   native `<details>`/`<summary>` exclusively for all collapsible
   controls (no custom JS toggle); `<details>` collapsed by default
   on load; (g) **print** — `@media print` hides the sidebar and
   expands all `<details>` elements (`details { display: block; }
   summary { display: none; }`); (h) **no-external-deps** — forbids
   CDN stylesheets, remote fonts, `<link>` tags, `<script src>`,
   `<iframe>`, `<object>`, `<embed>`, `@import` in CSS, CSS
   `url(https?:...)`, SVG `<use href="https?:...">`,
   `<meta http-equiv="refresh">`; (i) **Security & Escaping
   Contract** — ALL interpolated values (plan body, reviewer
   outputs, decision strings, table cell content, reviewer names)
   MUST be HTML-escaped before insertion (`<`→`&lt;`, `>`→`&gt;`,
   `&`→`&amp;`, `"`→`&quot;`, `'`→`&#39;`); if markdown is
   rendered to HTML: disable raw HTML passthrough, strip
   `javascript:`/`vbscript:`/`data:` (except `data:image/*`) from
   link `href`, strip event-handler attributes (`on*`); CSP
   `<meta http-equiv="Content-Security-Policy" content="default-src
   'none'; style-src 'self' 'unsafe-inline'; script-src 'self'
   'unsafe-inline'; img-src data:; base-uri 'none'; form-action
   'none'; frame-ancestors 'none'">` required in `<head>`.

   Also required in `<head>`: `<meta charset="UTF-8">`, `<meta
   name="viewport" content="width=device-width, initial-scale=1">`,
   `<title>` derived from the plan's H1 heading (or filename stem
   if no H1 is present), `<meta name="generator" content=
   "product-plans v3.3.0">`, and `<html lang="en">`.

   Also required: `<h1>` for the plan title, `<h2>` for top-level
   review sections, `<h3>` for reviewer cards; `:focus-visible`
   outline styles on all interactive elements (must not be
   suppressed by the CSS reset, per WCAG 2.4.11); scroll-spy JS
   updates only visual active state in TOC — it must not move
   keyboard focus programmatically (WCAG 2.4.3); a compact visible
   footer reading "This document may contain confidential plan
   content and reviewer findings. Classify before sharing." (prints
   with the artifact); a visible provenance footer with generation
   timestamp (ISO-8601 UTC) and source plan filename.

   The spec should include a minimal reference HTML skeleton
   (with `<!-- injection points -->` comments) showing the
   expected document structure, landmark nesting, and heading
   levels, so model runs fill named slots rather than generating
   document structure freehand.

   — *Why:* the spec carries the bulk of the layout, visual, security,
   and accessibility contract so the SKILL.md step body stays short
   and the model has one canonical place to look up rendering
   details. — *Verify:* the file exists at the path above; `grep -c
   '^## ' kit/plugins/product-plans/skills/plan-review-agents/references/html-spec.md`
   returns ≥ 9 (all nine required sections present: themes, layout,
   decision badge, reviewer cards, tables, appendix toggle, print,
   no-external-deps, Security & Escaping Contract); the spec file
   contains a reference HTML skeleton with at least `<html lang>`,
   `<meta charset>`, `<nav aria-label>`, `<main>`, `<aside>`,
   `<details>`, and `<meta http-equiv="Content-Security-Policy">`.

2. **Update `SKILL.md` opening summary and table of contents** —
   add a one-sentence mention of the HTML artifact in the opening
   paragraph (after the existing "coordinated by a lead that
   synthesizes findings…" sentence); add `Step 8 — Emit
   self-contained HTML artifact` to the table of contents between
   the current Step 7 and Step 8; renumber the existing "Clean up
   the team" step to **Step 9** in the TOC. — *Why:* keep readers
   oriented to the new behavior immediately; preserve the
   numbered-step structure. — *Verify:* the opening paragraph
   mentions HTML; the TOC lists Steps 0–9 in order with the new
   Step 8 anchored as `step-8--emit-self-contained-html-artifact`.

3. **Insert new Step 8 body in `SKILL.md`** with the following
   pieces:

   (a) **Mode clause** — "When `output_mode = review only`, skip
   this step entirely (section 15b does not exist; there is no
   revised plan to use as the primary surface). Otherwise, this
   step runs in both interactive and background modes regardless
   of `output_mode`."

   (b) **Synthesis instruction** — read `references/html-spec.md`
   and synthesize a single self-contained HTML string from the
   retained `synthesized_report` string from Step 6 (do **not**
   re-synthesize from reviewer outputs; do **not** read external
   CSS). Apply `body class="theme-default"` (theme selection is
   out of scope for v3.3.0 and will be added via `--theme` flag
   in a future release). Derive the output path as: take the
   absolute path of the resolved plan file from Step 1, extract
   the basename, strip the `.md` extension, replace any character
   outside `[A-Za-z0-9._-]` with `-`, append `-review.html`.
   Confirm the target path is in the same directory as the source
   plan and is not a symlink. All plan content and reviewer output
   interpolated into the HTML MUST be HTML-escaped per the
   "Security & Escaping Contract" section of `references/html-spec.md`.
   The revised plan section (section 15b) MUST be rendered from
   markdown to HTML (not shown as preformatted text). Supported
   markdown features: headings 1–6, fenced code blocks with
   language class (`<pre><code class="language-X">`), ordered/
   unordered lists with nesting, tables with `<thead>`/`<tbody>`,
   inline code, bold/italic, links with `rel="noopener noreferrer"`
   (strip `javascript:`/`vbscript:` URIs per the Security &
   Escaping Contract), blockquotes, horizontal rules. Raw HTML
   passthrough in the markdown source is disabled — all literal
   `<` characters are HTML-escaped per the Security & Escaping
   Contract.

   All content must be readable without JavaScript; JS provides
   scroll-spy active-state in the TOC only (progressive
   enhancement). Write the HTML string via `Write`; if the file
   exists, overwrite it silently. If `Write` fails (read-only
   directory, disk full, permission denied), announce
   `HTML artifact could not be written: <path> — <reason>` and
   continue to Step 9 (cleanup must still run).

   (c) **Announcement line** — emit both lines:
   ```
   HTML review artifact written: <resolved-html-path>
   ```
   In background mode, the `product-plans-bg` command wrapper
   surfaces this path alongside the in-place update path (see
   Step 10).

   — *Why:* ensures the step has an explicit security contract,
   deterministic path derivation, a defined failure mode, and a
   user-visible confirmation. — *Verify:* the Step 8 body
   contains the word "self-contained"; references
   `references/html-spec.md`; names `<source-plan-stem>-review.html`;
   contains the `review only` skip clause; contains the failure-mode
   announcement clause; includes the announcement-line blockquote.

4. **Renumber current "Clean up the team" step to Step 9** —
   update the heading and the in-body "Per the Agent Teams docs"
   block unchanged. — *Why:* preserves the cleanup-last invariant
   (cleanup must run after all artifacts are written). — *Verify:*
   the file contains exactly one `### Step 9 — Clean up the team`
   heading and no `### Step 8 — Clean up the team` heading.

5. **Update Step 0 todo-creation guidance in `SKILL.md`** — change
   the existing "Use `TodoWrite` to create a todo for each step
   below (Steps 1–8)" to **Steps 1–9** so the model creates a todo
   for the new step. — *Why:* TodoWrite-tracked progress must
   include the new step or it gets silently skipped. — *Verify:*
   the Step 0 paragraph references `Steps 1–9`.

6. **Update Step 7 closing announcement** — append a brief mention
   that the HTML artifact path will be announced separately in
   Step 8 (one short sentence after the existing
   `Plan updated in place: …` blockquote). — *Why:* makes the
   handoff between Step 7 and Step 8 explicit; avoids the reader
   wondering if the in-place update was the only output. —
   *Verify:* the Step 7 section closes with a line referencing
   "HTML artifact" or "next step" pointing to Step 8.

7. **Update `kit/plugins/product-plans/README.md`** — under the
   features/outputs section (find the existing description of
   what the panel produces), add a bullet documenting the new
   HTML artifact: filename pattern, location, content scope
   (revised plan + review appendix), and that it is always
   emitted alongside the in-place plan update. — *Why:* users
   discover plugin features from the README before reading
   SKILL.md. — *Verify:* `grep -n "html" kit/plugins/product-plans/README.md`
   (case-insensitive) returns at least one new match describing
   the artifact.

8. **Add CHANGELOG entry** at the top of
   `kit/plugins/product-plans/CHANGELOG.md` for version `3.3.0`,
   dated `2026-05-17`, describing the new self-contained HTML
   artifact, its filename pattern, that it is additive (does not
   replace any existing output), and that it requires no manifest
   changes. — *Why:* version history is the user-facing record of
   plugin changes per `marketplace.md`. — *Verify:* the first
   `##` header in the file reads `## 3.3.0 — 2026-05-17` and is
   followed by a non-empty body.

9. **Bump `product-plans` version in
   `.claude-plugin/marketplace.json`** from `"3.2.1"` to `"3.3.0"`.
   Do **not** add a `version` field to
   `kit/plugins/product-plans/.claude-plugin/plugin.json` (per the
   relative-path-plugin rule in `marketplace.md`). — *Why:* the
   marketplace is the source of truth for installable version;
   bump must be MINOR because new functionality is added without
   removing or breaking existing behavior. — *Verify:* the
   `product-plans` entry in `.claude-plugin/marketplace.json` has
   `"version": "3.3.0"` and the file passes the auto-validation
   hook on save.

10. **Update `kit/plugins/product-plans/commands/product-plans-bg.md`** —
    in Step 2, change the final-summary prompt from "report the
    path updated in place when done" to "report both the in-place
    update path and the HTML artifact path when done". The prompt
    template should become:
    ```
    Run the product-plans review panel on $ARGUMENTS in background mode.
    Invoke Skill(skill: "product-plans:plan-review-agents", args: "$ARGUMENTS --background")
    and report both the path updated in place and the HTML artifact
    path when done.
    ```
    — *Why:* the background wrapper's agent prompt drives what it
    surfaces to the invoker; without this change the HTML path is
    silently swallowed when the skill runs detached. — *Verify:*
    `grep "HTML artifact" kit/plugins/product-plans/commands/product-plans-bg.md`
    returns at least one match in the Step 2 prompt block.

## Verification

End-to-end confirmation that the plan was executed correctly:

1. **Spec exists and is referenced:**
   `ls kit/plugins/product-plans/skills/plan-review-agents/references/html-spec.md`
   succeeds and `grep -n "html-spec.md" kit/plugins/product-plans/skills/plan-review-agents/SKILL.md`
   returns at least one match.

2. **Step structure is intact:** `grep -n "^### Step" kit/plugins/product-plans/skills/plan-review-agents/SKILL.md`
   lists Steps 0 through 9 in order, with Step 8 titled
   "Emit self-contained HTML artifact" and Step 9 titled
   "Clean up the team".

3. **TOC matches body:** the table of contents anchors at the top
   of `SKILL.md` resolve to existing `### Step N — …` headings in
   the body (no broken anchors).

4. **Version is bumped:** `jq -r '.plugins[] | select(.name=="product-plans") | .version' .claude-plugin/marketplace.json`
   outputs `3.3.0`.

5. **CHANGELOG is dated correctly:** the top of
   `kit/plugins/product-plans/CHANGELOG.md` begins with
   `## 3.3.0 — 2026-05-17`.

6. **Live smoke test (manual):** invoke the skill on the fixture
   plan at `tests/fixtures/product-plans/sample-review-report.md`
   (a complete 15-section plan with all reviewer roles present).
   Confirm: (a) the chat report prints in full, (b) the source
   plan still has `## Panel Review` appended (Step 7 must not be
   disrupted by Step 8), (c) a new `<stem>-review.html` file
   appears next to the fixture plan. Open the HTML in a browser
   and confirm: (d) it loads with no console errors, (e) the
   decision badge reflects section 14's verdict and its text label
   is readable without CSS, (f) all six reviewer cards render
   (with `not assessed` variants where applicable), (g) the
   appendix is reachable and the `<details>` element is collapsed
   by default, (h) `grep -E '<link |<script[^>]*src=|<iframe|<object |<embed |@import|url\(https?:|<use[^>]*href="https?:|<meta[^>]*http-equiv="refresh"'` on the HTML file returns
   no matches, (i) print preview expands the appendix and hides
   the sidebar.

7. **Keyboard accessibility (manual):** tab through the rendered
   HTML file — all TOC links, the appendix `<summary>` toggle,
   and any collapsible controls must receive visible focus; press
   Space/Enter on the appendix `<summary>` — it must open and
   close; confirm the decision badge text is readable without CSS
   (disable styles in DevTools).

8. **XSS smoke test (manual):** invoke the skill on a fixture
   plan whose `# ` title is `Test <script>alert(1)</script> &
   "quote"`. Open the resulting HTML — confirm no alert fires.
   In `view-source`, confirm the title text shows
   `&lt;script&gt;alert(1)&lt;/script&gt;` rather than raw
   `<script>`.

## Acceptance Criteria

- [ ] Running the skill on any plan produces a `<stem>-review.html`
      file in the same directory as the source plan.
- [ ] The HTML file opens in any modern browser with no console
      errors and no outbound network requests.
- [ ] The revised plan (section 15b) is rendered as the primary
      view with markdown formatting applied; the full panel review
      is accessible via the collapsible appendix.
- [ ] The appendix `<details>` is collapsed by default on load and
      expands fully in print preview.
- [ ] All four themes are visually distinct; the `default` theme
      meets WCAG AA color contrast for body text and UI components.
- [ ] The HTML file passes the self-containment check: `grep -E
      '<link |<script[^>]*src=|<iframe|@import|url\(https?:'`
      returns no matches.
- [ ] Running with `output_mode = review only` produces no HTML
      file and emits no HTML path announcement.
- [ ] Running `/product-plans:product-plans-bg` on a plan surfaces
      the HTML artifact path in the final background-agent status
      message alongside the in-place update path.

## Next Steps *(optional)*

- Rename this plan file before the first implementation commit:
  ```text
  Rename docs/plans/the-kit-plugins-product-plans-skills-pla-merry-tome.md
  to docs/plans/add-html-output-to-plan-review-agents.md using
  `git mv` so history is preserved, then update any internal
  references in commit messages or other plan files that point at
  the old filename. Per plan-hygiene.md, random-named plan files
  must be renamed before the first commit for the feature. Do this
  immediately after plan approval, before touching any other file.
  ```

- Add theme selection to the HTML output:
  ```text
  Extend the plan-review-agents skill so the HTML artifact's theme
  can be chosen by the user. Add a `--theme=<default|developer|document|minimal>`
  flag parsed in Step 0 alongside `--background`, defaulting to
  `default` when absent. Pass the chosen theme to the HTML
  synthesis step so the rendered file ships with `body class="theme-<name>"`.
  Mirror the flag handling in the `/product-plans:product-plans-bg`
  command so background-mode invocations can also pick a theme.
  Do not add an interactive theme prompt — keep the choice
  flag-driven to preserve the additive/no-new-prompt design.
  ```

- Cross-link the HTML artifact from the appended `## Panel Review`
  section in the source plan:
  ```text
  After the plan-review-agents skill's Step 7 Pass 2 appends the
  `## Panel Review` section to the source plan, prepend a one-line
  link at the top of that section pointing to the sibling HTML
  artifact (`See also: [browser-friendly review](<stem>-review.html)`).
  Keep the link path relative so it works when the plan and HTML
  files are moved together. Verify the link does not break
  existing markdown linters by running any configured lint step
  on a sample plan after the change.
  ```

- Add an HTML artifact for `plan-interview:plan-to-html` parity:
  ```text
  Compare the new references/html-spec.md (added to plan-review-agents)
  with kit/plugins/plan-interview/skills/plan-to-html/reference/html-spec.md
  and identify any shared layout/theme primitives that could be
  factored into a single source of truth — e.g. a marketplace-level
  reference document or a shared `kit/shared/html/` directory both
  skills include via instruction. Recommend an approach with
  tradeoffs (duplication vs coupling) and a minimum-viable refactor
  path if consolidation is worthwhile.
  ```

- Add dark mode support to the HTML artifact:
  ```text
  Add a `@media (prefers-color-scheme: dark)` CSS block to
  kit/plugins/product-plans/skills/plan-review-agents/references/html-spec.md
  that maps to the `developer` theme palette as the dark variant.
  Update the verification smoke test to confirm the dark-mode CSS
  block is present and that all four themes still meet WCAG AA
  contrast. Dark mode is explicitly out of scope for v3.3.0 —
  target v3.4.0 or later.
  ```

## Panel Review

*Reviewed by: PM · Lead Developer · UX Designer · Lead Frontend Engineer · Accessibility Expert · Security Expert — coordinated by Lead Coordinator*

---

### 1. Executive Summary

High-quality, well-scoped plan with a clear user problem and additive design. The panel unanimously approves with revisions. The plan's core decisions — self-contained artifact, deterministic filename, in-memory synthesis reuse, additive emission — are sound. Three cross-cutting gaps require resolution before implementation: (1) no HTML-escaping or CSP contract for user-controlled content flowing into the artifact, creating a real stored-XSS vector when the artifact is shared to static hosts; (2) no WCAG accessibility baseline in the `html-spec.md` scope, despite this being a professionally shared document; (3) no explicit named-variable contract guaranteeing the Step 6 synthesis is preserved for Steps 7 and 8. All three are now addressed as inline edits applied to this plan. No reviewers rejected the plan.

---

### 2. Role-by-Role Review

#### Product Manager

**Works well:** Clear user problem statement; additive non-breaking design; self-contained constraint is explicit and verifiable; deterministic filename convention; honest reuse rationale; correct MINOR version bump; well-formed Next Steps.

**Critical concerns:** (1) No fallback behavior for the "always emitted" invariant — no error mode when `Write` fails. (2) `html-spec.md` created and relied upon in the same execution run with no content-quality gate. *Both addressed in inline edits.*

**Unclear:** What constitutes "Step 6 in-memory report" as a data structure; whether appendix is hidden-by-default or visible on load; intended reader persona; `review only` mode + HTML interaction.

**Missing requirements (addressed):** Accessibility baseline; file size envelope; reviewer-unavailable trigger definition; overwrite behavior not stated in Objective.

**Approval status:** Approve with revisions.

---

#### Lead Developer

**Works well:** Scope touches exactly five files; in-memory reuse strategy is correct; `Write` already in `allowed-tools`; MINOR version bump justified; per-step verification present; cleanup-last invariant preserved.

**Critical concerns:** None. Implementation is technically sound.

**Unclear:** In-memory report shape (named-variable contract needed); `review only` mode interaction (section 15b absent); default theme not named; background mode HTML path surfacing.

**Missing requirements (addressed):** No markdown-to-HTML extraction contract; no accessibility floor; no Write failure handling; no named-variable synthesis contract.

**Approval status:** Approve with revisions.

---

#### UX Designer

**Works well:** Additive-only design eliminates new prompts; self-contained constraint removes "why doesn't this render?" friction; deterministic filename is discoverable; sidebar TOC + collapsible appendix addresses information hierarchy.

**Critical concerns:** (1) No error state for HTML Write failure — no recovery path. (2) Smoke test references `~/.claude/plans/` — machine-specific, not repeatable. *Both addressed in inline edits.*

**Unclear:** Default theme; read-only directory behavior; overwrite behavior signal to user; `<details>` default visibility.

**Missing requirements (addressed):** Accessibility spec for artifact; charset declaration; `<title>` element spec.

**Approval status:** Approve with revisions.

---

#### Lead Frontend Engineer

**Works well:** Self-contained constraint explicit and enforced; single source-of-truth rendering is sound; filename pattern deterministic; additive design; CSS-variable theme approach is correct.

**Critical concerns:** (1) No accessibility spec — no ARIA, landmarks, heading hierarchy, or contrast requirements. (2) Inlined JS with no progressive-enhancement clause or CSP. (3) `html-spec.md` needs a reference skeleton for consistency across runs. *All addressed in inline edits to Step 1 and Step 3.*

**Unclear:** Template-fill vs. freehand generation; "in-memory report" continuity; collapsible mechanism (JS vs. native `<details>`); two-column breakpoint; theme default.

**Missing requirements (addressed):** Charset; viewport meta; HTML escaping to prevent XSS; dark mode policy (added as out-of-scope + Next Steps).

**Approval status:** Approve with revisions.

---

#### Accessibility Expert

**Works well:** Native `<details>`/`<summary>` is the right collapsible choice; no-external-deps eliminates third-party a11y regressions; decision badge uses text + styling; reviewer-unavailable pills are better than blank cells.

**Critical concerns:** (1) No WCAG conformance target in `html-spec.md`. (2) Verification has zero accessibility checks. (3) No `:focus-visible` styles specified. *All addressed in inline edits to Step 1 and Verification.*

**Missing requirements (addressed):** Accessibility clause in `html-spec.md` scope; keyboard nav contract; scroll-spy focus-management policy; TOC landmark spec; non-color decision badge; language attribute; accessibility verification step.

**Approval status:** Approve with revisions.

---

#### Security Expert

**Works well:** Self-contained/no-external-deps eliminates supply-chain risks; no manifest changes maintain least-privilege posture; deterministic scoped output location; distinct `.html` extension; single-source synthesis prevents divergence-based disclosure.

**Critical concerns:** (1) XSS via unescaped user content — plan body and reviewer outputs flow into HTML with no escaping contract; when uploaded to static hosts this is stored XSS (OWASP A03). (2) No threat model for the "shareable" attack surface. *Both addressed in Step 1 (Security & Escaping Contract section) and Step 3 inline edits.*

**Missing requirements (addressed):** HTML escaping rule; markdown renderer constraints; CSP meta tag; external-reference audit rule; sensitive content notice; provenance metadata; filename normalization; write-safety contract.

**Approval status:** Approve with revisions — blocking on XSS/escaping/CSP cluster (now resolved in inline edits).

---

### 3. Highest-Risk Issues

1. **Stored XSS via unescaped user content in shared HTML** — Plan-body and reviewer output content flowed into the HTML artifact without any escaping contract. When uploaded to a static host (the primary stated use case), this is OWASP A03 stored-XSS. *Resolved: Security & Escaping Contract added to Step 1 spec scope.*

2. **No WCAG accessibility baseline in `html-spec.md`** — The spec governed a professionally shared external document but specified zero semantic HTML, landmark, contrast, focus, or language requirements. *Resolved: nine-section spec scope in Step 1 now includes full WCAG AA requirements.*

3. **In-memory synthesis continuity not guaranteed (Steps 6 → 7 → 8)** — "Same in-memory report from Step 6" was an emergent behavior, not a runtime contract. *Resolved: named-variable contract added to Reuse notes.*

4. **Write failure leaves "always emitted" invariant undefined** — A disk-full or permissions error produced no user-visible error and no recovery path. *Resolved: failure-mode clause added to Step 3.*

5. **`html-spec.md` had no content-quality gate** — The ">200 lines" check did not verify the eight required sections exist. *Resolved: section-presence `grep -c '^## '` check replacing line-count verify.*

---

### 4. Blocking Issues

All blocking issues are resolved by the inline edits applied in Pass 1:

1. **HTML escaping and CSP contract** — Added as mandatory "Security & Escaping Contract" section to Step 1 spec scope, and as interpolation constraint in Step 3. *(Resolved)*
2. **Write failure mode** — Added to Step 3: announce error and continue to Step 9. *(Resolved)*
3. **Named-variable synthesis contract** — Added to Reuse notes. *(Resolved)*

---

### 5. Important but Non-Blocking Improvements

Applied in Pass 1:
- Default theme: `body class="theme-default"` stated in Step 3.
- `review only` mode: Step 8 skipped entirely when `output_mode = review only`.
- Appendix default state: collapsed on load, expanded in print — added to Step 1.
- Smoke test fixture: `tests/fixtures/product-plans/` replacing `~/.claude/plans/`.
- Verification item 4: replaced with `jq` command.
- Spec completeness gate: section-presence grep ≥ 9 replacing line-count check.
- Responsive breakpoint: two-column collapses at ≤768px — added to Step 1.
- `<meta charset>`, `<meta viewport>`, `<html lang>`, `<meta name="generator">`: added to Step 1 `<head>` requirements.
- Provenance footer: added to Step 1.
- Filename rename note: moved from floating blockquote to formal Next Steps entry.
- Dark mode: added as explicit out-of-scope + Next Steps entry.
- Unresolved Questions section: added for three pending decisions.

---

### 6. UX Recommendations

All addressed in inline edits to Step 1, Step 3, and Verification:
- Appendix `<details>` collapsed by default; expanded in `@media print`.
- Default theme `theme-default` applied explicitly in Step 3.
- Smoke test uses repeatable fixture path.
- Regression check added to Verification item 6: source plan must still contain `## Panel Review` after Step 8 runs.
- Compact footer disclaimer ("This document may contain confidential plan content and reviewer findings. Classify before sharing.") included in Step 1 spec requirements.

---

### 7. Accessibility Requirements

All addressed in inline edits to Step 1 and Verification:
- `<html lang="en">` (WCAG 3.1.1)
- Landmark regions: `<nav aria-label="Table of contents">`, `<main>`, `<aside>` (WCAG 1.3.6, 2.4.1)
- Heading hierarchy: h1/h2/h3 (WCAG 1.3.1, 2.4.6)
- `:focus-visible` on all interactive elements (WCAG 2.4.11)
- WCAG AA contrast for all four themes (WCAG 1.4.3, 1.4.11)
- Non-color decision badge: full text label required (WCAG 1.4.1)
- Native `<details>`/`<summary>` exclusively for collapsibles (WCAG 2.1.1)
- Scroll-spy must not move keyboard focus (WCAG 2.4.3)
- `<th scope="col">` on tables; `<ul><li>` for multi-line cells (WCAG 1.3.1)
- Accessible text on reviewer-unavailable pills (WCAG 1.1.1)
- Verification items 7 (keyboard) and 8 (XSS smoke test) added

---

### 8. Frontend Implementation Considerations

All addressed in inline edits to Step 1 and Step 3:
- Native `<details>`/`<summary>` exclusively for all collapsibles; JS for scroll-spy only.
- Progressive enhancement clause in Step 3: content readable without JS.
- Reference HTML skeleton required in spec (injection-point approach).
- Responsive breakpoint at ≤768px in Step 1.
- Conflicts-table empty state defined.
- Section-presence grep replacing line-count verify.
- Dark mode explicitly out-of-scope for v3.3.0, added as Next Steps entry.

---

### 9. Security Requirements

All addressed in inline edits to Step 1 (Security & Escaping Contract) and Step 3:
- HTML escaping rule for all interpolated values (OWASP A03)
- Markdown renderer constraints: no raw HTML, no `javascript:`/`vbscript:` URIs, no event-handler attributes (OWASP A03)
- CSP `<meta>` tag in `<head>` (OWASP A05)
- Complete self-containment verification grep (OWASP A06) — Verification 6h
- Filename normalization to `[A-Za-z0-9._-]` in Step 3 (OWASP A01, A03)
- Sensitive content footer notice (GDPR Art. 5(1)(f))
- Provenance metadata in `<head>` and footer (OWASP A08)
- XSS smoke test — Verification item 8 (OWASP A03)

---

### 10. Technical Feasibility Concerns

- No critical technical blockers. Implementation is feasible with existing skill capabilities.
- Markdown subset spec: Step 1 should enumerate supported markdown features in the spec (headings 1–6, fenced code, tables, lists, bold/italic, links with `rel="noopener noreferrer"`, blockquotes).
- Named-variable contract: addressed in Reuse notes.
- Spec drift risk: two parallel `html-spec.md` files will diverge; consolidation recommended before v3.4.0 (existing Next Steps entry).
- Test fixture recommendation: `tests/fixtures/product-plans/sample-review-report.md` serves as a worked example and future regression baseline.

---

### 11. Open Questions Before Development

Moved to formal `## Unresolved Questions` section above. Key decisions:

1. **Appendix default state** — collapsed by default (addressed in Step 1); print expanded (addressed in Step 1).
2. **`review only` mode** — skip Step 8 entirely (addressed in Step 3).
3. **Default theme** — `theme-default` (addressed in Step 3).
4. **Markdown rendering** — open question; see Unresolved Questions section.
5. **In-memory synthesis continuity** — explicit named string (addressed in Reuse notes).
6. **Write failure** — loud error + continue to cleanup (addressed in Step 3).
7. **Background-mode HTML path surfacing** — open question; see Unresolved Questions section.

---

### 12. Recommended Changes to the Plan

All nineteen recommendations from synthesis were applied in Pass 1 inline edits:

1. Security & Escaping Contract added to Step 1 spec scope.
2. Accessibility requirements added to Step 1 spec scope.
3. `<head>` requirements added to Step 1 (charset, viewport, title, generator meta, CSP).
4. Collapsible default state and print expansion added to Step 1.
5. Responsive breakpoint (≤768px) added to Step 1.
6. Section-presence grep (≥9) replacing line-count verify in Step 1.
7. Named-variable contract added to Reuse notes.
8. Write failure mode clause added to Step 3.
9. Default theme (`theme-default`) added to Step 3.
10. Progressive enhancement clause added to Step 3.
11. `review only` skip clause added to Step 3.
12. Path-safety (basename normalization, symlink check) added to Step 3.
13. Verification item 4 replaced with `jq` command.
14. Verification item 6 smoke test updated with fixture path + regression check + extended grep.
15. Verification items 7 (keyboard a11y) and 8 (XSS smoke test) added.
16. Floating filename-rename blockquote removed; formal Next Steps entry added.
17. Dark mode out-of-scope + Next Steps entry added.
18. Unresolved Questions section added for three open decisions.
19. Reference HTML skeleton requirement added to Step 1 spec scope.

---

### 13. Conflicts or Tradeoffs Between Reviewer Recommendations

**Collapsible appendix mechanism (JS toggle vs. native `<details>`)**
A11y required native `<details>`/`<summary>`. Frontend said pick one — both simultaneously causes interaction conflicts. Security noted inline JS event-handlers expand the XSS surface. UX acknowledged VoiceOver inconsistencies with native `<details>` but agreed it's lowest-risk.
*Resolution applied: native `<details>`/`<summary>` exclusively for all collapsible controls; JS restricted to scroll-spy TOC active-state only (progressive enhancement).*

**Sensitive content warning level (Security vs. UX)**
Security wanted a visible printable banner. UX wanted minimal friction on the primary surface.
*Resolution applied: compact footer disclaimer ("This document may contain confidential plan content and reviewer findings. Classify before sharing.") that prints — not a modal overlay or full-page banner.*

**`html-spec.md` generation approach (scaffold vs. freehand)**
Frontend, A11y, and Dev all converged on scaffold-fill (fixed skeleton with injection points) as more reliable and accessible than freehand generation. PM's plan implied freehand but had not committed.
*Resolution applied: reference HTML skeleton with injection-point comments required as part of Step 1 spec scope.*

---

### 14. Final Decision

Final decision: **Approve with revisions**

The plan is technically sound, correctly scoped, and the additive design holds up under cross-functional scrutiny. All three blocking issues (XSS/escaping/CSP, Write failure mode, named-variable synthesis contract) have been resolved by the inline edits applied in Pass 1. The plan is ready to implement once the three open Unresolved Questions are decided before Step 1 authoring begins.

---

### 15a. Inline Edits to Apply

*(Applied in Pass 1 above.)*

| # | Section heading | Action | Content summary |
|---|-----------------|--------|---------|
| 1 | `## Reuse notes` | `append` | Named-variable contract for `synthesized_report` |
| 2 | `## Steps` Step 1 | `edit` | Nine-section spec scope with security, accessibility, head requirements, skeleton requirement, section-presence verify |
| 3 | `## Steps` Step 3 | `edit` | Review-only skip, failure mode, default theme, progressive enhancement, path-safety clauses |
| 4 | `## Verification` item 4 | `edit` | `jq` command replacing fragile grep |
| 5 | `## Verification` item 6 | `edit` | Fixture path, regression check, extended self-containment grep |
| 6 | `## Verification` | `append` | Items 7 (keyboard a11y) and 8 (XSS smoke test) |
| 7 | Plan title blockquote | `edit` | Removed floating filename-rename blockquote |
| 8 | `## Next Steps` | `edit` | Rename entry now formal with fenced prompt per plan-mode.md |
| 9 | `## Next Steps` | `append` | Dark mode out-of-scope + Next Steps entry |
| 10 | `## Next Steps` | `insert after` | `## Unresolved Questions` section with three open decisions |

---

### 15b. Complete Revised Plan

*(The source plan file above reflects all inline edits. This section is a reference view of the plan as it stands after Pass 1.)*

See the updated `docs/plans/the-kit-plugins-product-plans-skills-pla-merry-tome.md` (to be renamed `add-html-output-to-plan-review-agents.md` before first implementation commit). Key additions from the panel:

- `## Reuse notes`: named-variable contract (`synthesized_report` retained through Steps 7 and 8)
- Step 1: nine-section spec scope including Security & Escaping Contract and full WCAG AA accessibility requirements; reference skeleton required; section-presence verify
- Step 3: review-only skip clause, Write failure mode, default theme, progressive enhancement, path-safety normalization
- Verification: `jq`-based version check; fixture-based smoke test; items 7 (keyboard a11y) and 8 (XSS smoke test)
- Next Steps: formal rename entry, dark mode out-of-scope entry
- `## Unresolved Questions`: markdown rendering trust boundary, review-only mode output, background-mode path surfacing
